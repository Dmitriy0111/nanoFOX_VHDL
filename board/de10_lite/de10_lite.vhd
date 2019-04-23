library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
library work;
use work.nf_settings.all;

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
    -- generic params
    constant    debug_type  : string := "vga";
    constant    cpu         : string := "nanoFOX";
    constant    sub_path    : string := "../../brd_rtl/DebugScreenCore/";
    -- wires & inputs
    -- clock and reset
    signal clk      : std_logic;                        -- clock
    signal resetn   : std_logic;                        -- reset
    signal div      : std_logic_vector(25 downto 0);    -- clock divide input
    -- pwm side
    signal pwm      : std_logic;                        -- PWM output
    -- gpio side
    signal gpi      : std_logic_vector(7  downto 0);    -- GPIO input
    signal gpo      : std_logic_vector(7  downto 0);    -- GPIO output
    signal gpd      : std_logic_vector(7  downto 0);    -- GPIO direction
    -- for debug
    signal reg_addr : std_logic_vector(4  downto 0);    -- scan register address
    signal reg_data : std_logic_vector(31 downto 0);    -- scan register data
    -- hex
    signal hex      : std_logic_vector(47 downto 0);    -- hex values from convertors
    -- for debug ScreenCore
    signal en       : std_logic;                        -- enable logic for vga DebugScreenCore
    -- component definition
    -- nf_top
    component nf_top
        port 
        (
            -- clock and reset
            clk         : in    std_logic;                                  -- clock
            resetn      : in    std_logic;                                  -- reset
            div         : in    std_logic_vector(25 downto 0);              -- clock divide input
            -- pwm side
            pwm         : out   std_logic;                                  -- PWM output
            -- gpio side
            gpi         : in    std_logic_vector(NF_GPIO_WIDTH-1 downto 0); -- GPIO input
            gpo         : out   std_logic_vector(NF_GPIO_WIDTH-1 downto 0); -- GPIO output
            gpd         : out   std_logic_vector(NF_GPIO_WIDTH-1 downto 0); -- GPIO direction
            -- for debug
            reg_addr    : in    std_logic_vector(4  downto 0);              -- scan register address
            reg_data    : out   std_logic_vector(31 downto 0)               -- scan register data
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
    -- vha_ds_top
    component vga_ds_top
        generic
        (
            cpu         : string := "nanoFOX";                  -- cpu type
            sub_path    : string := "../"                       -- sub path for DebugScreenCore memorys
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

    ledr(7 downto 0) <= gpo;
    ledr(8) <= pwm;

    hex0 <= hex(7  downto  0);
    hex1 <= hex(15 downto  8);
    hex2 <= hex(23 downto 16);
    hex3 <= hex(31 downto 24);
    hex4 <= hex(39 downto 32);
    hex5 <= hex(47 downto 40);
    clk <= max10_clk1_50;
    resetn <= key(0);
    div <= sw(9 downto 5) & (20 downto 0 => '1');
    gpi <= 8X"00";
    -- creating one nf_top_0 unit
    nf_top_0 : nf_top 
    port map  
    (
        -- clock and reset
        clk         => clk,         -- clock
        resetn      => resetn,      -- reset
        div         => div,         -- clock divide input
        -- pwm side
        pwm         => pwm,         -- PWM output
        -- gpio side
        gpi         => gpi,         -- GPIO input
        gpo         => gpo,         -- GPIO output
        gpd         => gpd,         -- GPIO direction
        -- for debug
        reg_addr    => reg_addr,    -- scan register address
        reg_data    => reg_data     -- scan register data
    );
    debug_hex_generate :
    if( debug_type = "hex") generate
        reg_addr <= sw(4 downto 0);
        R <= 4X"0";
        G <= 4X"0";
        B <= 4X"0";
        hsync <= '0';
        vsync <= '0';
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
    end generate debug_hex_generate;

    debug_dsc_generate :
    if( debug_type = "vga") generate
        hex <= 48X"0";
        -- creating one debug_screen_core
        vga_ds_top_0 : vga_ds_top
        generic map
        (
            cpu         => cpu,         -- cpu type
            sub_path    => sub_path     -- sub path for DebugScreenCore memorys
        )
        port map
        (
            clk         =>   clk,       -- clock
            resetn      =>   resetn,    -- reset
            en          =>   en,        -- enable input
            hsync       =>   hsync,     -- hsync output
            vsync       =>   vsync,     -- vsync output
            bgColor     =>   12X"00F",  -- Background color
            fgColor     =>   12X"F00",  -- Foreground color
            regData     =>   reg_data,  -- Register data input from cpu
            regAddr     =>   reg_addr,  -- Register data output to cpu
            R           =>   R,         -- R-color
            G           =>   G,         -- G-color
            B           =>   B          -- B-color
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

end rtl; -- de10_lite
