--
-- File            :   nf_ahb_uart.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.04.26
-- Language        :   VHDL
-- Description     :   This is AHB UART module
-- Copyright(c)    :   2019 Vlasov D.V.
--

library ieee;
use ieee.std_logic_1164.all;
library nf;
use nf.nf_settings.all;
use nf.nf_ahb_pkg.all;
use nf.nf_help_pkg.all;
use nf.nf_components.all;

entity nf_ahb_uart is
    port
    (
        -- clock and reset
        hclk        : in   std_logic;                       -- hclock
        hresetn     : in   std_logic;                       -- hresetn
        -- AHB UART slave side
        haddr_s     : in   std_logic_vector(31 downto 0);   -- AHB - UART-slave HADDR
        hwdata_s    : in   std_logic_vector(31 downto 0);   -- AHB - UART-slave HWDATA
        hrdata_s    : out  std_logic_vector(31 downto 0);   -- AHB - UART-slave HRDATA
        hwrite_s    : in   std_logic;                       -- AHB - UART-slave HWRITE
        htrans_s    : in   std_logic_vector(1  downto 0);   -- AHB - UART-slave HTRANS
        hsize_s     : in   std_logic_vector(2  downto 0);   -- AHB - UART-slave HSIZE
        hburst_s    : in   std_logic_vector(2  downto 0);   -- AHB - UART-slave HBURST
        hresp_s     : out  std_logic_vector(1  downto 0);   -- AHB - UART-slave HRESP
        hready_s    : out  std_logic;                       -- AHB - UART-slave HREADYOUT
        hsel_s      : in   std_logic;                       -- AHB - UART-slave HSEL
        -- UART side
        uart_tx     : out  std_logic;                       -- UART tx wire
        uart_rx     : in   std_logic                        -- UART rx wire
    );
end nf_ahb_uart;

architecture rtl of nf_ahb_uart is
    -- wires 
    signal uart_request     : std_logic_vector(0  downto 0);    -- uart request
    signal uart_wrequest    : std_logic_vector(0  downto 0);    -- uart write request
    signal uart_addr        : std_logic_vector(31 downto 0);    -- uart address
    signal uart_we          : std_logic_vector(0  downto 0);    -- uart write enable

    signal addr             : std_logic_vector(31 downto 0);    -- address for uart module
    signal rd               : std_logic_vector(31 downto 0);    -- read data from uart module
    signal wd               : std_logic_vector(31 downto 0);    -- write data for uart module
    signal we               : std_logic;                        -- write enable for uart module

    signal hready_s_i   : std_logic_vector(0  downto 0);    -- hready_s internal
begin

    addr     <= uart_addr;
    we       <= uart_we(0);
    wd       <= hwdata_s;
    hrdata_s <= rd;
    hresp_s  <= AHB_HRESP_OKAY;
    hready_s <= hready_s_i(0);
    uart_request  <= sl2slv( hsel_s and bool2sl( htrans_s /= AHB_HTRANS_IDLE) );
    uart_wrequest <= uart_request and sl2slv(hwrite_s);

    -- creating control and address registers
    uart_addr_ff : nf_register_we generic map( 32 ) port map ( hclk, hresetn, uart_request(0) , haddr_s, uart_addr );
    uart_wreq_ff : nf_register    generic map(  1 ) port map ( hclk, hresetn, uart_wrequest , uart_we    );
    hready_ff    : nf_register    generic map(  1 ) port map ( hclk, hresetn, uart_request  , hready_s_i );
    -- creating one uart top module
    nf_uart_top_0 : nf_uart_top 
    port map
    (
        -- reset and clock
        clk         => hclk,    -- clk
        resetn      => hresetn, -- resetn
        -- bus side
        addr        => addr,    -- address
        we          => we,      -- write enable
        wd          => wd,      -- write data
        rd          => rd,      -- read data
        -- UART side
        uart_tx     => uart_tx, -- UART tx wire
        uart_rx     => uart_rx  -- UART rx wire
    );

end rtl; -- nf_ahb_uart
