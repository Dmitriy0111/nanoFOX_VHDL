library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
library work;
use work.nf_settings.all;

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
    -- generic params
    constant    debug_type  : string := "hex";
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
    signal hex      : std_logic_vector(7  downto 0);    -- hex values from convertors
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

    hex0 <= hex;
    clk <= clk50mhz;
    resetn <= rst_key;
    div <= 26X"00ffffff";
    led   <= gpo(3 downto 0);
    
    -- creating one nf_top_0 unit
    nf_top_0 : nf_top 
    port map 
    (
        -- clock and reset
        clk         => clk,         -- clock
        resetn      => resetn,      -- reset
        div         => div,         -- clock divide input
        -- pwm side
        pwm         => open,        -- PWM output
        -- gpio side
        gpi         => 8X"00",      -- GPIO input
        gpo         => gpo,         -- GPIO output
        gpd         => open,        -- GPIO direction
        -- for debug
        reg_addr    => reg_addr,    -- scan register address
        reg_data    => reg_data     -- scan register data
    );
    
    debug_hex_generate :
    if( debug_type = "hex") generate
        reg_addr <= '0' & key(3 downto 0);
        R <= '0';
        G <= '0';
        B <= '0';
        hsync <= '0';
        vsync <= '0';
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
        R <= R_i(3);
        G <= G_i(3);
        B <= B_i(3);
        dig <= 4X"0";
        hex <= 8X"0";
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
            R           =>   R_i,       -- R-color
            G           =>   G_i,       -- G-color
            B           =>   B_i        -- B-color
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

end rtl; -- rz_easyFPGA_A2_1
