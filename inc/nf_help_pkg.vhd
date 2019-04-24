--
-- File            :   nf_help_pkg.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.04.24
-- Language        :   VHDL
-- Description     :   This is help package
-- Copyright(c)    :   2019 Vlasov D.V.
--

library ieee;
use ieee.std_logic_1164.all;

package nf_help_pkg is

    function bool2lv(bool_v : boolean) return std_logic;

end package nf_help_pkg;

package body nf_help_pkg is

    function bool2lv(bool_v : boolean) return std_logic is
        begin
            if bool_v then
                return '1';
            else 
                return '0';
            end if;
    end function;

end nf_help_pkg;
