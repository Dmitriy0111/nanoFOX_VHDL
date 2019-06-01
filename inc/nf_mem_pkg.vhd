--
-- File            :   nf_mem_pkg.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.04.24
-- Language        :   VHDL
-- Description     :   This is cpu unit commands
-- Copyright(c)    :   2019 Vlasov D.V.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package nf_mem_pkg is

    type    mem_t is array (natural range<>) of std_logic_vector; 

    function mem_i( init_i : boolean ; in_mem : mem_t ; ram_depth : integer ) return mem_t;

end package nf_mem_pkg;

package body nf_mem_pkg is

    function mem_i( init_i : boolean ; in_mem : mem_t ; ram_depth : integer ) return mem_t is
        variable mem_ret : mem_t(ram_depth-1 downto 0)(31 downto 0) := ( others => X"XXXXXXXX" );
    begin
        if( init_i ) then
            mem_ret := in_mem;
        end if;
        return mem_ret;
    end function; -- mem_i

end nf_mem_pkg;
