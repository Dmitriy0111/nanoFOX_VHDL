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

entity nf_branch_unit is
    port 
    (
        branch_type : in    std_logic;                      -- from control unit, '1 if branch instruction
        branch_hf   : in    std_logic;                      -- branch help field
        d1          : in    std_logic_vector(31 downto 0);  -- from register file (rd1)
        d2          : in    std_logic_vector(31 downto 0);  -- from register file (rd2)
        pc_src      : out   std_logic                       -- next program counter
    );
end nf_branch_unit;

architecture rtl of nf_branch_unit is
    signal  equal : std_logic;
begin

    equal   <= '1' when ( d1 = d2 ) else '0';
    pc_src  <= branch_type and ( not ( equal xor branch_hf ) );

end rtl; -- nf_branch_unit