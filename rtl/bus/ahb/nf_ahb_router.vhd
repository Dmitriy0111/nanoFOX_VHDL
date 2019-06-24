--
-- File            :   nf_ahb_router.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.04.25
-- Language        :   VHDL
-- Description     :   This is AHB router module
-- Copyright(c)    :   2019 Vlasov D.V.
--

library ieee;
use ieee.std_logic_1164.all;
library nf;
use nf.nf_settings.all;
use nf.nf_ahb_pkg.all;
use nf.nf_components.all;

entity nf_ahb_router is
    generic
    (
        slave_c : integer := SLAVE_COUNT
    );
    port
    (
        hclk        : in   std_logic;                                       -- hclk
        hresetn     : in   std_logic;                                       -- hresetn
        -- Master side
        haddr       : in   std_logic_vector(31 downto 0);                   -- AHB - Master HADDR
        hwdata      : in   std_logic_vector(31 downto 0);                   -- AHB - Master HWDATA
        hrdata      : out  std_logic_vector(31 downto 0);                   -- AHB - Master HRDATA
        hwrite      : in   std_logic;                                       -- AHB - Master HWRITE
        htrans      : in   std_logic_vector(1  downto 0);                   -- AHB - Master HTRANS
        hsize       : in   std_logic_vector(2  downto 0);                   -- AHB - Master HSIZE
        hburst      : in   std_logic_vector(2  downto 0);                   -- AHB - Master HBURST
        hresp       : out  std_logic_vector(1  downto 0);                   -- AHB - Master HRESP
        hready      : out  std_logic;                                       -- AHB - Master HREADY
        -- Slaves side
        haddr_s     : out  logic_v_array(slave_c-1 downto 0)(31 downto 0);  -- AHB - Slave HADDR
        hwdata_s    : out  logic_v_array(slave_c-1 downto 0)(31 downto 0);  -- AHB - Slave HWDATA
        hrdata_s    : in   logic_v_array(slave_c-1 downto 0)(31 downto 0);  -- AHB - Slave HRDATA
        hwrite_s    : out  logic_array  (slave_c-1 downto 0);               -- AHB - Slave HWRITE
        htrans_s    : out  logic_v_array(slave_c-1 downto 0)(1  downto 0);  -- AHB - Slave HTRANS
        hsize_s     : out  logic_v_array(slave_c-1 downto 0)(2  downto 0);  -- AHB - Slave HSIZE
        hburst_s    : out  logic_v_array(slave_c-1 downto 0)(2  downto 0);  -- AHB - Slave HBURST
        hresp_s     : in   logic_v_array(slave_c-1 downto 0)(1  downto 0);  -- AHB - Slave HRESP
        hready_s    : in   logic_array  (slave_c-1 downto 0);               -- AHB - Slave HREADY
        hsel_s      : out  logic_array  (slave_c-1 downto 0)                -- AHB - Slave HSEL
    );
end nf_ahb_router;

architecture rtl of nf_ahb_router is
    -- hsel signals
    signal hsel_ff  : std_logic_vector(slave_c-1 downto 0);
    signal hsel     : std_logic_vector(slave_c-1 downto 0);
begin

    hsel_gen:
    for i in 0 to hsel'length-1 generate
        hsel_s(i) <= hsel(i);
    end generate hsel_gen;

    -- generating wires for all slaves
    ahb_wires_gen:
    for i in 0 to slave_c-1 generate
        haddr_s (i) <= haddr;
        hwdata_s(i) <= hwdata;
        hwrite_s(i) <= hwrite;
        htrans_s(i) <= htrans;
        hsize_s (i) <= hsize;
        hburst_s(i) <= hburst;
    end generate ahb_wires_gen;

    -- creating one hsel flip-flop
    slave_sel_ff : nf_register generic map ( slave_c ) port map ( hclk, hresetn, hsel, hsel_ff );
    -- creating one AHB decoder module
    nf_ahb_dec_0 : nf_ahb_dec
    generic map
    (
        slave_c => slave_c
    )
    port map
    (   
        haddr   => haddr,   -- AHB address
        hsel    => hsel     -- hsel signal
    );
    -- creating one AHB multiplexer module
    nf_ahb_mux_0 : nf_ahb_mux
    generic map
    (
        slave_c     => slave_c
    )
    port map
    (
        hsel_ff     => hsel_ff,     -- hsel after flip-flop
        -- slave side
        hrdata_s    => hrdata_s,    -- AHB read data slaves 
        hresp_s     => hresp_s,     -- AHB response slaves
        hready_s    => hready_s,    -- AHB ready slaves
        -- master side
        hrdata      => hrdata,      -- AHB read data master 
        hresp       => hresp,       -- AHB response master
        hready      => hready       -- AHB ready master
    );

end rtl; -- nf_ahb_router
