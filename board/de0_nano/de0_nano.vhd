library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
library work;
use work.nf_settings.all;

entity de0_nano is
    port 
    (
        -- CLOCK
        CLOCK_50        : in    std_logic;
        -- LED
        LED             : out   std_logic_vector(7  downto 0);
        -- KEY
        KEY             : in    std_logic_vector(1  downto 0);
        -- SW
        SW              : in    std_logic_vector(3  downto 0);
        -- SDRAM
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
        -- EPCS
        EPCS_ASDO       : out   std_logic;
        EPCS_DATA0      : in    std_logic;
        EPCS_DCLK       : out   std_logic;
        EPCS_NCSO       : out   std_logic;
        -- Accelerometer and EEPROM
        G_SENSOR_CS_N   : out   std_logic;
        G_SENSOR_INT    : in    std_logic;
        I2C_SCLK        : out   std_logic;
        I2C_SDAT        : inout std_logic;
        -- ADC
        ADC_CS_N        : out   std_logic;
        ADC_SADDR       : out   std_logic;
        ADC_SCLK        : out   std_logic;
        ADC_SDAT        : in    std_logic;
        -- 2x13 GPIO Header
        GPIO_2          : inout std_logic_vector(12 downto 0);
        GPIO_2_IN       : in    std_logic_vector(2  downto 0);
        -- GPIO_0, GPIO_0 connect to GPIO Default
        GPIO_0          : inout std_logic_vector(33 downto 0);
        GPIO_0_IN       : in    std_logic_vector(1  downto 0);
        -- GPIO_1, GPIO_1 connect to GPIO Default
        GPIO_1          : inout std_logic_vector(33 downto 0);
        GPIO_1_IN       : in    std_logic_vector(1  downto 0)
    );
end de0_nano;

architecture rtl of de0_nano is
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
begin
    
    clk    <= CLOCK_50;
    resetn <= KEY(0);
    div    <= SW(1 downto 0) & 24X"FFFFF";

    LED(6 downto 0) <= gpo(6 downto 0);
    LED(7)          <= pwm;
    gpi             <= (7 downto 2 => '0') & SW(3 downto 2);
    -- creating one nf_top_0 unit
    nf_top_0 : nf_top 
    port map
    (
        -- clock and reset
        clk         => clk,     -- clock
        resetn      => resetn,  -- reset
        div         => div,     -- clock divide input
        -- pwm side
        pwm         => pwm,     -- PWM output
        -- gpio side
        gpi         => gpi,     -- GPIO input
        gpo         => gpo,     -- GPIO output
        gpd         => gpd,     -- GPIO direction
        -- for debug
        reg_addr    => 5X"00",  -- scan register address
        reg_data    => open     -- scan register data
    );

end rtl; -- de0_nano
