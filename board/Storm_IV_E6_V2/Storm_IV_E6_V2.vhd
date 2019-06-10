library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity Storm_IV_E6_V2 is
    port 
    (
        clk50mhz    : in    std_logic;
        rst_key     : in    std_logic;
        -- seven segment's
        hex0        : out   std_logic_vector(7  downto 0);
        -- vga
        hsync       : out   std_logic;
        vsync       : out   std_logic;
        G           : out   std_logic;
        B           : out   std_logic;
        -- button's
        key         : in    std_logic_vector(3  downto 0);
        sw          : in    std_logic_vector(3  downto 0);
        -- led's
        led         : out   std_logic_vector(7  downto 0)
    );
end Storm_IV_E6_V2;

architecture rtl of Storm_IV_E6_V2 is
    -- generic params
    constant    debug_type  : string := "vga";
    constant    cpu         : string := "nanoFOX";
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
    signal dig      : std_logic_vector(3  downto 0);
    -- for debug ScreenCore
    signal en       : std_logic;                        -- enable logic for vga DebugScreenCore
    signal R_i      : std_logic_vector(3  downto 0);    -- R internal
    signal G_i      : std_logic_vector(3  downto 0);    -- G internal
    signal B_i      : std_logic_vector(3  downto 0);    -- B internal
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
    -- vga_ds_top
    component vga_ds_top
        generic
        (
            cpu         : string := "nanoFOX"                   -- cpu type
        );
        port
        (
            clk         : in    std_logic;                      -- clock
            resetn      : in    std_logic;                      -- reset
            en          : in    std_logic;                      -- enable input
            hsync       : out   std_logic;                      -- hsync output
            vsync       : out   std_logic;                      -- vsync output
            bgColor     : in    std_logic_vector(11 downto 0);  -- Background color
            fgColor     : in    std_logic_vector(11 downto 0);  -- Foreground color
            regData     : in    std_logic_vector(31 downto 0);  -- Register data input from cpu
            regAddr     : out   std_logic_vector(4  downto 0);  -- Register data output to cpu
            R           : out   std_logic_vector(3  downto 0);  -- R-color
            G           : out   std_logic_vector(3  downto 0);  -- G-color
            B           : out   std_logic_vector(3  downto 0)   -- B-color
        );
    end component;
begin

    clk <= clk50mhz;
    resetn <= rst_key;
    div <= sw(3 downto 1) & 23X"7fffff";

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
    debug_hex_generate :
    if( debug_type = "hex") generate

        hex0 <= hex;
        B     <= dig(0);
        G     <= dig(1);
        hsync <= dig(2);
        vsync <= dig(3);
        reg_addr <= sw(0) & key(3 downto 0);

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
    end generate debug_hex_generate;

    debug_dsc_generate :
    if( debug_type = "vga") generate
        hex <= 8X"0";
        hex0(0) <= R_i(3);
        G <= G_i(3);
        B <= B_i(3);
        -- creating one debug_screen_core
        vga_ds_top_0 : vga_ds_top
        generic map
        (
            cpu         => cpu          -- cpu type
        )
        port map
        (
            clk         => clk,         -- clock
            resetn      => resetn,      -- reset
            en          => en,          -- enable input
            hsync       => hsync,       -- hsync output
            vsync       => vsync,       -- vsync output
            bgColor     => 12X"00F",    -- Background color
            fgColor     => 12X"F00",    -- Foreground color
            regData     => reg_data,    -- Register data input from cpu
            regAddr     => reg_addr,    -- Register data output to cpu
            R           => R_i,         -- R-color
            G           => G_i,         -- G-color
            B           => B_i          -- B-color
        );

        en_proc : process(all)
        begin
            if( not resetn ) then
                en <= '0';
            elsif( rising_edge(clk) ) then
                en <= not en;
            end if;
        end process;

    end generate debug_dsc_generate;

end rtl; -- Storm_IV_E6_V2
