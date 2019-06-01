--
-- File            :   nf_control_unit.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.04.19
-- Language        :   VHDL
-- Description     :   This is controll unit
-- Copyright(c)    :   2019 Vlasov D.V.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library nf;
use nf.nf_cpu_def.all;

entity nf_control_unit is
    port 
    (
        opcode      : in    std_logic_vector(6 downto 0);   -- operation code field in instruction code
        funct3      : in    std_logic_vector(2 downto 0);   -- funct 3 field in instruction code
        funct7      : in    std_logic_vector(6 downto 0);   -- funct 7 field in instruction code
        imm_src     : out   std_logic_vector(1 downto 0);   -- for selecting immediate data
        srcBsel     : out   std_logic;                      -- for selecting srcB ALU
        branch_type : out   std_logic;                      -- for executing branch instructions
        branch_hf   : out   std_logic;                      -- branch help field
        we          : out   std_logic;                      -- write enable signal for register file
        ALU_Code    : out   std_logic_vector(2 downto 0)    -- output code for ALU unit
    );
end nf_control_unit;

architecture rtl of nf_control_unit is
begin

    control_process : process(all)
    begin
        we          <= '0';
        ALU_Code    <= ALU_ADD;
        srcBsel     <= SRCB_IMM(0);
        imm_src     <= I_SEL;
        branch_hf   <= '0';
        branch_type <= B_NONE(0);
        case? ( opcode & funct3 & funct7 ) is
            -- R - type command's
            when C_ADD  & F3_ADD  & F7_ADD => we <= '1' ; ALU_Code <= ALU_ADD ; srcBsel <= SRCB_RD1(0) ;
            when C_SUB  & F3_SUB  & F7_SUB => we <= '1' ; ALU_Code <= ALU_SUB ; srcBsel <= SRCB_RD1(0) ;
            when C_OR   & F3_OR   & F7_ANY => we <= '1' ; ALU_Code <= ALU_OR  ; srcBsel <= SRCB_RD1(0) ;
            -- I - type command's
            when C_SLLI & F3_SLLI & F7_ANY => we <= '1' ; ALU_Code <= ALU_SLL ; srcBsel <= SRCB_IMM(0) ; imm_src <= I_SEL ;
            when C_ADDI & F3_ADDI & F7_ANY => we <= '1' ; ALU_Code <= ALU_ADD ; srcBsel <= SRCB_IMM(0) ; imm_src <= I_SEL ;
            -- U - type command's
            when C_LUI  & F3_ANY  & F7_ANY => we <= '1' ; ALU_Code <= ALU_LUI ; srcBsel <= SRCB_IMM(0) ; imm_src <= U_SEL ;
            -- B - type command's
            when C_BEQ  & F3_BEQ  & F7_ANY => we <= '0' ; ALU_Code <= ALU_ADD ; srcBsel <= SRCB_RD1(0) ; imm_src <= B_SEL ; branch_type <= B_EQ_NEQ(0); branch_hf <= '1';
            -- S - type command's
            -- in the future
            -- J - type command's
            -- in the future
            when others => 
        end case ?;
    end process;

end rtl; -- nf_control_unit
