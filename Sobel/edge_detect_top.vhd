library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity edge_detect_top is 
    port (
        signal clock_25 : in std_logic;
        signal clock_50 : in std_logic;
        signal reset : in std_logic;
        signal fifo_in_full : out std_logic;
        signal fifo_in_wr_en : in std_logic;
        signal fifo_in_din : in std_logic_vector (23 downto 0);
        signal fifo_out_rd_en : in std_logic;
        signal fifo_out_empty : out std_logic;
        signal fifo_out_dout : out std_logic_vector (7 downto 0)
    );
end entity edge_detect_top;

architecture structural of edge_detect_top is 

    component fifo is
        generic (
            constant FIFO_DATA_WIDTH : integer;
            constant FIFO_BUFFER_SIZE : integer
        );
        port (
            signal rd_clk : in std_logic;
            signal wr_clk : in std_logic;
            signal reset : in std_logic;
            signal rd_en : in std_logic;
            signal wr_en : in std_logic;
            signal din : in std_logic_vector ((FIFO_DATA_WIDTH - 1) downto 0);
            signal dout : out std_logic_vector ((FIFO_DATA_WIDTH - 1) downto 0);
            signal full : out std_logic;
            signal empty : out std_logic
        );
    end component fifo;

    component edge_detect is
        port (
            clock_50 : in std_logic;
            reset : in std_logic;
            fifo_in_dout : in std_logic_vector (23 downto 0);
            fifo_in_empty : in std_logic;
            fifo_out_full : in std_logic;
            fifo_out_din : out std_logic_vector (7 downto 0);
            fifo_out_wr_en : out std_logic;
            fifo_in_rd_en : out std_logic
        );
    end component edge_detect;

    signal fifo_in_dout : std_logic_vector (23 downto 0) := (others=>'0');
    signal fifo_in_empty : std_logic := '0';
    signal fifo_in_rd_en : std_logic := '0';
    signal fifo_out_din : std_logic_vector (7 downto 0) := (others=>'0');
    signal fifo_out_full : std_logic := '0'; 
    signal fifo_out_wr_en : std_logic := '0';

    begin

    fifo_in : component fifo
    generic map
    (
        FIFO_DATA_WIDTH => 24,
        FIFO_BUFFER_SIZE => 16
    )
    port map (
        rd_clk => clock_50,
        wr_clk => clock_25,
        reset => reset,
        rd_en => fifo_in_rd_en,
        wr_en => fifo_in_wr_en,
        din => fifo_in_din,
        dout => fifo_in_dout,
        full => fifo_in_full,
        empty => fifo_in_empty
    );

    edge_detect_inst : edge_detect
    port map (
        clock_50 => clock_50,
        reset => reset,
        fifo_in_dout => fifo_in_dout,
        fifo_in_empty => fifo_in_empty,
        fifo_out_full => fifo_out_full,
        fifo_out_din => fifo_out_din,
        fifo_out_wr_en => fifo_out_wr_en,
        fifo_in_rd_en => fifo_in_rd_en
    );

    fifo_out : component fifo
    generic map
    (
        FIFO_DATA_WIDTH => 8,
        FIFO_BUFFER_SIZE => 16
    )
    port map (
        rd_clk => clock_25,
        wr_clk => clock_50,
        reset => reset,
        rd_en => fifo_out_rd_en,
        wr_en => fifo_out_wr_en,
        din => fifo_out_din,
        dout => fifo_out_dout,
        full => fifo_out_full,
        empty => fifo_out_empty
    );

end architecture structural;