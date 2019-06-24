--
-- File            :   nf_ahb2core.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.04.25
-- Language        :   VHDL
-- Description     :   This is AHB <-> core bridge
-- Copyright(c)    :   2019 Vlasov D.V.
--

library ieee;
use ieee.std_logic_1164.all;
library nf;
use nf.nf_settings.all;
use nf.nf_ahb_pkg.all;
use nf.nf_help_pkg.all;
use nf.nf_components.all;

entity nf_ahb2core is
    port
    (
        clk     : in   std_logic;                       -- clk
        resetn  : in   std_logic;                       -- resetn
        -- AHB side
        haddr   : out  std_logic_vector(31 downto 0);   -- AHB HADDR
        hwdata  : out  std_logic_vector(31 downto 0);   -- AHB HWDATA
        hrdata  : in   std_logic_vector(31 downto 0);   -- AHB HRDATA
        hwrite  : out  std_logic;                       -- AHB HWRITE
        htrans  : out  std_logic_vector(1  downto 0);   -- AHB HTRANS
        hsize   : out  std_logic_vector(2  downto 0);   -- AHB HSIZE
        hburst  : out  std_logic_vector(2  downto 0);   -- AHB HBURST
        hresp   : in   std_logic_vector(1  downto 0);   -- AHB HRESP
        hready  : in   std_logic;                       -- AHB HREADY
        -- core side
        addr    : in   std_logic_vector(31 downto 0);   -- address memory
        wd      : in   std_logic_vector(31 downto 0);   -- write memory
        rd      : out  std_logic_vector(31 downto 0);   -- read memory
        we      : in   std_logic;                       -- write enable signal
        size    : in   std_logic_vector(1  downto 0);   -- size for load/store instructions
        req     : in   std_logic;                       -- request memory signal
        req_ack : out  std_logic                        -- request acknowledge memory signal
    );
end nf_ahb2core;

architecture rtl of nf_ahb2core is
begin

    haddr   <= addr;
    hwrite  <= we;
    rd      <= hrdata;
    htrans  <= AHB_HTRANS_NONSEQ when req else AHB_HTRANS_IDLE;
    hsize   <= '0' & size;
    hburst  <= AHB_HBUSRT_SINGLE;
    req_ack <= hready and bool2sl( hresp /= AHB_HRESP_ERROR );

    -- creating one write data flip-flop
    wd_dm_ff : nf_register_we generic map( 32 ) port map ( clk, resetn, we, wd, hwdata );

end rtl; -- nf_ahb2core

