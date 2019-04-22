--
-- File            :   nf_instr_mem.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.04.19
-- Language        :   VHDL
-- Description     :   This is instruction memory module
-- Copyright(c)    :   2019 Vlasov D.V.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity nf_instr_mem is
    generic
    (
        depth   : integer := 64                         -- depth of memory array
    );
    port 
    (
        addr    : in    std_logic_vector(31 downto 0);  -- instruction address
        instr   : out   std_logic_vector(31 downto 0)   -- instruction data
    );
end nf_instr_mem;

architecture rtl of nf_instr_mem is
    type    mem_t is array (depth-1 downto 0) of std_logic_vector(31 downto 0); 
    signal  mem : mem_t :=  (   others => X"00000000"   );
begin

    instr <= mem(to_integer(unsigned(addr)));

end rtl; -- nf_instr_mem
