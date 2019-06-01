--
-- File            :   nf_cpu_def.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.04.19
-- Language        :   VHDL
-- Description     :   This is cpu unit commands
-- Copyright(c)    :   2019 Vlasov D.V.
--

--  Base Instruction Formats for ISA
--  fields          31                           25 24                           20 19       15 14        12 11                         7 6          0
--  instr R-type    |           funct7            | |             rs2             | |   rs1   | |  funct3  | |            rd            | |  opcode  |
--                  ----------------------------------------------------------------------------------------------------------------------------------
--  fields          31                                                           20 19       15 14        12 11                         7 6          0
--  instr I-type    |                          imm[11:0]                          | |   rs1   | |  funct3  | |            rd            | |  opcode  |
--                  ----------------------------------------------------------------------------------------------------------------------------------
--  fields          31                           25 24                           20 19       15 14        12 11                         7 6          0
--  instr S-type    |          imm[11:5]          | |             rs2             | |   rs1   | |  funct3  | |         imm[4:0]         | |  opcode  |
--                  ----------------------------------------------------------------------------------------------------------------------------------
--  fields          31                                                                                    12 11                         7 6          0
--  instr U-type    |                                      imm[31:12]                                      | |            rd            | |  opcode  |
--                  ----------------------------------------------------------------------------------------------------------------------------------
--  fields          31           31 30           25 24                           20 19       15 14        12 11           8 7           7 6          0
--  instr B-type    |   imm[12]   | |  imm[10:5]  | |             rs2             | |   rs1   | |  funct3  | |  imm[4:1]  | |  imm[11]  | |  opcode  |
--                  ----------------------------------------------------------------------------------------------------------------------------------
--  fields          31           31 30                             21 20         20 19                    12 11                         7 6          0
--  instr J-type    |   imm[20]   | |           imm[10:1]           | |  imm[11]  | |      imm[19:12]      | |            rd            | |  opcode  |
--                  ----------------------------------------------------------------------------------------------------------------------------------
--  rs1 and rs2 are sources registers, rd are destination register. 
--  imm is immediate data. 
--  opcode is operation code for instruction
--  funct3 and funct7 help's for encode more instructions with same opcode field

library ieee;
use ieee.std_logic_1164.all;

package nf_cpu_def is

    type instr_cf is record
        I_NAME  : string          (5 downto 1);     -- instruction name
        IT      : std_logic_vector(1 downto 0);     -- instruction type
        OP      : std_logic_vector(4 downto 0);     -- instruction opcode
        F3      : std_logic_vector(2 downto 0);     -- instruction function field 3
        F7      : std_logic_vector(6 downto 0);     -- instruction function field 7
    end record;    -- instruction record

    constant RVI    : std_logic_vector(1 downto 0) := "11";
    constant RVC_0  : std_logic_vector(1 downto 0) := "11";
    constant RVC_1  : std_logic_vector(1 downto 0) := "11";
    constant RVC_2  : std_logic_vector(1 downto 0) := "11";
    constant ANY    : std_logic_vector(1 downto 0) := "--";

    constant R_OP0  : std_logic_vector(4 downto 0) := "01100";  
    constant U_OP0  : std_logic_vector(4 downto 0) := "01101";  -- LUI
    constant U_OP1  : std_logic_vector(4 downto 0) := "00101";  -- AUIPC
    constant J_OP0  : std_logic_vector(4 downto 0) := "11011";  -- JAL
    constant S_OP0  : std_logic_vector(4 downto 0) := "01000";  -- SW,SH,SB,SHU,SBU
    constant B_OP0  : std_logic_vector(4 downto 0) := "11000";  -- BEQ,BNE,BGE,BLT,BGEU,BLTU
    constant I_OP0  : std_logic_vector(4 downto 0) := "00100";  
    constant I_OP1  : std_logic_vector(4 downto 0) := "00000";  -- LW,LH,LB
    constant I_OP2  : std_logic_vector(4 downto 0) := "11001";  -- JALR

    -- ALU commands
    constant ALU_ADD : std_logic_vector(2 downto 0) := "000";
    constant ALU_OR  : std_logic_vector(2 downto 0) := "001";
    constant ALU_LUI : std_logic_vector(2 downto 0) := "010";
    constant ALU_SLL : std_logic_vector(2 downto 0) := "011";
    constant ALU_SUB : std_logic_vector(2 downto 0) := "100";
    -- branch type constants
    constant B_NONE     : std_logic_vector(0 downto 0) := "0";
    constant B_EQ_NEQ   : std_logic_vector(0 downto 0) := "1";
    -- srcB select constants
    constant SRCB_IMM   : std_logic_vector(0 downto 0) := "0";
    constant SRCB_RD1   : std_logic_vector(0 downto 0) := "1";
    -- sign imm select
    constant I_SEL  : std_logic_vector(1 downto 0) := "00";     -- for i type instruction
    constant U_SEL  : std_logic_vector(1 downto 0) := "01";     -- for u type instruction
    constant B_SEL  : std_logic_vector(1 downto 0) := "10";     -- for b type instruction
    -- command constants
    -- opcode field
    constant C_LUI  : std_logic_vector(6 downto 0) := "0110111";    -- U-type, Load upper immediate
                                                                    --         Rt = Immed << 12
    constant C_SLLI : std_logic_vector(6 downto 0) := "0010011";    -- I-type, Shift right logical
                                                                    --         rd = rs1 << shamt
    constant C_ADDI : std_logic_vector(6 downto 0) := "0010011";    -- I-type, Adding with immediate
                                                                    --         rd = rs1 + Immed
    constant C_ADD  : std_logic_vector(6 downto 0) := "0110011";    -- R-type, Adding with register
                                                                    --         rd = rs1 + rs2
    constant C_SUB  : std_logic_vector(6 downto 0) := "0110011";    -- R-type, Adding with register
                                                                    --         rd = rs1 - rs2
    constant C_OR   : std_logic_vector(6 downto 0) := "0110011";    -- R-type, Or with two register
                                                                    --         rd = rs1 | rs2
    constant C_BEQ  : std_logic_vector(6 downto 0) := "1100011";    -- B-type, Branch if equal
                                                                    --         
    constant C_ANY  : std_logic_vector(6 downto 0) := "-------";    -- for verification
    -- function3 field
    constant F3_SLLI    : std_logic_vector(2 downto 0) := "001";    -- I-type, Shift right logical
                                                                    --         rd = rs1 << shamt
    constant F3_ADDI    : std_logic_vector(2 downto 0) := "000";    -- I-type, Adding with immediate
                                                                    --         rd = rs1 + Immed
    constant F3_ADD     : std_logic_vector(2 downto 0) := "000";    -- R-type, Adding with register
                                                                    --         rd = rs1 + rs2
    constant F3_SUB     : std_logic_vector(2 downto 0) := "000";    -- R-type, Subtracting with register
                                                                    --         rd = rs1 - rs2
    constant F3_OR      : std_logic_vector(2 downto 0) := "110";    -- R-type, Or with two register
                                                                    --         rd = rs1 | rs2
    constant F3_BEQ     : std_logic_vector(2 downto 0) := "000";    -- B-type, Branch if equal
                                                                    --         
    constant F3_ANY     : std_logic_vector(2 downto 0) := "---";    -- if instruction haven't function3 field and for verification
    -- function7 field
    constant F7_ADD     : std_logic_vector(6 downto 0) := "0000000";    --R-type, Adding with register
                                                                        --         rd = rs1 + rs2
    constant F7_SUB     : std_logic_vector(6 downto 0) := "0100000";    --R-type, Subtracting with register
                                                                        --         rd = rs1 - rs2        
    constant F7_ANY     : std_logic_vector(6 downto 0) := "-------";    -- if instruction haven't function7 field and for verification

end package nf_cpu_def;
