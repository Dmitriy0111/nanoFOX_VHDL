--
-- File            :   nf_apb_gpio.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.11.29
-- Language        :   VHDL
-- Description     :   This is APB GPIO module
-- Copyright(c)    :   2019 Vlasov D.V.
--

library ieee;
use ieee.std_logic_1164.all;
library nf;
use nf.nf_settings.all;
use nf.nf_ahb_pkg.all;
use nf.nf_help_pkg.all;
use nf.nf_components.all;

entity nf_apb_gpio is
    generic
    (
        gpio_w      : integer := NF_GPIO_WIDTH
    );
    port
    (
        -- clock and reset
        pclk        : in    std_logic;                              -- pclock
        presetn     : in    std_logic;                              -- presetn
        -- APB GPIO slave side
        paddr_s     : in    std_logic_vector(31       downto 0);    -- APB - GPIO-slave PADDR
        pwdata_s    : in    std_logic_vector(31       downto 0);    -- APB - GPIO-slave PWDATA
        prdata_s    : out   std_logic_vector(31       downto 0);    -- APB - GPIO-slave PRDATA
        pwrite_s    : in    std_logic;                              -- APB - GPIO-slave PWRITE
        psel_s      : in    std_logic;                              -- APB - GPIO-slave PSEL
        penable_s   : in    std_logic;                              -- APB - GPIO-slave PENABLE
        pready_s    : out   std_logic;                              -- APB - GPIO-slave PREADY
        -- GPIO side
        gpi         : in    std_logic_vector(gpio_w-1 downto 0);    -- GPIO input
        gpo         : out   std_logic_vector(gpio_w-1 downto 0);    -- GPIO output
        gpd         : out   std_logic_vector(gpio_w-1 downto 0)     -- GPIO direction
    );
end nf_apb_gpio;

architecture rtl of nf_apb_gpio is
    signal pready_ff        : std_logic_vector(0  downto 0);
    signal psel_slv         : std_logic_vector(0  downto 0);

    signal addr             : std_logic_vector(31 downto 0);    -- address for gpio module
    signal rd               : std_logic_vector(31 downto 0);    -- read data from gpio module
    signal wd               : std_logic_vector(31 downto 0);    -- write data for gpio module
    signal we               : std_logic;                        -- write enable for gpio module
begin

    addr     <= paddr_s;
    we       <= pwrite_s and penable_s and psel_s;
    wd       <= pwdata_s;
    prdata_s <= rd;

    psel_slv(0) <= psel_s;

    pready_reg : nf_register    generic map( 1 ) port map ( hclk, hresetn, psel_slv, pready_ff );

    -- creating one nf_gpio unit
    nf_gpio_0 : nf_gpio
    generic map
    (
        gpio_w  => gpio_w
    )
    port map
    (
        -- reset and clock
        clk     => hclk,    -- clk
        resetn  => hresetn, -- resetn
        -- bus side
        addr    => addr,    -- address
        we      => we,      -- write enable
        wd      => wd,      -- write data
        rd      => rd,      -- read data
        -- GPIO side
        gpi     => gpi,     -- GPIO input
        gpo     => gpo,     -- GPIO output
        gpd     => gpd      -- GPIO direction
    );

end rtl; -- nf_apb_gpio
