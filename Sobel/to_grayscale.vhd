library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity to_grayscale is
    port(
        clock_50 : in std_logic;
        reset : in std_logic;
        fifo_in_dout : in std_logic_vector (23 downto 0);
        fifo_in_empty : in std_logic;
        fifo_gs2sob_full : in std_logic;
        fifo_gs2sob_din : out std_logic_vector (7 downto 0);
        fifo_gs2sob_wr_en : out std_logic;
        fifo_in_rd_en : out std_logic
    );
end entity to_grayscale;

architecture behavioral of to_grayscale is
    
    type state_type is (REGISTER_DATA, GRAYSCALE);
    signal state, next_state : state_type := REGISTER_DATA;
    signal R, R_c, G, G_c, B, B_c : std_logic_vector (7 downto 0) := (others => '0');
    begin

    grayscale_comb_proc : process 
    (
        state, 
        R, 
        G,
        B,
        fifo_in_dout, 
        fifo_gs2sob_full, 
        fifo_in_empty
    ) 
    begin

        R_c <= R;
        G_c <= G;
        B_c <= B;
        fifo_gs2sob_din <= (others => '0');
        fifo_gs2sob_wr_en <= '0';
        fifo_in_rd_en <= '0';
        next_state <= state;

        case (state) is 
            when REGISTER_DATA =>
                if (fifo_in_empty = '0') then
                    fifo_in_rd_en <= '1';
                    next_state <= GRAYSCALE;
                end if;
                R_c <= fifo_in_dout(23 downto 16);
                G_c <= fifo_in_dout(15 downto 8);
                B_c <= fifo_in_dout(7 downto 0);
            when GRAYSCALE =>
                if (fifo_gs2sob_full = '0') then
                    fifo_gs2sob_wr_en <= '1';
                    next_state <= REGISTER_DATA;
                end if;

                -- calculate grayscale value using luminosity method, which provides
                -- greater contrast. Green will be weighted the most heavily as the
                -- human eye is most sensitive to it.
                -- using luminosity method faster than averaging (avoid division by 3)

                -- formula: .21 * R + .72 * G + .07 * B
                -- for an approximation using bitshifts, we use:
                -- .25 * R + .625 * G + .125 * B =
                -- (R >> 2) + (G >> 1) + (G >> 3) + (B >> 3)
                -- NOTE: cannot use .75 * G because then gs value will exceed 255
                fifo_gs2sob_din <= std_logic_vector(resize(
                    unsigned("0000" & R(7 downto 2)) + 
                    unsigned("000" & G(7 downto 1)) +
                    unsigned("00000" & G(7 downto 3)) +
                    unsigned("00000" & B(7 downto 3)), 8));
            when others =>
                next_state <= REGISTER_DATA;
        end case;
    end process;

    grayscale_reg_proc : process (clock_50, reset)
    begin
        if reset = '0' then
            state <= REGISTER_DATA;
            R <= (others=>'0');
            G <= (others=>'0');
            B <= (others=>'0');
        elsif rising_edge(clock_50) then
            state <= next_state;
            R <= R_c;
            G <= G_c;
            B <= B_c;
        end if;
    end process;

end architecture behavioral;
