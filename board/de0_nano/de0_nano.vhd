library ieee;
use ieee.std_logic_1164.all;

entity de0_nano is
    port
    (
        ------------ CLOCK ----------
        CLOCK_50        : in    std_logic;
        ------------ LED ----------
        LED             : out   std_logic_vector(7  downto 0);
        ------------ KEY ----------
        KEY             : in    std_logic_vector(1  downto 0);
        ------------ SW ----------
        SW              : in    std_logic_vector(3  downto 0);
        ------------ SDRAM ----------
        DRAM_ADDR       : out   std_logic_vector(12 downto 0);
        DRAM_BA         : out   std_logic_vector(1  downto 0);
        DRAM_CAS_N      : out   std_logic;
        DRAM_CKE        : out   std_logic;
        DRAM_CLK        : out   std_logic;
        DRAM_CS_N       : out   std_logic;
        DRAM_DQ         : inout std_logic_vector(15 downto 0);
        DRAM_DQM        : out   std_logic_vector(1  downto 0);
        DRAM_RAS_N      : out   std_logic;
        DRAM_WE_N       : out   std_logic;
        ------------ EPCS ----------
        EPCS_ASDO       : out   std_logic;
        EPCS_DATA0      : in    std_logic;
        EPCS_DCLK       : out   std_logic;
        EPCS_NCSO       : out   std_logic;
        ------------ Accelerometer and EEPROM ----------
        G_SENSOR_CS_N   : out   std_logic;
        G_SENSOR_INT    : in    std_logic;
        I2C_SCLK        : out   std_logic;
        I2C_SDAT        : inout std_logic;
        ------------ ADC ----------
        ADC_CS_N        : out   std_logic;
        ADC_SADDR       : out   std_logic;
        ADC_SCLK        : out   std_logic;
        ADC_SDAT        : in    std_logic;
        ------------ 2x13 GPIO Header ----------
        GPIO_2          : inout std_logic_vector(12 downto 0);
        GPIO_2_IN       : in    std_logic_vector(2  downto 0);
        ------------ GPIO_0, GPIO_0 connect to GPIO Default ----------
        GPIO_0          : inout std_logic_vector(33 downto 0);
        GPIO_0_IN       : in    std_logic_vector(1  downto 0);
        ------------ GPIO_1, GPIO_1 connect to GPIO Default ----------
        GPIO_1          : inout std_logic_vector(33 downto 0);
        GPIO_1_IN       : in    std_logic_vector(1  downto 0)
    );
end de0_nano;

architecture rtl of de0_nano is
    -- clock and reset
    signal clk      : std_logic;                    -- clock
    signal resetn   : std_logic;                    -- reset
    -- pwm side
    signal pwm      : std_logic;                    -- pwm output
    -- gpio side
    signal gpio_i_0 : std_logic_vector(7 downto 0); -- gpio input
    signal gpio_o_0 : std_logic_vector(7 downto 0); -- gpio output
    signal gpio_d_0 : std_logic_vector(7 downto 0); -- gpio direction
    -- UART side
    signal uart_tx  : std_logic;                    -- UART tx wire
    signal uart_rx  : std_logic;                    -- UART rx wire
    -- nf_top
    component nf_top
        port
        (
            -- clock and reset
            clk         : in    std_logic;                      -- clock input
            resetn      : in    std_logic;                      -- reset input
            -- GPIO side
            gpio_i_0    : in    std_logic_vector(7 downto 0);   -- GPIO_0 input
            gpio_o_0    : out   std_logic_vector(7 downto 0);   -- GPIO_0 output
            gpio_d_0    : out   std_logic_vector(7 downto 0);   -- GPIO_0 direction
            -- PWM side
            pwm         : out   std_logic;                      -- PWM output signal
            -- UART side
            uart_tx     : out   std_logic;                      -- UART tx wire
            uart_rx     : in    std_logic                       -- UART rx wire
        );
    end component;
begin

    clk       <= CLOCK_50;
    resetn    <= KEY(0);
    LED       <= gpio_o_0;
    gpio_i_0  <= 4X"0" & SW;
    GPIO_0(4) <= uart_tx;
    uart_rx   <= GPIO_0(5);

    -- creating one nf_top_0 unit
    nf_top_0 : nf_top 
    port map
    (
        clk         => clk,
        resetn      => resetn,
        pwm         => pwm,
        gpio_i_0    => gpio_i_0,
        gpio_o_0    => gpio_o_0,
        gpio_d_0    => gpio_d_0,
        uart_tx     => uart_tx,
        uart_rx     => uart_rx
    );

end rtl; -- de0_nano
