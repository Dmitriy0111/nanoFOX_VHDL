--
-- File            :   nf_branch_unit.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.04.19
-- Language        :   VHDL
-- Description     :   This is branch unit
-- Copyright(c)    :   2019 Vlasov D.V.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library nf;
use nf.nf_help_pkg.all;

entity nf_branch_unit is
    port 
    (
        branch_type : in    std_logic_vector(3  downto 0);  -- from control unit, '1 if branch instruction
        branch_hf   : in    std_logic;                      -- branch help field
        d1          : in    std_logic_vector(31 downto 0);  -- from register file (rd1)
        d2          : in    std_logic_vector(31 downto 0);  -- from register file (rd2)
        pc_src      : out   std_logic                       -- next program counter
    );
end nf_branch_unit;

architecture rtl of nf_branch_unit is
    -- for equal and not equal operation
    signal  equal : std_logic;
begin
    -- finding equality
    equal   <= bool2sl( d1 = d2 );
    -- finding pc source
    pc_src  <= branch_type(0) and ( not ( equal xor branch_hf ) );

end rtl; -- nf_branch_unit

