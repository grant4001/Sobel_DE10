library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity edge_detect is
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
end entity edge_detect;

architecture structural of edge_detect is

    component fifo is
        generic
        (
            constant FIFO_DATA_WIDTH : integer;
            constant FIFO_BUFFER_SIZE : integer
        );
        port
        (
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

    component to_grayscale is
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
    end component to_grayscale;

    component sobel is
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
    end component sobel;

    signal fifo_gs2sob_rd_en : std_logic := '0';
    signal fifo_gs2sob_wr_en : std_logic := '0';
    signal fifo_gs2sob_din : std_logic_vector (7 downto 0) := (others=>'0');
    signal fifo_gs2sob_dout : std_logic_vector (7 downto 0) := (others=>'0');
    signal fifo_gs2sob_full : std_logic := '0';
    signal fifo_gs2sob_empty : std_logic := '0';

    begin

    to_grayscale_inst : to_grayscale
    port map (
        clock_50 => clock_50,
        reset => reset, 
        fifo_in_dout => fifo_in_dout,
        fifo_in_empty => fifo_in_empty,
        fifo_gs2sob_full => fifo_gs2sob_full,
        fifo_gs2sob_din => fifo_gs2sob_din,
        fifo_gs2sob_wr_en => fifo_gs2sob_wr_en,
        fifo_in_rd_en => fifo_in_rd_en
    );

    fifo_gs2sob : component fifo
    generic map
    (
        FIFO_DATA_WIDTH => 8,
        FIFO_BUFFER_SIZE => 16
    )
    port map (
        rd_clk => clock_50,
        wr_clk => clock_50,
        reset => reset,
        rd_en => fifo_gs2sob_rd_en,
        wr_en => fifo_gs2sob_wr_en,
        din => fifo_gs2sob_din,
        dout => fifo_gs2sob_dout,
        full => fifo_gs2sob_full,
        empty => fifo_gs2sob_empty
    );

    sobel_inst: sobel
    port map (
        clock_50 => clock_50,
        reset => reset,
        fifo_gs2sob_dout => fifo_gs2sob_dout,
        fifo_gs2sob_empty => fifo_gs2sob_empty,
        fifo_out_full => fifo_out_full,
        fifo_out_din => fifo_out_din,
        fifo_out_wr_en => fifo_out_wr_en,
        fifo_gs2sob_rd_en => fifo_gs2sob_rd_en
    );

end architecture structural;