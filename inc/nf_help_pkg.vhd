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

    function bool2sl(bool_v : boolean) return std_logic;

    function sl2slv(sl_v : std_logic ; slv_v : std_logic_vector := "0" ) return std_logic_vector;

    function repbit(sl_v : std_logic ; rep : integer) return std_logic_vector;

    function sel_slv(bool_v : boolean ; slv_1 : std_logic_vector ; slv_0 : std_logic_vector ) return std_logic_vector;

end package nf_help_pkg;

package body nf_help_pkg is

    function bool2sl(bool_v : boolean) return std_logic is
    begin
        if bool_v then
            return '1';
        else 
            return '0';
        end if;
    end function;

    function sl2slv(sl_v : std_logic ; slv_v : std_logic_vector := "0" ) return std_logic_vector is
        variable ret_slv : std_logic_vector(slv_v'range);
    begin
        ret_slv := (others => sl_v);
        return ret_slv;
    end function;

    function repbit(sl_v : std_logic ; rep : integer) return std_logic_vector is
        variable ret_slv : std_logic_vector(rep-1 downto 0);
    begin
        rep_gen : for i in 0 to rep-1 loop
            ret_slv(i) := sl_v;
        end loop ; -- rep_gen
        return ret_slv;
    end function;

    function sel_slv(bool_v : boolean ; slv_1 : std_logic_vector ; slv_0 : std_logic_vector ) return std_logic_vector is
        variable ret_slv : std_logic_vector(slv_1'range);
    begin
        if( bool_v ) then 
            ret_slv := slv_1;
        else
            ret_slv := slv_0;
        end if;
        return ret_slv;
    end function;

end nf_help_pkg;
