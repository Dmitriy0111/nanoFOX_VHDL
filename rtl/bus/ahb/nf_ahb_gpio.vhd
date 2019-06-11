--
-- File            :   nf_ahb_gpio.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.04.26
-- Language        :   VHDL
-- Description     :   This is AHB GPIO module
-- Copyright(c)    :   2019 Vlasov D.V.
--

library ieee;
use ieee.std_logic_1164.all;
library nf;
use nf.nf_settings.all;
use nf.nf_ahb_pkg.all;
use nf.nf_help_pkg.all;

entity nf_ahb_gpio is
    generic
    (
        gpio_w      : integer := NF_GPIO_WIDTH
    );
    port
    (
        -- clock and reset
        hclk        : in    std_logic;                              -- hclock
        hresetn     : in    std_logic;                              -- hresetn
        -- AHB GPIO slave side
        haddr_s     : in    std_logic_vector(31       downto 0);    -- AHB - GPIO-slave HADDR
        hwdata_s    : in    std_logic_vector(31       downto 0);    -- AHB - GPIO-slave HWDATA
        hrdata_s    : out   std_logic_vector(31       downto 0);    -- AHB - GPIO-slave HRDATA
        hwrite_s    : in    std_logic;                              -- AHB - GPIO-slave HWRITE
        htrans_s    : in    std_logic_vector(1        downto 0);    -- AHB - GPIO-slave HTRANS
        hsize_s     : in    std_logic_vector(2        downto 0);    -- AHB - GPIO-slave HSIZE
        hburst_s    : in    std_logic_vector(2        downto 0);    -- AHB - GPIO-slave HBURST
        hresp_s     : out   std_logic_vector(1        downto 0);    -- AHB - GPIO-slave HRESP
        hready_s    : out   std_logic;                              -- AHB - GPIO-slave HREADYOUT
        hsel_s      : in    std_logic;                              -- AHB - GPIO-slave HSEL
        -- GPIO side
        gpi         : in    std_logic_vector(gpio_w-1 downto 0);    -- GPIO input
        gpo         : out   std_logic_vector(gpio_w-1 downto 0);    -- GPIO output
        gpd         : out   std_logic_vector(gpio_w-1 downto 0)     -- GPIO direction
    );
end nf_ahb_gpio;

architecture rtl of nf_ahb_gpio is
    -- wires 
    signal gpio_request     : std_logic_vector(0  downto 0);    -- gpio request
    signal gpio_wrequest    : std_logic_vector(0  downto 0);    -- gpio write request
    signal gpio_addr        : std_logic_vector(31 downto 0);    -- gpio address
    signal gpio_we          : std_logic_vector(0  downto 0);    -- gpio write enable

    signal addr             : std_logic_vector(31 downto 0);    -- address for gpio module
    signal rd               : std_logic_vector(31 downto 0);    -- read data from gpio module
    signal wd               : std_logic_vector(31 downto 0);    -- write data for gpio module
    signal we               : std_logic;                        -- write enable for gpio module

    signal hready_s_i   : std_logic_vector(0  downto 0);    -- hready_s internal
    -- nf_register
    component nf_register
        generic
        (
            width   : integer   := 1
        );
        port
        (
            clk     : in    std_logic;                          -- clk
            resetn  : in    std_logic;                          -- resetn
            datai   : in    std_logic_vector(width-1 downto 0); -- in data
            datao   : out   std_logic_vector(width-1 downto 0)  -- out data
        );
    end component;
    -- nf_register_we
    component nf_register_we
        generic
        (
            width   : integer   := 1
        );
        port
        (
            clk     : in    std_logic;                          -- clk
            resetn  : in    std_logic;                          -- resetn
            we      : in    std_logic;                          -- write enable
            datai   : in    std_logic_vector(width-1 downto 0); -- in data
            datao   : out   std_logic_vector(width-1 downto 0)  -- out data
        );
    end component; 
    -- nf_gpio
    component nf_gpio
        generic
        (
            gpio_w  : integer := NF_GPIO_WIDTH                      -- width gpio port
        );
        port 
        (
            -- clock and reset
            clk     : in    std_logic;                              -- clock
            resetn  : in    std_logic;                              -- reset
            -- nf_router side
            addr    : in    std_logic_vector(31       downto 0);    -- address
            we      : in    std_logic;                              -- write enable
            wd      : in    std_logic_vector(31       downto 0);    -- write data
            rd      : out   std_logic_vector(31       downto 0);    -- read data
            -- gpio_side
            gpi     : in    std_logic_vector(gpio_w-1 downto 0);    -- GPIO input
            gpo     : out   std_logic_vector(gpio_w-1 downto 0);    -- GPIO output
            gpd     : out   std_logic_vector(gpio_w-1 downto 0)     -- GPIO direction
        );
    end component;
begin

    addr     <= gpio_addr;
    we       <= gpio_we(0);
    wd       <= hwdata_s;
    hrdata_s <= rd;
    hresp_s  <= AHB_HRESP_OKAY;
    hready_s <= hready_s_i(0);
    gpio_request  <= sl2slv( hsel_s and bool2sl( htrans_s /= AHB_HTRANS_IDLE) );
    gpio_wrequest <= gpio_request and sl2slv(hwrite_s);

    -- creating control and address registers
    gpio_addr_ff : nf_register_we generic map( 32 ) port map ( hclk, hresetn, gpio_request(0) , haddr_s, gpio_addr );
    gpio_wreq_ff : nf_register    generic map(  1 ) port map ( hclk, hresetn, gpio_wrequest , gpio_we    );
    hready_ff    : nf_register    generic map(  1 ) port map ( hclk, hresetn, gpio_request  , hready_s_i );
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

end rtl; -- nf_ahb_gpio
