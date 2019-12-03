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
        un      : std_logic_vector(3 downto 0); -- unused
        rx_en   : std_logic_vector(0 downto 0); -- receiver enable
        tx_en   : std_logic_vector(0 downto 0); -- transmitter enable
        rx_val  : std_logic_vector(0 downto 0); -- rx byte received
        busy_tx : std_logic_vector(0 downto 0); -- transmit busy
    end record; -- uart control reg

    function ucr2slv(ucr_v : ucr ) return std_logic_vector;

end nf_uart_pkg;

package body nf_uart_pkg is

    function ucr2slv( ucr_v : ucr ) return std_logic_vector is
        variable ret_svl : std_logic_vector(7 downto 0);
    begin
        ret_svl := ucr_v.un & ucr_v.rx_en & ucr_v.tx_en & ucr_v.rx_val & ucr_v.busy_tx;
        return ret_svl;
    end function;

end nf_uart_pkg;
