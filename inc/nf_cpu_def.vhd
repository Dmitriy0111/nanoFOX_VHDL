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
        I_NAME  : string          (6 downto 1);     -- instruction name
        IT      : std_logic_vector(1 downto 0);     -- instruction type
        OP      : std_logic_vector(4 downto 0);     -- instruction opcode
        F3      : std_logic_vector(2 downto 0);     -- instruction function field 3
        F7      : std_logic_vector(6 downto 0);     -- instruction function field 7
        F12     : std_logic_vector(11 downto 0);    -- instruction function field 12
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

    -- instructions
    -- LUI      -    Load Upper Immediate
    --          rd = Immed << 12
    constant I_LUI    : instr_cf := ( "   LUI", RVI , "01101" , "---" , "-------" , "------------");
    -- AUIPC    -  U-type, Add upper immediate to PC
    --          rd = PC + Immed << 12
    constant I_AUIPC  : instr_cf := ( " AUIPC", RVI , "00101" , "---" , "-------" , "------------");
    -- JAL      -   J-type, Jump and load PC + 4 in register
    --          rd = PC + 4
    --          PC = Immed << 12
    constant I_JAL    : instr_cf := ( "   JAL", RVI , "11011" , "---" , "-------" , "------------");
    -- JAL      -    J-type, Jump and load PC + 4 in register
    --          rd = PC + 4
    --          PC = Immed << 12
    constant I_JALR   : instr_cf := ( "  JALR", RVI , "11001" , "---" , "-------" , "------------");
    -- BEQ      -    B-type, Branch if equal
    -- 
    constant I_BEQ    : instr_cf := ( "   BEQ", RVI , "11000" , "000" , "-------" , "------------");
    -- BNE      -    B-type, Branch if not equal
    -- 
    constant I_BNE    : instr_cf := ( "   BNE", RVI , "11000" , "001" , "-------" , "------------");
    -- BLT      -    B-type, Branch if less
    -- 
    constant I_BLT    : instr_cf := ( "   BLT", RVI , "11000" , "100" , "-------" , "------------");
    -- BGE      -    B-type, Branch if greater
    -- 
    constant I_BGE    : instr_cf := ( "   BGE", RVI , "11000" , "101" , "-------" , "------------");
    -- BLTU     -   B-type, Branch if less unsigned
    -- 
    constant I_BLTU   : instr_cf := ( "  BLTU", RVI , "11000" , "110" , "-------" , "------------");
    -- BGEU     -   B-type, Branch if greater unsigned
    --
    constant I_BGEU   : instr_cf := ( "  BGEU", RVI , "11000" , "111" , "-------" , "------------");
    -- LB       -     I-type, Load byte
    --          rd = mem[addr]
    constant I_LB     : instr_cf := ( "    LB", RVI , "00000" , "000" , "-------" , "------------");
    -- LH       -     I-type, Load half word
    --          rd = mem[addr]
    constant I_LH     : instr_cf := ( "    LH", RVI , "00000" , "001" , "-------" , "------------");
    -- LW       -     I-type, Load word
    --          rd = mem[addr]
    constant I_LW     : instr_cf := ( "    LW", RVI , "00000" , "010" , "-------" , "------------");
    -- LBU      -    I-type, Load byte unsigned
    --          rd = mem[addr]
    constant I_LBU    : instr_cf := ( "   LBU", RVI , "00000" , "100" , "-------" , "------------");
    -- LHU      -    I-type, Load half word unsigned
    --          rd = mem[addr]
    constant I_LHU    : instr_cf := ( "   LHU", RVI , "00000" , "101" , "-------" , "------------");
    -- SB       -     S-type, Store byte
    --          mem[addr] = rs1
    constant I_SB     : instr_cf := ( "    SB", RVI , "01000" , "000" , "-------" , "------------");
    -- SH       -     S-type, Store half word
    --          mem[addr] = rs1
    constant I_SH     : instr_cf := ( "    SH", RVI , "01000" , "001" , "-------" , "------------");
    -- SW       -     S-type, Store word
    --          mem[addr] = rs1
    constant I_SW     : instr_cf := ( "    SW", RVI , "01000" , "010" , "-------" , "------------");
    -- ADDI     -   I-type, Adding with immidiate
    --          rd = rs1 + Immed
    constant I_ADDI   : instr_cf := ( "  ADDI", RVI , "00100" , "000" , "-------" , "------------");
    -- SLTI     -   I-type, Set less immidiate
    --          rd = rs1 < signed   ( Immed ) ? '0 : '1
    constant I_SLTI   : instr_cf := ( "  SLTI", RVI , "00100" , "010" , "-------" , "------------");
    -- SLTIU    -  I-type, Set less unsigned immidiate
    --          rd = rs1 < unsigned ( Immed ) ? '0 : '1
    constant I_SLTIU  : instr_cf := ( " SLTIU", RVI , "00100" , "011" , "-------" , "------------");
    -- XORI     -   I-type, Excluding Or operation with immidiate
    --          rd = rs1 ^ Immed
    constant I_XORI   : instr_cf := ( "  XORI", RVI , "00100" , "100" , "-------" , "------------");
    -- ORI      -    I-type, Or operation with immidiate
    --          rd = rs1 | Immed
    constant I_ORI    : instr_cf := ( "   ORI", RVI , "00100" , "110" , "-------" , "------------");
    -- ANDI     -   I-type, And operation with immidiate
    --          rd = rs1 & Immed
    constant I_ANDI   : instr_cf := ( "  ANDI", RVI , "00100" , "111" , "-------" , "------------");
    -- SLLI     -   I-type, Shift Left Logical
    --          rd = rs1 << shamt
    constant I_SLLI   : instr_cf := ( "  SLLI", RVI , "00100" , "001" , "0000000" , "------------");
    -- SRLI     -   I-type, Shift Right Logical
    --          rd = rs1 >> shamt
    constant I_SRLI   : instr_cf := ( "  SRLI", RVI , "00100" , "101" , "0000000" , "------------");
    -- SRAI     -   I-type, Shift Right Arifmetical
    --          rd = rs1 >> shamt
    constant I_SRAI   : instr_cf := ( "  SRAI", RVI , "00100" , "101" , "0100000" , "------------");
    -- ADD      -    R-type, Adding with register
    --          rd = rs1 + rs2
    constant I_ADD    : instr_cf := ( "   ADD", RVI , "01100" , "000" , "0000000" , "------------");
    -- SUB      -    R-type, Adding with register
    --          rd = rs1 - rs2
    constant I_SUB    : instr_cf := ( "   SUB", RVI , "01100" , "000" , "0100000" , "------------");
    -- SLL      -    R-type, Set left logical
    --          rd = rs1 << rs2
    constant I_SLL    : instr_cf := ( "   SLL", RVI , "01100" , "001" , "0000000" , "------------");
    -- SLT      -    R-type, Set less
    --          rd = rs1 < rs2 ? '0 : '1
    constant I_SLT    : instr_cf := ( "   SLT", RVI , "01100" , "010" , "0000000" , "------------");
    -- SLTU     -   R-type, Set less unsigned
    --          rd = rs1 < rs2 ? '0 : '1
    constant I_SLTU   : instr_cf := ( "  SLTU", RVI , "01100" , "011" , "0000000" , "------------");
    -- XOR      -    R-type, Excluding Or two register
    --          rd = rs1 ^ rs2
    constant I_XOR    : instr_cf := ( "   XOR", RVI , "01100" , "100" , "0000000" , "------------");
    -- SRL      -    R-type, Set right logical
    --          rd = rs1 >> rs2
    constant I_SRL    : instr_cf := ( "   SRL", RVI , "01100" , "101" , "0000000" , "------------");
    -- SRA      -    R-type, Set right arifmetical
    --          rd = rs1 >> rs2
    constant I_SRA    : instr_cf := ( "   SRA", RVI , "01100" , "101" , "0100000" , "------------");
    -- OR       -     R-type, Or two register
    --          rd = rs1 | rs2
    constant I_OR     : instr_cf := ( "    OR", RVI , "01100" , "110" , "0000000" , "------------");
    -- AND      -    R-type, And two register
    --          rd = rs1 & rs2
    constant I_AND    : instr_cf := ( "   AND", RVI , "01100" , "111" , "0000000" , "------------");
    -- I_F      -    Flushed instruction
    constant I_F      : instr_cf := ( "   FLU", "00" , "00000" , "000" , "0000000" , "------------" );
    -- I_UNK    -    Unknown instruction
    constant I_UNK    : instr_cf := ( "   UNK", "--" , "-----" , "---" , "-------" , "------------" );

    -- FENCE instructions
    -- FENCE    -    FENCE
    constant I_FENCE    : instr_cf := ( " FENCE", RVI , "00011" , "000" , "-------" , "------------" );
    -- FENCEI   -    FENCE.I
    constant I_FENCEI   : instr_cf := ( "FENCEI", RVI , "00011" , "001" , "-------" , "------------" );
    -- CSR instructions
    -- WFI      -    Wait for interrupt
    constant I_WFI      : instr_cf := ( "   WFI", RVI , "11100" , "000" , "-------" , "000100000101" );
    -- MRET     -    M return
    constant I_MRET     : instr_cf := ( "  MRET", RVI , "11100" , "000" , "-------" , "001100000010" );
    -- ECALL    -    ECALL
    constant I_ECALL    : instr_cf := ( " ECALL", RVI , "11100" , "000" , "-------" , "000000000000" );
    -- EBREAK   -    EBREAK
    constant I_EBREAK   : instr_cf := ( "EBREAK", RVI , "11100" , "000" , "-------" , "000000000001" );
    -- CSRRW    -    Atomic Read/Write CSR
    constant I_CSRRW    : instr_cf := ( " CSRRW", RVI , "11100" , "001" , "-------" , "------------" );
    -- CSRRS    -    Atomic Read and Set Bits in CSR
    constant I_CSRRS    : instr_cf := ( " CSRRS", RVI , "11100" , "010" , "-------" , "------------" );
    -- CSRRC    -    Atomic Read and Clear Bits in CSR
    constant I_CSRRC    : instr_cf := ( " CSRRC", RVI , "11100" , "011" , "-------" , "------------" );
    -- CSRRWI   -    Atomic Read/Write CSR (unsigned immediate)
    constant I_CSRRWI   : instr_cf := ( "CSRRWI", RVI , "11100" , "101" , "-------" , "------------" );
    -- CSRRSI   -    Atomic Read and Set Bits in CSR (unsigned immediate)
    constant I_CSRRSI   : instr_cf := ( "CSRRSI", RVI , "11100" , "110" , "-------" , "------------" );
    -- CSRRCI   -    Atomic Read and Clear Bits in CSR (unsigned immediate)
    constant I_CSRRCI   : instr_cf := ( "CSRRCI", RVI , "11100" , "111" , "-------" , "------------" );

    constant R_OP0  : std_logic_vector(4 downto 0) := "01100";  
    constant U_OP0  : std_logic_vector(4 downto 0) := "01101";  -- LUI
    constant U_OP1  : std_logic_vector(4 downto 0) := "00101";  -- AUIPC
    constant J_OP0  : std_logic_vector(4 downto 0) := "11011";  -- JAL
    constant S_OP0  : std_logic_vector(4 downto 0) := "01000";  -- SW,SH,SB,SHU,SBU
    constant B_OP0  : std_logic_vector(4 downto 0) := "11000";  -- BEQ,BNE,BGE,BLT,BGEU,BLTU
    constant I_OP0  : std_logic_vector(4 downto 0) := "00100";  
    constant I_OP1  : std_logic_vector(4 downto 0) := "00000";  -- LW,LH,LB
    constant I_OP2  : std_logic_vector(4 downto 0) := "11001";  -- JALR
    constant CSR_OP : std_logic_vector(4 downto 0) := "11100";

    -- ALU commands
    constant ALU_ADD    : std_logic_vector(3 downto 0) := "0000";
    constant ALU_SUB    : std_logic_vector(3 downto 0) := "0001";
    constant ALU_SRA    : std_logic_vector(3 downto 0) := "0010";
    constant ALU_SRL    : std_logic_vector(3 downto 0) := "0011";
    constant ALU_SLL    : std_logic_vector(3 downto 0) := "0100";
    constant ALU_SLT    : std_logic_vector(3 downto 0) := "0101";
    constant ALU_SLTU   : std_logic_vector(3 downto 0) := "0110";
    constant ALU_OR     : std_logic_vector(3 downto 0) := "0111";
    constant ALU_AND    : std_logic_vector(3 downto 0) := "1000";
    constant ALU_XOR    : std_logic_vector(3 downto 0) := "1001";
    
    -- branch type constants
    constant B_NONE     : std_logic_vector(3 downto 0) := 4X"0";
    constant B_EQ_NEQ   : std_logic_vector(3 downto 0) := 4X"1";
    constant B_GE_LT    : std_logic_vector(3 downto 0) := 4X"2";
    constant B_GEU_LTU  : std_logic_vector(3 downto 0) := 4X"4";
    constant B_UB       : std_logic_vector(3 downto 0) := 4X"8";
    -- srcA select constants
    constant SRCA_IMM   : std_logic_vector(1 downto 0) := "00";
    constant SRCA_RD1   : std_logic_vector(1 downto 0) := "01";
    constant SRCA_PC    : std_logic_vector(1 downto 0) := "10";
    -- srcB select constants
    constant SRCB_IMM   : std_logic_vector(1 downto 0) := "00";
    constant SRCB_RD2   : std_logic_vector(1 downto 0) := "01";
    constant SRCB_12    : std_logic_vector(1 downto 0) := "10";
    -- src shift select constants
    constant SRCS_SHAMT : std_logic_vector(1 downto 0) := "00";
    constant SRCS_RD2   : std_logic_vector(1 downto 0) := "01";
    constant SRCS_12    : std_logic_vector(1 downto 0) := "10";
    -- sign imm select
    constant I_SEL  : std_logic_vector(4 downto 0) := 5X"01";     -- for i type instruction
    constant U_SEL  : std_logic_vector(4 downto 0) := 5X"02";     -- for u type instruction
    constant B_SEL  : std_logic_vector(4 downto 0) := 5X"04";     -- for b type instruction
    constant S_SEL  : std_logic_vector(4 downto 0) := 5X"08";     -- for s type instruction
    constant J_SEL  : std_logic_vector(4 downto 0) := 5X"10";     -- for j type instruction
    -- RF src constants
    constant RF_ALUR    : std_logic := '0';                   -- RF write data is ALU result
    constant RF_DMEM    : std_logic := '1';                   -- RF write data is data memory read data
    -- result src constants
    constant RES_ALU    : std_logic_vector(1 downto 0) := "00";
    constant RES_UB     : std_logic_vector(1 downto 0) := "01";
    constant RES_CSR    : std_logic_vector(1 downto 0) := "10";
    -- CSR command constants
    constant CSR_NONE   : std_logic_vector := "00"; -- none edit csr value
    constant CSR_WR     : std_logic_vector := "01"; -- csr write data
    constant CSR_SET    : std_logic_vector := "10"; -- csr set with mask
    constant CSR_CLR    : std_logic_vector := "11"; -- csr clear with mask

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
