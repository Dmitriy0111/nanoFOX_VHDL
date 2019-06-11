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
    signal clk      :   std_logic;                      -- clock
    signal resetn   :   std_logic;                      -- reset
    -- GPIO
    signal gpio_i_0 :   std_logic_vector(7  downto 0);  -- GPIO_0 input
    signal gpio_o_0 :   std_logic_vector(7  downto 0);  -- GPIO_0 output
    signal gpio_d_0 :   std_logic_vector(7  downto 0);  -- GPIO_0 direction
    -- PWM
    signal pwm      :   std_logic;                      -- PWM output signal
    -- UART side
    signal uart_tx  :   std_logic;                      -- UART tx wire
    signal uart_rx  :   std_logic;                      -- UART rx wire
    -- hex
    signal hex      :   std_logic_vector(47 downto 0);  -- hex values from convertors
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
    gpio_i_0 <= 3X"000" & sw(4 downto 0);
    ledr(8)  <= pwm;
    ledr(7 downto 0) <= gpio_o_0;
    
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
        gpio_i_0    => gpio_i_0,    -- GPIO input
        gpio_o_0    => gpio_o_0,    -- GPIO output
        gpio_d_0    => gpio_d_0,    -- GPIO direction
        -- UART side
        uart_tx     => uart_tx,     -- UART tx wire
        uart_rx     => uart_rx      -- UART rx wire
    );
    -- creating one nf_seven_seg_static_0 unit
    nf_seven_seg_static_0 : nf_seven_seg_static 
    generic map
    (
        hn          => 6
    )
    port map
    (
        hex         => 32D"2019",
        cc_ca       => '0',
        seven_seg   => hex
    );

end rtl; -- de10_lite
