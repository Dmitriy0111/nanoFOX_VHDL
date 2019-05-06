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

    type s_mem_if_i is record
        rd_dm       : std_logic_vector(31 downto 0);    -- read data memory
        req_ack_dm  : std_logic;                        -- request acknowledge data memory signal
    end record;

    type s_mem_if_o is record
        addr_dm     : std_logic_vector(31 downto 0);    -- address data memory
        wd_dm       : std_logic_vector(31 downto 0);    -- write data memory
        we_dm       : std_logic;                        -- write enable data memory signal
        size_dm     : std_logic_vector(1  downto 0);    -- size for load/store instructions
        req_dm      : std_logic;                        -- request data memory signal
    end record;

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

    constant I_ADD  : std_logic_vector(2 downto 0) := "000";
    constant I_SLL  : std_logic_vector(2 downto 0) := "001";
    constant I_SLT  : std_logic_vector(2 downto 0) := "010";
    constant I_SLTU : std_logic_vector(2 downto 0) := "011";
    constant I_XOR  : std_logic_vector(2 downto 0) := "100";
    constant I_SRL  : std_logic_vector(2 downto 0) := "101";
    constant I_OR   : std_logic_vector(2 downto 0) := "110";
    constant I_AND  : std_logic_vector(2 downto 0) := "111";

    -- ALU commands
    constant ALU_ADD : std_logic_vector(3 downto 0) := "0000";
    constant ALU_OR  : std_logic_vector(3 downto 0) := "0001";
    constant ALU_LUI : std_logic_vector(3 downto 0) := "0010";
    constant ALU_SLL : std_logic_vector(3 downto 0) := "0011";
    constant ALU_SRL : std_logic_vector(3 downto 0) := "0100";
    constant ALU_AND : std_logic_vector(3 downto 0) := "0101";
    constant ALU_XOR : std_logic_vector(3 downto 0) := "0110";
    
    -- branch type constants
    constant B_NONE     : std_logic_vector(3 downto 0) := 4X"0";
    constant B_EQ_NEQ   : std_logic_vector(3 downto 0) := 4X"1";
    constant B_GE_LT    : std_logic_vector(3 downto 0) := 4X"2";
    constant B_GEU_LTU  : std_logic_vector(3 downto 0) := 4X"4";
    constant B_UB       : std_logic_vector(3 downto 0) := 4X"8";
    -- srcB select constants
    constant SRCB_IMM   : std_logic_vector(0 downto 0) := "0";
    constant SRCB_RD2   : std_logic_vector(0 downto 0) := "1";
    -- src shift select constants
    constant SRCS_SHAMT : std_logic_vector(0 downto 0) := "0";
    constant SRCS_RD2   : std_logic_vector(0 downto 0) := "1";
    -- sign imm select
    constant I_SEL  : std_logic_vector(4 downto 0) := 5X"01";     -- for i type instruction
    constant U_SEL  : std_logic_vector(4 downto 0) := 5X"02";     -- for u type instruction
    constant B_SEL  : std_logic_vector(4 downto 0) := 5X"04";     -- for b type instruction
    constant S_SEL  : std_logic_vector(4 downto 0) := 5X"08";     -- for s type instruction
    constant J_SEL  : std_logic_vector(4 downto 0) := 5X"10";     -- for j type instruction
    -- RF src constants
    constant RF_ALUR    :   std_logic := '0';                   -- RF write data is ALU result
    constant RF_DMEM    :   std_logic := '1';                   -- RF write data is data memory read data
    -- result src constants
    constant RES_ALU    :   std_logic := '0';
    constant RES_UB     :   std_logic := '1';

    function ret_code( instr_cf_in : instr_cf ) return std_logic_vector;

end package nf_cpu_def;

package body nf_cpu_def is

    function ret_code( instr_cf_in : instr_cf )
    return std_logic_vector is
        variable ret_v : std_logic_vector(8 downto 0);
    begin
        ret_v(8 downto 4) := instr_cf_in.OP;
        ret_v(3 downto 1) := instr_cf_in.F3;
        ret_v(0) := instr_cf_in.F7(5);
        return ret_v;
    end function;

end nf_cpu_def;
