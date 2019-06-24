--
-- File            :   nf_ahb_top.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.04.26
-- Language        :   VHDL
-- Description     :   This is AHB top module
-- Copyright(c)    :   2019 Vlasov D.V.
--

library ieee;
use ieee.std_logic_1164.all;
library nf;
use nf.nf_settings.all;
use nf.nf_components.all;

entity nf_ahb_top is
    generic
    (
        slave_c     : integer := SLAVE_COUNT
    );
    port
    (
        clk         : in   std_logic;                                       -- clk
        resetn      : in   std_logic;                                       -- resetn
        -- AHB slaves side
        haddr_s     : out  logic_v_array(slave_c-1 downto 0)(31 downto 0);  -- AHB - Slave HADDR 
        hwdata_s    : out  logic_v_array(slave_c-1 downto 0)(31 downto 0);  -- AHB - Slave HWDATA 
        hrdata_s    : in   logic_v_array(slave_c-1 downto 0)(31 downto 0);  -- AHB - Slave HRDATA 
        hwrite_s    : out  logic_array  (slave_c-1 downto 0);               -- AHB - Slave HWRITE 
        htrans_s    : out  logic_v_array(slave_c-1 downto 0)(1  downto 0);  -- AHB - Slave HTRANS 
        hsize_s     : out  logic_v_array(slave_c-1 downto 0)(2  downto 0);  -- AHB - Slave HSIZE 
        hburst_s    : out  logic_v_array(slave_c-1 downto 0)(2  downto 0);  -- AHB - Slave HBURST 
        hresp_s     : in   logic_v_array(slave_c-1 downto 0)(1  downto 0);  -- AHB - Slave HRESP 
        hready_s    : in   logic_array  (slave_c-1 downto 0);               -- AHB - Slave HREADYOUT 
        hsel_s      : out  logic_array  (slave_c-1 downto 0);               -- AHB - Slave HSEL
        -- core side
        addr        : in   std_logic_vector(31 downto 0);                   -- address memory
        rd          : out  std_logic_vector(31 downto 0);                   -- read memory
        wd          : in   std_logic_vector(31 downto 0);                   -- write memory
        we          : in   std_logic;                                       -- write enable signal
        size        : in   std_logic_vector(1  downto 0);                   -- size for load/store instructions
        req         : in   std_logic;                                       -- request memory signal
        req_ack     : out  std_logic                                        -- request acknowledge memory signal
    );
end nf_ahb_top;

architecture rtl of nf_ahb_top is
    signal haddr    : std_logic_vector(31 downto 0);
    signal hwdata   : std_logic_vector(31 downto 0);
    signal hrdata   : std_logic_vector(31 downto 0);
    signal hwrite   : std_logic;
    signal htrans   : std_logic_vector(1  downto 0);
    signal hsize    : std_logic_vector(2  downto 0);
    signal hburst   : std_logic_vector(2  downto 0);
    signal hresp    : std_logic_vector(1  downto 0);
    signal hready   : std_logic;
begin

    -- creating one ahb to core unit
    nf_ahb2core_0 : nf_ahb2core
    port map
    (
        clk         => clk,     -- clk
        resetn      => resetn,  -- resetn
        -- AHB side
        haddr       => haddr,   -- AHB HADDR
        hwdata      => hwdata,  -- AHB HWDATA
        hrdata      => hrdata,  -- AHB HRDATA
        hwrite      => hwrite,  -- AHB HWRITE
        htrans      => htrans,  -- AHB HTRANS
        hsize       => hsize,   -- AHB HSIZE
        hburst      => hburst,  -- AHB HBURST
        hresp       => hresp,   -- AHB HRESP
        hready      => hready,  -- AHB HREADY
        -- core side
        addr        => addr,    -- address memory
        we          => we,      -- write enable signal
        wd          => wd,      -- write memory
        rd          => rd,      -- read memory
        size        => size,    -- size for load/store instructions
        req         => req,     -- request memory signal
        req_ack     => req_ack  -- request acknowledge memory signal
    );
    -- creating one ahb router
    nf_ahb_router_0 : nf_ahb_router 
    generic map
    (
        slave_c     => slave_c
    )
    port map
    (
        hclk        => clk,         -- clk
        hresetn     => resetn,      -- resetn
        -- Master side
        haddr       => haddr,       -- AHB - Master HADDR
        hwdata      => hwdata,      -- AHB - Master HWDATA
        hrdata      => hrdata,      -- AHB - Master HRDATA
        hwrite      => hwrite,      -- AHB - Master HWRITE
        htrans      => htrans,      -- AHB - Master HTRANS 
        hsize       => hsize,       -- AHB - Master HSIZE
        hburst      => hburst,      -- AHB - Master HBURST
        hresp       => hresp,       -- AHB - Master HRESP
        hready      => hready,      -- AHB - Master HREADY
        -- Slaves side
        haddr_s     => haddr_s,     -- AHB - Slave HADDR 
        hwdata_s    => hwdata_s,    -- AHB - Slave HWDATA 
        hrdata_s    => hrdata_s,    -- AHB - Slave HRDATA 
        hwrite_s    => hwrite_s,    -- AHB - Slave HWRITE 
        htrans_s    => htrans_s,    -- AHB - Slave HTRANS 
        hsize_s     => hsize_s,     -- AHB - Slave HSIZE 
        hburst_s    => hburst_s,    -- AHB - Slave HBURST 
        hresp_s     => hresp_s,     -- AHB - Slave HRESP 
        hready_s    => hready_s,    -- AHB - Slave HREADY 
        hsel_s      => hsel_s       -- AHB - Slave HSEL
    );

end rtl; -- nf_ahb_top
