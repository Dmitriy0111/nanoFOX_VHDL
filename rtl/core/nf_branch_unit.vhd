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
use ieee.std_logic_unsigned.all;
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
    --
    signal sub_res      : std_logic_vector(32 downto 0);    -- substruction result
    -- branch wires
    signal beq_bne      : std_logic;                        -- for beq and bne instructions
    signal blt_bge      : std_logic;                        -- for 
    signal bltu_bgeu    : std_logic;                        -- for 
    -- for less and greater operation
    signal zero         : std_logic;                        -- zero flag
    signal sign         : std_logic;                        -- sign flag
    signal sof          : std_logic;                        -- substruction overflow flag
    signal carry        : std_logic;                        -- carry flag
    signal equal        : std_logic;                        -- equality flag
begin
    -- finding result of substruction
    sub_res <= ( '0' & d1 ) - ( '0' & d2 );
    -- finding flags
    equal <= '1' when ( d1 = d2 ) else '0';                 -- equal flag
    zero  <= '1' when sub_res = (31 downto 0 => '0') else '0';   -- finding zero flag
    carry <= sub_res(32);                                   -- finding carry flag
    sign  <= sub_res(31);                                   -- finding sign flag
    sof   <= ( ( not d1(31) ) and d2(31) and sub_res(31) ) or ( d1(31) and ( not d2(31) ) and ( not sub_res(31) ) ); -- finding substruction overflow flag
    -- finding substruction overflow
    beq_bne   <= branch_type(0) and ( not ( equal         xor branch_hf ) );    -- finding result for beq or bne operation
    --beq_bne   <= branch_type(0) and ( not ( zero          xor branch_hf ) );    -- finding result for beq or bne operation
    blt_bge   <= branch_type(1) and ( not ( sign  xor sof xor branch_hf ) );    -- finding result for blt or bge operation
    bltu_bgeu <= branch_type(2) and ( not ( carry         xor branch_hf ) );    -- finding result for bltu or bgeu operation
    -- finding pc source
    pc_src <= beq_bne or blt_bge or bltu_bgeu or branch_type(3);

end rtl; -- nf_branch_unit
