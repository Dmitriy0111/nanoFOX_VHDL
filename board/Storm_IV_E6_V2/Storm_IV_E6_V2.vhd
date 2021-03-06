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
    -- wires & inputs
    -- clock and reset
    signal clk      : std_logic;                        -- clock
    signal resetn   : std_logic;                        -- reset
    -- GPIO
    signal gpio_i_0 :   std_logic_vector(7  downto 0);  -- GPIO_0 input
    signal gpio_o_0 :   std_logic_vector(7  downto 0);  -- GPIO_0 output
    signal gpio_d_0 :   std_logic_vector(7  downto 0);  -- GPIO_0 direction
    -- PWM
    signal pwm      :   std_logic;                      -- PWM output signal
    -- UART side
    signal uart_tx  :   std_logic;                      -- UART tx wire
    signal uart_rx  :   std_logic;                      -- UART rx wire

    signal gpio2hex :   std_logic_vector(31 downto 0);  -- gpio to hex
    signal hex      :   std_logic_vector(7  downto 0);  -- for hex display
    signal dig      :   std_logic_vector(3  downto 0);
    -- component definition
    -- nf_top_ahb
    component nf_top_ahb
        port
        (
            -- clock and reset
            clk         : in    std_logic;                      -- clock
            resetn      : in    std_logic;                      -- reset
            -- PWM side
            pwm         : out   std_logic;                      -- PWM output
            -- GPIO side
            gpio_i_0    : in    std_logic_vector(7 downto 0);   -- GPIO input
            gpio_o_0    : out   std_logic_vector(7 downto 0);   -- GPIO output
            gpio_d_0    : out   std_logic_vector(7 downto 0);   -- GPIO direction
            -- UART side
            uart_tx     : out   std_logic;                      -- UART tx wire
            uart_rx     : in    std_logic                       -- UART rx wire
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

    -- assigns
    hex0     <= hex;
    clk      <= clk50mhz;
    resetn   <= rst_key;
    gpio2hex <= 24X"0" & gpio_o_0;
    gpio_i_0 <= 4X"00" & sw;
    b        <= dig(0);
    g        <= dig(1);
    hsync    <= dig(2);
    vsync    <= dig(3);
    led(0)   <= pwm; 
    -- creating one nf_top_ahb_0 unit
    nf_top_ahb_0 : nf_top_ahb 
    port map
    (
        -- clock and reset
        clk         => clk,         -- clock
        resetn      => resetn,      -- reset
        -- PWM side
        pwm         => pwm,         -- PWM output
        -- GPIO side
        gpio_o_0    => gpio_o_0,    -- GPIO output
        gpio_d_0    => gpio_d_0,    -- GPIO direction
        gpio_i_0    => gpio_i_0,    -- GPIO input
        -- UART side
        uart_tx     => uart_tx,     -- UART tx wire
        uart_rx     => uart_rx      -- UART rx wire
    );
    -- creating one nf_seven_seg_dynamic_0 unit
    nf_seven_seg_dynamic_0 : nf_seven_seg_dynamic 
    port map
    (
        clk         => clk,         -- clock
        resetn      => resetn,      -- reset
        hex         => gpio2hex,    -- hexadecimal value input
        cc_ca       => '0',         -- common cathode or common anode
        seven_seg   => hex,         -- seven segments output
        dig         => dig          -- digital tube selector
    );

end rtl; -- Storm_IV_E6_V2
