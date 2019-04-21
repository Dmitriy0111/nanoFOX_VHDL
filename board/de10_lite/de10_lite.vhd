library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity de10_lite is
    port 
    (
        -- max10 clock input's
        adc_clk_10      : in    std_logic;
        max10_clk1_50   : in    std_logic;
        max10_clk2_50   : in    std_logic;
        -- seven segment's
        hex0            : out   std_logic_vector(7  downto 0);
        hex1            : out   std_logic_vector(7  downto 0);
        hex2            : out   std_logic_vector(7  downto 0);
        hex3            : out   std_logic_vector(7  downto 0);
        hex4            : out   std_logic_vector(7  downto 0);
        hex5            : out   std_logic_vector(7  downto 0);
        -- vga
        hsync           : out   std_logic;
        vsync           : out   std_logic;
        R               : out   std_logic_vector(3  downto 0);
        G               : out   std_logic_vector(3  downto 0);
        B               : out   std_logic_vector(3  downto 0);
        -- button's
        key             : in    std_logic_vector(1  downto 0);
        -- led's
        ledr            : out   std_logic_vector(9  downto 0);
        -- switches
        sw              : in    std_logic_vector(9  downto 0);
        -- gpio
        gpio            : inout std_logic_vector(35 downto 0)
    );
end de10_lite;

architecture rtl of de10_lite is
    -- wires & inputs
    -- clock and reset
    signal clk      : std_logic;                        -- clock
    signal resetn   : std_logic;                        -- reset
    signal div      : std_logic_vector(25 downto 0);    -- clock divide input
    -- for debug
    signal reg_addr : std_logic_vector(4  downto 0);    -- scan register address
    signal reg_data : std_logic_vector(31 downto 0);    -- scan register data
    -- hex
    signal hex      : std_logic_vector(47 downto 0);    -- hex values from convertors
    -- component definition
    -- nf_top
    component nf_top
        port 
        (
            -- clock and reset
            clk         : in    std_logic;                      -- clock
            resetn      : in    std_logic;                      -- reset
            div         : in    std_logic_vector(25 downto 0);  -- clock divide input
            -- for debug
            reg_addr    : in    std_logic_vector(4  downto 0);  -- scan register address
            reg_data    : out   std_logic_vector(31 downto 0)   -- scan register data
        );
    end component;
    -- nf_seven_seg_static
    component nf_seven_seg_static
        generic
        (
            hn          : integer := 8                              -- number of seven segments unit
        );
        port 
        (
            hex         : in    std_logic_vector(31     downto 0);  -- hexadecimal value input
            cc_ca       : in    std_logic;                          -- common cathode or common anode
            seven_seg   : out   std_logic_vector(hn*8-1 downto 0)   -- seven segments output
        );
    end component;
begin

    hex0 <= hex(7 downto 0);
    hex1 <= hex(15 downto 8);
    hex2 <= hex(23 downto 16);
    hex3 <= hex(31 downto 24);
    hex4 <= hex(39 downto 32);
    hex5 <= hex(47 downto 40);
    clk <= max10_clk1_50;
    resetn <= key(0);
    div <= sw(9 downto 5) & (20 downto 0 => '0');
    reg_addr <= sw(4 downto 0);
    R <= "0000";
    G <= "0000";
    B <= "0000";
    hsync <= '0';
    vsync <= '0';
    -- creating one nf_top_0 unit
    nf_top_0 : nf_top 
    port map 
    (
        -- clock and reset
        clk         => clk,         -- clock
        resetn      => resetn,      -- reset
        div         => div,         -- clock divide input
        -- for debug
        reg_addr    => reg_addr,    -- scan register address
        reg_data    => reg_data     -- scan register data
    );
    -- creating one nf_seven_seg_static_0 unit
    nf_seven_seg_static_0 : nf_seven_seg_static 
    generic map
    (
        hn          => 6
    )
    port map
    (
        hex         => reg_data,    -- hexadecimal value input
        cc_ca       => '0',         -- common cathode or common anode
        seven_seg   => hex          -- seven segments output
    );

end rtl; -- de10_lite
