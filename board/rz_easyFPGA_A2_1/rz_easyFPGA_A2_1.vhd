library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity rz_easyFPGA_A2_1 is
    port 
    (
        clk50mhz    : in    std_logic;
        rst_key     : in    std_logic;
        -- seven segment's
        hex0        : out   std_logic_vector(7  downto 0);
        dig         : out   std_logic_vector(3  downto 0);
        -- vga
        hsync       : out   std_logic;
        vsync       : out   std_logic;
        R           : out   std_logic;
        G           : out   std_logic;
        B           : out   std_logic;
        -- button's
        key         : in    std_logic_vector(3  downto 0);
        -- led's
        led         : out   std_logic_vector(3  downto 0)
    );
end rz_easyFPGA_A2_1;

architecture rtl of rz_easyFPGA_A2_1 is
    -- wires & inputs
    -- clock and reset
    signal clk      : std_logic;                        -- clock
    signal resetn   : std_logic;                        -- reset
    signal div      : std_logic_vector(25 downto 0);    -- clock divide input
    -- for debug
    signal reg_addr : std_logic_vector(4  downto 0);    -- scan register address
    signal reg_data : std_logic_vector(31 downto 0);    -- scan register data
    -- hex
    signal hex      : std_logic_vector(7  downto 0);    -- hex values from convertors
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
    -- nf_seven_seg_dynamic
    component nf_seven_seg_dynamic
        port 
        (
            clk         : in    std_logic;                      -- clock
            resetn      : in    std_logic;                      -- reset
            hex         : in    std_logic_vector(31 downto 0);  -- hexadecimal value input
            cc_ca       : in    std_logic;                      -- common cathode or common anode
            seven_seg   : out   std_logic_vector(7  downto 0);  -- seven segments output
            dig         : out   std_logic_vector(3  downto 0)   -- digital tube selector
        );
    end component;
begin

    hex0 <= hex;
    clk <= clk50mhz;
    resetn <= rst_key;
    div <= 26X"00ffffff";
    reg_addr <= '0' & key(3 downto 0);
    R <= '0';
    G <= '0';
    B <= '0';
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
    -- creating one nf_seven_seg_dynamic_0 unit
    nf_seven_seg_dynamic_0 : nf_seven_seg_dynamic
    port map
    (
        clk         => clk,         -- clock
        resetn      => resetn,      -- reset
        hex         => reg_data,    -- hexadecimal value input
        cc_ca       => '0',         -- common cathode or common anode
        seven_seg   => hex,         -- seven segments output
        dig         => dig          -- digital tube selector
    );

end rtl; -- rz_easyFPGA_A2_1
