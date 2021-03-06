--
-- File            :   nf_top_ahb.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.04.19
-- Language        :   VHDL
-- Description     :   This is top unit
-- Copyright(c)    :   2019 Vlasov D.V.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
library nf;
use nf.nf_settings.all;
use nf.nf_program.all;
use nf.nf_mem_pkg.all;
use nf.nf_components.all;

entity nf_top_ahb is
    port
    (
        -- clock and reset
        clk         : in    std_logic;                                  -- clock
        resetn      : in    std_logic;                                  -- reset
        pclk        : in    std_logic;
        presetn     : in    std_logic;
        -- PWM side
        pwm         : out   std_logic;                                  -- PWM output
        -- GPIO side
        gpio_i_0    : in    std_logic_vector(NF_GPIO_WIDTH-1 downto 0); -- GPIO input
        gpio_o_0    : out   std_logic_vector(NF_GPIO_WIDTH-1 downto 0); -- GPIO output
        gpio_d_0    : out   std_logic_vector(NF_GPIO_WIDTH-1 downto 0); -- GPIO direction
        -- UART side
        uart_tx     : out   std_logic;                                  -- UART tx wire
        uart_rx     : in    std_logic                                   -- UART rx wire
    );
end nf_top_ahb;

architecture rtl of nf_top_ahb is
    constant gpio_w     :   integer := NF_GPIO_WIDTH;
    constant slave_c    :   integer := SLAVE_COUNT;

    -- instruction memory (IF)
    signal addr_i       :   std_logic_vector(31 downto 0);          -- address instruction memory
    signal rd_i         :   std_logic_vector(31 downto 0);          -- read instruction memory
    signal wd_i         :   std_logic_vector(31 downto 0);          -- write instruction memory
    signal we_i         :   std_logic;                              -- write enable instruction memory signal
    signal size_i       :   std_logic_vector(1  downto 0);          -- size for load/store instructions
    signal req_i        :   std_logic;                              -- request instruction memory signal
    signal req_ack_i    :   std_logic;                              -- request acknowledge instruction memory signal
    -- data memory and other's
    signal addr_dm      :   std_logic_vector(31 downto 0);          -- address data memory
    signal rd_dm        :   std_logic_vector(31 downto 0);          -- read data memory
    signal wd_dm        :   std_logic_vector(31 downto 0);          -- write data memory
    signal we_dm        :   std_logic;                              -- write enable data memory signal
    signal size_dm      :   std_logic_vector(1  downto 0);          -- size for load/store instructions
    signal req_dm       :   std_logic;                              -- request data memory signal
    signal req_ack_dm   :   std_logic;                              -- request acknowledge data memory signal
    -- cross connect data
    signal addr_cc      :   std_logic_vector(31 downto 0);          -- address cc_data memory
    signal rd_cc        :   std_logic_vector(31 downto 0);          -- read cc_data memory
    signal wd_cc        :   std_logic_vector(31 downto 0);          -- write cc_data memory
    signal we_cc        :   std_logic;                              -- write enable cc_data memory signal
    signal size_cc      :   std_logic_vector(1  downto 0);          -- size for load/store instructions
    signal req_cc       :   std_logic;                              -- request cc_data memory signal
    signal req_ack_cc   :   std_logic;                              -- request acknowledge cc_data memory signal
    -- RAM side
    signal ram_addr     :   std_logic_vector(31 downto 0);          -- addr memory
    signal ram_addr_i   :   std_logic_vector(31 downto 0);          -- addr memory internal
    signal ram_we       :   std_logic_vector(3  downto 0);          -- write enable
    signal ram_wd       :   std_logic_vector(31 downto 0);          -- write data
    signal ram_rd       :   std_logic_vector(31 downto 0);          -- read data
    -- PWM 
    signal pwm_clk      :   std_logic;                              -- PWM clock input
    signal pwm_resetn   :   std_logic;                              -- PWM reset input   
    -- AHB interconnect wires
    signal haddr_s      :   logic_v_array(slave_c-1 downto 0)(31 downto 0); -- AHB - Slave HADDR 
    signal hwdata_s     :   logic_v_array(slave_c-1 downto 0)(31 downto 0); -- AHB - Slave HWDATA 
    signal hrdata_s     :   logic_v_array(slave_c-1 downto 0)(31 downto 0); -- AHB - Slave HRDATA 
    signal hwrite_s     :   logic_array  (slave_c-1 downto 0);              -- AHB - Slave HWRITE 
    signal htrans_s     :   logic_v_array(slave_c-1 downto 0)(1  downto 0); -- AHB - Slave HTRANS 
    signal hsize_s      :   logic_v_array(slave_c-1 downto 0)(2  downto 0); -- AHB - Slave HSIZE 
    signal hburst_s     :   logic_v_array(slave_c-1 downto 0)(2  downto 0); -- AHB - Slave HBURST 
    signal hresp_s      :   logic_v_array(slave_c-1 downto 0)(1  downto 0); -- AHB - Slave HRESP 
    signal hready_s     :   logic_array  (slave_c-1 downto 0);              -- AHB - Slave HREADYOUT 
    signal hsel_s       :   logic_array  (slave_c-1 downto 0);              -- AHB - Slave HSEL
    -- APB interconnect bridge to router
    signal paddr_b2r    :   std_logic_vector(7  downto 0);                  -- APB - bridge to router PADDR
    signal pwdata_b2r   :   std_logic_vector(31 downto 0);                  -- APB - bridge to router PWDATA
    signal prdata_b2r   :   std_logic_vector(31 downto 0);                  -- APB - bridge to router PRDATA
    signal pwrite_b2r   :   std_logic;                                      -- APB - bridge to router PWRITE
    signal penable_b2r  :   std_logic;                                      -- APB - bridge to router PENABLE
    signal pready_b2r   :   std_logic;                                      -- APB - bridge to router PREADY
    signal psel_b2r     :   std_logic;                                      -- APB - bridge to router PSEL
    -- APB interconnect router to slaves
    signal paddr_r2s    :   logic_v_array(1 downto 0)(7  downto 0);         -- APB - slave PADDR
    signal pwdata_r2s   :   logic_v_array(1 downto 0)(31 downto 0);         -- APB - slave PWDATA
    signal prdata_r2s   :   logic_v_array(1 downto 0)(31 downto 0);         -- APB - slave PRDATA
    signal pwrite_r2s   :   logic_array  (1 downto 0);                      -- APB - slave PWRITE
    signal penable_r2s  :   logic_array  (1 downto 0);                      -- APB - slave PENABLE
    signal pready_r2s   :   logic_array  (1 downto 0);                      -- APB - slave PREADY
    signal psel_r2s     :   logic_array  (1 downto 0);                      -- APB - slave PSEL
    --
    signal bus_error    :   std_logic;
begin

    pwm_clk    <= clk;
    pwm_resetn <= resetn;    
    ram_addr_i <= "00" & ram_addr(31 downto 2);

    -- Creating one nf_cpu_0
    nf_cpu_0 : nf_cpu 
    generic map
    (
        ver         => "1.1"
    )
    port map
    (
        -- clock and reset
        clk         => clk,         -- clk  
        resetn      => resetn,      -- resetn
        -- instruction memory (IF)
        addr_i      => addr_i,      -- address instruction memory
        rd_i        => rd_i,        -- read instruction memory
        wd_i        => wd_i,        -- write instruction memory
        we_i        => we_i,        -- write enable instruction memory signal
        size_i      => size_i,      -- size for load/store instructions
        req_i       => req_i,       -- request instruction memory signal
        req_ack_i   => req_ack_i,   -- request acknowledge instruction memory signal
        -- data memory and other's
        addr_dm     => addr_dm,     -- address data memory
        rd_dm       => rd_dm,       -- read data memory
        wd_dm       => wd_dm,       -- write data memory
        we_dm       => we_dm,       -- write enable data memory signal
        size_dm     => size_dm,     -- size for load/store instructions
        req_dm      => req_dm,      -- request data memory signal
        req_ack_dm  => req_ack_dm   -- request acknowledge data memory signal
    );
    -- Creating one nf_cpu_cc_0
    nf_cpu_cc_0 : nf_cpu_cc 
    port map
    (
        -- clock and reset
        clk         => clk,         -- clk
        resetn      => resetn,      -- resetn
        -- instruction memory (IF)
        addr_i      => addr_i,      -- address instruction memory
        rd_i        => rd_i,        -- read instruction memory
        wd_i        => wd_i,        -- write instruction memory
        we_i        => we_i,        -- write enable instruction memory signal
        size_i      => size_i,      -- size for load/store instructions
        req_i       => req_i,       -- request instruction memory signal
        req_ack_i   => req_ack_i,   -- request acknowledge instruction memory signal
        -- data memory and other's
        addr_dm     => addr_dm,     -- address data memory
        rd_dm       => rd_dm,       -- read data memory
        wd_dm       => wd_dm,       -- write data memory
        we_dm       => we_dm,       -- write enable data memory signal
        size_dm     => size_dm,     -- size for load/store instructions
        req_dm      => req_dm,      -- request data memory signal
        req_ack_dm  => req_ack_dm,  -- request acknowledge data memory signal
        -- cross connect data
        addr_cc     => addr_cc,     -- address cc_data memory
        rd_cc       => rd_cc,       -- read cc_data memory
        wd_cc       => wd_cc,       -- write cc_data memory
        we_cc       => we_cc,       -- write enable cc_data memory signal
        size_cc     => size_cc,     -- size for load/store instructions
        req_cc      => req_cc,      -- request cc_data memory signal
        req_ack_cc  => req_ack_cc   -- request acknowledge cc_data memory signal
    );
    -- creating AHB top module
    nf_ahb_top_0 : nf_ahb_top
    generic map
    (
        slave_c => slave_c
    )
    port map
    (
        -- clock and reset
        clk         => clk,         -- clk
        resetn      => resetn,      -- resetn
        -- AHB slaves side
        haddr_s     => haddr_s,     -- AHB - Slave HADDR 
        hwdata_s    => hwdata_s,    -- AHB - Slave HWDATA 
        hrdata_s    => hrdata_s,    -- AHB - Slave HRDATA 
        hwrite_s    => hwrite_s,    -- AHB - Slave HWRITE 
        htrans_s    => htrans_s,    -- AHB - Slave HTRANS 
        hsize_s     => hsize_s,     -- AHB - Slave HSIZE 
        hburst_s    => hburst_s,    -- AHB - Slave HBURST 
        hresp_s     => hresp_s,     -- AHB - Slave HRESP 
        hready_s    => hready_s,    -- AHB - Slave HREADYOUT 
        hsel_s      => hsel_s,      -- AHB - Slave HSEL
        -- core side
        addr        => addr_cc,     -- address memory
        rd          => rd_cc,       -- read memory
        wd          => wd_cc,       -- write memory
        we          => we_cc,       -- write enable signal
        size        => size_cc,     -- size for load/store instructions
        req         => req_cc,      -- request memory signal
        req_ack     => req_ack_cc   -- request acknowledge memory signal
    );
    -- Creating one nf_ahb_ram_0
    nf_ahb_ram_0 : nf_ahb_ram 
    port map
    (
        -- clock and reset
        hclk        => clk,             -- hclk
        hresetn     => resetn,          -- hresetn
        -- AHB RAM slave side
        haddr_s     => haddr_s  (0),    -- AHB - RAM-slave HADDR
        hwdata_s    => hwdata_s (0),    -- AHB - RAM-slave HWDATA
        hrdata_s    => hrdata_s (0),    -- AHB - RAM-slave HRDATA
        hwrite_s    => hwrite_s (0),    -- AHB - RAM-slave HWRITE
        htrans_s    => htrans_s (0),    -- AHB - RAM-slave HTRANS
        hsize_s     => hsize_s  (0),    -- AHB - RAM-slave HSIZE
        hburst_s    => hburst_s (0),    -- AHB - RAM-slave HBURST
        hresp_s     => hresp_s  (0),    -- AHB - RAM-slave HRESP
        hready_s    => hready_s (0),    -- AHB - RAM-slave HREADYOUT
        hsel_s      => hsel_s   (0),    -- AHB - RAM-slave HSEL
        -- RAM side
        ram_addr    => ram_addr,        -- addr memory
        ram_we      => ram_we,          -- write enable
        ram_wd      => ram_wd,          -- write data
        ram_rd      => ram_rd           -- read data
    );
    -- Creating one nf_ahb_uart_0
    nf_ahb_uart_0 : nf_ahb_uart 
    port map
    (
        -- clock and reset
        hclk        => clk,             -- hclock
        hresetn     => resetn,          -- hresetn
        -- Slaves side
        haddr_s     => haddr_s  (1),    -- AHB - UART-slave HADDR
        hwdata_s    => hwdata_s (1),    -- AHB - UART-slave HWDATA
        hrdata_s    => hrdata_s (1),    -- AHB - UART-slave HRDATA
        hwrite_s    => hwrite_s (1),    -- AHB - UART-slave HWRITE
        htrans_s    => htrans_s (1),    -- AHB - UART-slave HTRANS
        hsize_s     => hsize_s  (1),    -- AHB - UART-slave HSIZE
        hburst_s    => hburst_s (1),    -- AHB - UART-slave HBURST
        hresp_s     => hresp_s  (1),    -- AHB - UART-slave HRESP
        hready_s    => hready_s (1),    -- AHB - UART-slave HREADYOUT
        hsel_s      => hsel_s   (1),    -- AHB - UART-slave HSEL
        -- UART side
        uart_tx     => uart_tx,         -- UART tx wire
        uart_rx     => uart_rx          -- UART rx wire
    );
    -- Creating one nf_ahb2apb_bridge_0
    nf_ahb2apb_bridge_0 : nf_ahb2apb_bridge
    generic map
    (
        apb_addr_w  => 8,
        cdc_use     => 1
    )
    port map
    (
        -- AHB clock and reset
        hclk        => clk,             -- AHB clk
        hresetn     => resetn,          -- AHB resetn
        -- AHB - Slave side
        haddr_s     => haddr_s  (2),    -- AHB - slave HADDR
        hwdata_s    => hwdata_s (2),    -- AHB - slave HWDATA
        hrdata_s    => hrdata_s (2),    -- AHB - slave HRDATA
        hwrite_s    => hwrite_s (2),    -- AHB - slave HWRITE
        htrans_s    => htrans_s (2),    -- AHB - slave HTRANS
        hsize_s     => hsize_s  (2),    -- AHB - slave HSIZE
        hburst_s    => hburst_s (2),    -- AHB - slave HBURST
        hresp_s     => hresp_s  (2),    -- AHB - slave HRESP
        hready_s    => hready_s (2),    -- AHB - slave HREADYOUT
        hsel_s      => hsel_s   (2),    -- AHB - slave HSEL
        -- APB clock and reset
        pclk        => pclk,            -- APB clk
        presetn     => presetn,         -- APB resetn
        -- APB - Master side
        paddr_m     => paddr_b2r,       -- APB - master PADDR
        pwdata_m    => pwdata_b2r,      -- APB - master PWDATA
        prdata_m    => prdata_b2r,      -- APB - master PRDATA
        pwrite_m    => pwrite_b2r,      -- APB - master PWRITE
        penable_m   => penable_b2r,     -- APB - master PENABLE
        pready_m    => pready_b2r,      -- APB - master PREADY
        psel_m      => psel_b2r         -- APB - master PSEL
    );
    -- Creating one nf_apb_router_0
    nf_apb_router_0 : nf_apb_router
    generic map
    (
        apb_slave_c => 2,
        apb_addr_w  => 8
    )
    port map
    (
        pclk        => pclk,            -- pclk
        presetn     => presetn,         -- presetn
        -- Master side
        paddr_m     => paddr_b2r,       -- APB - master PADDR
        pwdata_m    => pwdata_b2r,      -- APB - master PWDATA
        prdata_m    => prdata_b2r,      -- APB - master PRDATA
        pwrite_m    => pwrite_b2r,      -- APB - master PWRITE
        penable_m   => penable_b2r,     -- APB - master PENABLE
        pready_m    => pready_b2r,      -- APB - master PREADY
        psel_m      => psel_b2r,        -- APB - master PSEL
        -- Slaves side
        paddr_s     => paddr_r2s,       -- APB - slave PADDR
        pwdata_s    => pwdata_r2s,      -- APB - slave PWDATA
        prdata_s    => prdata_r2s,      -- APB - slave PRDATA
        pwrite_s    => pwrite_r2s,      -- APB - slave PWRITE
        penable_s   => penable_r2s,     -- APB - slave PENABLE
        pready_s    => pready_r2s,      -- APB - slave PREADY
        psel_s      => psel_r2s,        -- APB - slave PSEL
        --
        bus_error   => bus_error
    );
    -- Creating one nf_apb_gpio_0
    nf_apb_gpio_0 : nf_apb_gpio
    generic map
    (
        gpio_w      => 8,
        apb_addr_w  => 8
    )
    port map
    (
        -- clock and reset
        pclk        => pclk,                -- pclock
        presetn     => presetn,             -- presetn
        -- APB GPIO slave side
        paddr_s     => paddr_r2s    (0),    -- APB - GPIO-slave PADDR
        pwdata_s    => pwdata_r2s   (0),    -- APB - GPIO-slave PWDATA
        prdata_s    => prdata_r2s   (0),    -- APB - GPIO-slave PRDATA
        pwrite_s    => pwrite_r2s   (0),    -- APB - GPIO-slave PWRITE
        psel_s      => psel_r2s     (0),    -- APB - GPIO-slave PSEL
        penable_s   => penable_r2s  (0),    -- APB - GPIO-slave PENABLE
        pready_s    => pready_r2s   (0),    -- APB - GPIO-slave PREADY
        -- GPIO side
        gpi         => gpio_i_0,            -- GPIO input
        gpo         => gpio_o_0,            -- GPIO output
        gpd         => gpio_d_0             -- GPIO direction
    );
    -- Creating one nf_apb_pwm_0
    nf_apb_pwm_0 : nf_apb_pwm
    generic map
    (
        pwm_width   => 8,
        apb_addr_w  => 8
    )
    port map
    (
        -- clock and reset
        pclk        => pclk,                -- pclk
        presetn     => presetn,             -- presetn
        -- APB PWM slave side
        paddr_s     => paddr_r2s    (1),    -- APB - PWM-slave PADDR
        pwdata_s    => pwdata_r2s   (1),    -- APB - PWM-slave PWDATA
        prdata_s    => prdata_r2s   (1),    -- APB - PWM-slave PRDATA
        pwrite_s    => pwrite_r2s   (1),    -- APB - PWM-slave PWRITE
        psel_s      => psel_r2s     (1),    -- APB - PWM-slave PSEL
        penable_s   => penable_r2s  (1),    -- APB - PWM-slave PENABLE
        pready_s    => pready_r2s   (1),    -- APB - PWM-slave PREADY
        -- PWM side
        pwm_clk     => pclk,                -- PWM clk
        pwm_resetn  => presetn,             -- PWM resetn
        pwm         => pwm                  -- PWM output signal
    );
    -- Creating one instruction/data memory
    nf_ram_i_d_0 : nf_ram
    generic map
    (
        addr_w  => 12,
        depth   => 4096,
        init    => true,
        i_mem   => program
    )
    port map
    (
        clk     => clk,         -- clk
        addr    => ram_addr_i,  -- addr memory (word addressable)
        we      => ram_we,      -- write enable
        wd      => ram_wd,      -- write data
        rd      => ram_rd       -- read data
    );

end rtl; -- nf_top_ahb
