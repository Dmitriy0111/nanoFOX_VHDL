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

    function bank_init( bank_number : integer; full_ram : mem_t; bank_depth : integer ) return mem_t;

end package nf_mem_pkg;

package body nf_mem_pkg is

    function bank_init( bank_number : integer; full_ram : mem_t; bank_depth : integer ) return mem_t is
        variable bank_ret : mem_t(bank_depth-1 downto 0)(7 downto 0);
    begin
        for i in 0 to bank_depth-1 loop
            bank_ret(i) := full_ram( i*4 + bank_number );
        end loop;
        return bank_ret;
    end function;

end nf_mem_pkg;
