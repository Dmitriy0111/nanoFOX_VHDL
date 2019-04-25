--
-- File            :   nf_ahb_pkg.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.04.25
-- Language        :   VHDL
-- Description     :   This is uart package
-- Copyright(c)    :   2019 Vlasov D.V.
--

library ieee;
use ieee.std_logic_1164.all;

package nf_ahb_pkg is

    -- response constants
    constant AHB_HRESP_OKAY     : std_logic_vector(1 downto 0) := "00";
    constant AHB_HRESP_ERROR    : std_logic_vector(1 downto 0) := "01";
    constant AHB_HRESP_RETRY    : std_logic_vector(1 downto 0) := "10";
    constant AHB_HRESP_SPLIT    : std_logic_vector(1 downto 0) := "11";

    -- transfer constants
    constant AHB_HTRANS_IDLE    : std_logic_vector(1 downto 0) := "00";
    constant AHB_HTRANS_BUSY    : std_logic_vector(1 downto 0) := "01";
    constant AHB_HTRANS_NONSEQ  : std_logic_vector(1 downto 0) := "10";
    constant AHB_HTRANS_SEQ     : std_logic_vector(1 downto 0) := "11";

    -- burst constants
    constant AHB_HBUSRT_SINGLE  : std_logic_vector(2 downto 0) := "000";
    constant AHB_HBUSRT_INCR    : std_logic_vector(2 downto 0) := "001";
    constant AHB_HBUSRT_WRAP4   : std_logic_vector(2 downto 0) := "010";
    constant AHB_HBUSRT_INCR4   : std_logic_vector(2 downto 0) := "011";
    constant AHB_HBUSRT_WRAP8   : std_logic_vector(2 downto 0) := "100";
    constant AHB_HBUSRT_INCR8   : std_logic_vector(2 downto 0) := "101";
    constant AHB_HBUSRT_WRAP16  : std_logic_vector(2 downto 0) := "110";
    constant AHB_HBUSRT_INCR16  : std_logic_vector(2 downto 0) := "111";

    -- size constants
    constant AHB_HSIZE_B        : std_logic_vector(2 downto 0) := "000";
    constant AHB_HSIZE_HW       : std_logic_vector(2 downto 0) := "001";
    constant AHB_HSIZE_W        : std_logic_vector(2 downto 0) := "010";
    constant AHB_HSIZE_NU1      : std_logic_vector(2 downto 0) := "011";
    constant AHB_HSIZE_4W       : std_logic_vector(2 downto 0) := "100";
    constant AHB_HSIZE_8W       : std_logic_vector(2 downto 0) := "101";
    constant AHB_HSIZE_NU2      : std_logic_vector(2 downto 0) := "110";
    constant AHB_HSIZE_NU3      : std_logic_vector(2 downto 0) := "111";

end nf_ahb_pkg;

package body nf_ahb_pkg is

end nf_ahb_pkg;
