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
        --I_NAME  : string;                           -- instruction name
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

    -- LUI      -    Load Upper Immediate
    --          rd = Immed << 12
    constant I_LUI   : instr_cf := ( RVI , "01101" , "---" , "-------" );
    -- AUIPC    -  U-type, Add upper immediate to PC
    --          rd = PC + Immed << 12
    constant I_AUIPC : instr_cf := ( RVI , "00101" , "---" , "-------" );
    -- JAL      -   J-type, Jump and load PC + 4 in register
    --          rd = PC + 4
    --          PC = Immed << 12
    constant I_JAL   : instr_cf := ( RVI , "11011" , "---" , "-------" );
    -- JAL      -    J-type, Jump and load PC + 4 in register
    --          rd = PC + 4
    --          PC = Immed << 12
    constant I_JALR  : instr_cf := ( RVI , "11001" , "---" , "-------" );
    -- BEQ      -    B-type, Branch if equal
    -- 
    constant I_BEQ   : instr_cf := ( RVI , "11000" , "000" , "-------" );
    -- BNE      -    B-type, Branch if not equal
    -- 
    constant I_BNE   : instr_cf := ( RVI , "11000" , "001" , "-------" );
    -- BLT      -    B-type, Branch if less
    -- 
    constant I_BLT   : instr_cf := ( RVI , "11000" , "100" , "-------" );
    -- BGE      -    B-type, Branch if greater
    -- 
    constant I_BGE   : instr_cf := ( RVI , "11000" , "101" , "-------" );
    -- BLTU     -   B-type, Branch if less unsigned
    -- 
    constant I_BLTU  : instr_cf := ( RVI , "11000" , "110" , "-------" );
    -- BGEU     -   B-type, Branch if greater unsigned
    --
    constant I_BGEU  : instr_cf := ( RVI , "11000" , "111" , "-------" );
    -- LB       -     I-type, Load byte
    --          rd = mem[addr]
    constant I_LB    : instr_cf := ( RVI , "00000" , "000" , "-------" );
    -- LH       -     I-type, Load half word
    --          rd = mem[addr]
    constant I_LH    : instr_cf := ( RVI , "00000" , "001" , "-------" );
    -- LW       -     I-type, Load word
    --          rd = mem[addr]
    constant I_LW    : instr_cf := ( RVI , "00000" , "010" , "-------" );
    -- LBU      -    I-type, Load byte unsigned
    --          rd = mem[addr]
    constant I_LBU   : instr_cf := ( RVI , "00000" , "100" , "-------" );
    -- LHU      -    I-type, Load half word unsigned
    --          rd = mem[addr]
    constant I_LHU   : instr_cf := ( RVI , "00000" , "101" , "-------" );
    -- SB       -     S-type, Store byte
    --          mem[addr] = rs1
    constant I_SB    : instr_cf := ( RVI , "01000" , "000" , "-------" );
    -- SH       -     S-type, Store half word
    --          mem[addr] = rs1
    constant I_SH    : instr_cf := ( RVI , "01000" , "001" , "-------" );
    -- SW       -     S-type, Store word
    --          mem[addr] = rs1
    constant I_SW    : instr_cf := ( RVI , "01000" , "010" , "-------" );
    -- ADDI     -   I-type, Adding with immidiate
    --          rd = rs1 + Immed
    constant I_ADDI  : instr_cf := ( RVI , "00100" , "000" , "-------" );
    -- SLTI     -   I-type, Set less immidiate
    --          rd = rs1 < signed   ( Immed ) - '0 : '1
    constant I_SLTI  : instr_cf := ( RVI , "00100" , "010" , "-------" );
    -- SLTIU    -  I-type, Set less unsigned immidiate
    --          rd = rs1 < unsigned ( Immed ) - '0 : '1
    constant I_SLTIU : instr_cf := ( RVI , "00100" , "011" , "-------" );
    -- XORI     -   I-type, Excluding Or operation with immidiate
    --          rd = rs1 ^ Immed
    constant I_XORI  : instr_cf := ( RVI , "00100" , "100" , "-------" );
    -- ORI      -    I-type, Or operation with immidiate
    --          rd = rs1 | Immed
    constant I_ORI   : instr_cf := ( RVI , "00100" , "110" , "-------" );
    -- ANDI     -   I-type, And operation with immidiate
    --          rd = rs1 , Immed
    constant I_ANDI  : instr_cf := ( RVI , "00100" , "111" , "-------" );
    -- SLLI     -   I-type, Shift Left Logical
    --          rd = rs1 << shamt
    constant I_SLLI  : instr_cf := ( RVI , "00100" , "001" , "0000000" );
    -- SRLI     -   I-type, Shift Right Logical
    --          rd = rs1 >> shamt
    constant I_SRLI  : instr_cf := ( RVI , "00100" , "101" , "0000000" );
    -- SRAI     -   I-type, Shift Right Arifmetical
    --          rd = rs1 >> shamt
    constant I_SRAI  : instr_cf := ( RVI , "00100" , "101" , "0100000" );
    -- ADD      -    R-type, Adding with register
    --          rd = rs1 + rs2
    constant I_ADD   : instr_cf := ( RVI , "01100" , "000" , "0000000" );
    -- SUB      -    R-type, Adding with register
    --          rd = rs1 - rs2
    constant I_SUB   : instr_cf := ( RVI , "01100" , "000" , "0100000" );
    -- SLL      -    R-type, Set left logical
    --          rd = rs1 << rs2
    constant I_SLL   : instr_cf := ( RVI , "01100" , "001" , "0000000" );
    -- SLT      -    R-type, Set less
    --          rd = rs1 < rs2 - '0 : '1
    constant I_SLT   : instr_cf := ( RVI , "01100" , "010" , "0000000" );
    -- SLTU     -   R-type, Set less unsigned
    --          rd = rs1 < rs2 - '0 : '1
    constant I_SLTU  : instr_cf := ( RVI , "01100" , "011" , "0000000" );
    -- XOR      -    R-type, Excluding Or two register
    --          rd = rs1 ^ rs2
    constant I_XOR   : instr_cf := ( RVI , "01100" , "100" , "0000000" );
    -- SRL      -    R-type, Set right logical
    --          rd = rs1 >> rs2
    constant I_SRL   : instr_cf := ( RVI , "01100" , "101" , "0000000" );
    -- SRA      -    R-type, Set right arifmetical
    --          rd = rs1 >> rs2
    constant I_SRA   : instr_cf := ( RVI , "01100" , "101" , "0100000" );
    -- OR       -     R-type, Or two register
    --          rd = rs1 | rs2
    constant I_OR    : instr_cf := ( RVI , "01100" , "110" , "0000000" );
    -- AND      -    R-type, And two register
    --          rd = rs1 , rs2
    constant I_AND   : instr_cf := ( RVI , "01100" , "111" , "0000000" );
    -- VER      -    For verification
    constant I_VER   : instr_cf := ( RVI , "-----" , "---" , "-------" );

    -- ALU commands
    constant ALU_ADD : std_logic_vector(3 downto 0) := "0000";
    constant ALU_OR  : std_logic_vector(3 downto 0) := "0001";
    constant ALU_LUI : std_logic_vector(3 downto 0) := "0010";
    constant ALU_SLL : std_logic_vector(3 downto 0) := "0011";
    constant ALU_SRL : std_logic_vector(3 downto 0) := "0100";
    constant ALU_SUB : std_logic_vector(3 downto 0) := "0101";
    constant ALU_AND : std_logic_vector(3 downto 0) := "0110";
    constant ALU_XOR : std_logic_vector(3 downto 0) := "0111";
    
    -- branch type constants
    constant B_NONE     : std_logic_vector(3 downto 0) := 4X"0";
    constant B_EQ_NEQ   : std_logic_vector(3 downto 0) := 4X"1";
    constant B_GE_LT    : std_logic_vector(3 downto 0) := 4X"2";
    constant B_GEU_LTU  : std_logic_vector(3 downto 0) := 4X"4";
    constant B_UB       : std_logic_vector(3 downto 0) := 4X"8";
    -- srcB select constants
    constant SRCB_IMM   : std_logic_vector(0 downto 0) := "0";
    constant SRCB_RD2   : std_logic_vector(0 downto 0) := "1";
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
