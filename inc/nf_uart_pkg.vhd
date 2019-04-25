--
-- File            :   nf_uart_pkg.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.04.25
-- Language        :   VHDL
-- Description     :   This is uart package
-- Copyright(c)    :   2019 Vlasov D.V.
--

library ieee;
use ieee.std_logic_1164.all;

package nf_uart_pkg is

    type ucr is record
        UN      : std_logic_vector(3 downto 0); -- unused
        RX_EN   : std_logic_vector(0 downto 0); -- receiver enable
        TX_EN   : std_logic_vector(0 downto 0); -- transmitter enable
        RX_VAL  : std_logic_vector(0 downto 0); -- rx byte received
        TX_REQ  : std_logic_vector(0 downto 0); -- request transmit
    end record; -- uart control reg

    function ucr2slv(ucr_v : ucr ) return std_logic_vector;

end nf_uart_pkg;

package body nf_uart_pkg is

    function ucr2slv( ucr_v : ucr ) return std_logic_vector is
        variable ret_svl : std_logic_vector(7 downto 0);
    begin
        ret_svl := ucr_v.UN & ucr_v.RX_EN & ucr_v.TX_EN & ucr_v.RX_VAL & ucr_v.TX_REQ;
        return ret_svl;
    end function;

end nf_uart_pkg;
