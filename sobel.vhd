library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity sobel is
    port(
        clock_50 : in std_logic;
        reset : in std_logic;
        fifo_gs2sob_dout : in std_logic_vector (7 downto 0);
        fifo_gs2sob_empty : in std_logic;
        fifo_out_full : in std_logic;
        fifo_out_din : out std_logic_vector (7 downto 0);
        fifo_out_wr_en : out std_logic;
        fifo_gs2sob_rd_en : out std_logic
    );
end entity sobel;

architecture behavioral of sobel is

    constant w : integer := 640 + 16 + 96 + 48;
    constant h : integer := 480 + 11 + 2 + 31;

    type state_type is (s0, s1);
    type shiftreg_type is array (0 to (w * 2) + 3 - 1) of std_logic_vector (7 downto 0); --640 * 2 + 3 - 1
    type kernel_type is array (0 to 2, 0 to 2) of std_logic_vector (2 downto 0);
    type window_type is array (0 to 2, 0 to 2) of std_logic_vector (7 downto 0);
    constant horiz_kernel : kernel_type := ((std_logic_vector(to_signed(-1, 3)), std_logic_vector(to_signed(0, 3)), std_logic_vector(to_signed(1, 3))),
                                            (std_logic_vector(to_signed(-2, 3)), std_logic_vector(to_signed(0, 3)), std_logic_vector(to_signed(2, 3))),
                                            (std_logic_vector(to_signed(-1, 3)), std_logic_vector(to_signed(0, 3)), std_logic_vector(to_signed(1, 3))));
    constant vert_kernel : kernel_type := (( std_logic_vector(to_signed(1, 3)), std_logic_vector(to_signed(2, 3)), std_logic_vector(to_signed(1, 3))),
                                            (std_logic_vector(to_signed(0, 3)), std_logic_vector(to_signed(0, 3)), std_logic_vector(to_signed(0, 3))),
                                            (std_logic_vector(to_signed(-1, 3)), std_logic_vector(to_signed(-2, 3)), std_logic_vector(to_signed(-1, 3))));
    signal state, next_state : state_type := s0;
    signal shiftreg, shiftreg_c : shiftreg_type := (others => (others => '0'));
    signal x, x_c : std_logic_vector (11 downto 0) := (others=>'0'); --10 bits for 640, 12 for 3264
    signal y, y_c : std_logic_vector (11 downto 0) := (others=>'0'); --9 bits for 480, 12 for 2448
    

    function MATMUL_3(A: window_type; B: kernel_type)
        return std_logic_vector is
            variable c : std_logic_vector (15 downto 0) := x"0000";
            begin
                for j in 0 to 2 loop
                    for i in 0 to 2 loop
                        c := std_logic_vector(signed(c) + signed('0' & A(j, i)) * signed(B(i, j)));
                    end loop;
                end loop;
        return c;
    end MATMUL_3;

    function if_cond( test : boolean; true_cond : std_logic_vector; false_cond : std_logic_vector )
	return std_logic_vector is 
	begin
		if ( test ) then
			return true_cond;
		else
			return false_cond;
		end if;
	end if_cond;

    begin
                    
    comb_proc : process 
    (
        state, 
        fifo_gs2sob_empty, 
        fifo_gs2sob_dout,
        fifo_out_full,
        x, 
        y,
        shiftreg
    )
    variable window : window_type := (others=>(others=>(others=>'0')));
    variable horiz_res, vert_res : std_logic_vector (15 downto 0) := (others=>'0');
    variable avg : std_logic_vector (15 downto 0) := (others=>'0');
    variable pixel : std_logic_vector (7 downto 0) := (others=>'0');
    begin

        window := (others=>(others=>(others=>'0')));
        next_state <= state;
        shiftreg_c <= shiftreg;
        x_c <= x;
        y_c <= y;
        fifo_out_din <= (others => '0');
        fifo_out_wr_en <= '0';
        fifo_gs2sob_rd_en <= '0';

        case (state) is

            --Read grayscale pixel into the shift register
            when s0 => 
                if (fifo_gs2sob_empty = '0') then
                    next_state <= s1;
                    fifo_gs2sob_rd_en <= '1';
                    for i in (w*2)+3-1 downto 1 loop
                        shiftreg_c(i) <= shiftreg(i - 1);
                    end loop;
                    x_c <= std_logic_vector(unsigned(x) + to_unsigned(1, x'length));
                    if (unsigned(x) = to_unsigned(w - 1, x'length)) then
                        x_c <= (others=>'0');
                        y_c <= std_logic_vector(unsigned(y) + to_unsigned(1, y'length));
                        if (unsigned(y) = to_unsigned(h - 1, y'length)) then
                            y_c <= (others=>'0');
                        end if;
                    end if;
                end if;
                shiftreg_c(0) <= fifo_gs2sob_dout;

            when s1 =>
                window(0, 0) := shiftreg((2*w)+2);
                window(0, 1) := shiftreg((2*w)+1);
                window(0, 2) := shiftreg(2*w);
                window(1, 0) := shiftreg(w+2);
                window(1, 1) := shiftreg(w+1);
                window(1, 2) := shiftreg(w);
                window(2, 0) := shiftreg(2);
                window(2, 1) := shiftreg(1);
                window(2, 2) := shiftreg(0);
                horiz_res := MATMUL_3(window, horiz_kernel);
                vert_res := MATMUL_3(window, vert_kernel);
                avg := std_logic_vector('0' & resize(abs(signed(horiz_res)) + abs(signed(vert_res)), 16)(15 downto 1));
                pixel := if_cond(unsigned(avg) >= to_unsigned(255, 16), x"FF", std_logic_vector(resize(unsigned(avg), 8)));

                fifo_out_din <= pixel;
                --if (unsigned(x) = to_unsigned(0, x'length) or 
                --    unsigned(x) = to_unsigned(1, x'length) or 
                --    unsigned(y) = to_unsigned(0, y'length) or 
                --    unsigned(y) = to_unsigned(1, y'length)) then
                --    fifo_out_din <= x"00";
                --end if;

                if (fifo_out_full = '0') then
                    fifo_out_wr_en <= '1';
                    next_state <= s0;
                end if;

            when others =>
                next_state <= s0;
        end case;
    end process;

    reg_proc : process (clock_50, reset)
    begin
        if (reset = '0') then
            state <= s0;
            shiftreg <= (others => (others => '0'));
            x <= (others=>'0');
            y <= (others=>'0');
        elsif rising_edge(clock_50) then
            state <= next_state;
            shiftreg <= shiftreg_c;
            x <= x_c;
            y <= y_c;
        end if;
    end process;

end architecture behavioral;