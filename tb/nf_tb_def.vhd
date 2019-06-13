--
-- File            :   nf_tb_def.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.05.06
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
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

use std.textio.all;

library nf;
use nf.nf_cpu_def.all;
use nf.nf_mem_pkg.all;

package nf_tb_def is
    -- enable debug instruction messages
    constant debug_lev0     : boolean   := false;
    -- enable term logging
    constant log_term       : boolean   := false;
    -- enable txt logging
    constant log_txt        : boolean   := true;
    -- enable html logging
    constant log_html       : boolean   := false;
    -- enable logging
    constant log_en         : boolean   := true;

    type    i_list is array(natural range <>) of instr_cf;

    constant I_C_LIST : i_list(0 to 38) := 
                                            (
                                                I_LUI,
                                                I_AUIPC,
                                                I_JAL,
                                                I_JALR,
                                                I_BEQ,
                                                I_BNE,
                                                I_BLT,
                                                I_BGE,
                                                I_BLTU,
                                                I_BGEU,
                                                I_LB,
                                                I_LH,
                                                I_LW,
                                                I_LBU,
                                                I_LHU,
                                                I_SB,
                                                I_SH,
                                                I_SW,
                                                I_ADDI,
                                                I_SLTI,
                                                I_SLTIU,
                                                I_XORI,
                                                I_ORI,
                                                I_ANDI,
                                                I_SLLI,
                                                I_SRLI,
                                                I_SRAI,
                                                I_ADD,
                                                I_SUB,
                                                I_SLL,
                                                I_SLT,
                                                I_SLTU,
                                                I_XOR,
                                                I_SRL,
                                                I_SRA,
                                                I_OR,
                                                I_AND,
                                                I_F,
                                                I_UNK
                                            );

    type reg_l  is array(natural range <>) of string(5 downto 1);
    constant reg_list : reg_l(0 to 31) := (
                                            "zero ",
                                            "ra   ",
                                            "sp   ",
                                            "gp   ",
                                            "tp   ",
                                            "t0   ",
                                            "t1   ",
                                            "t2   ",
                                            "s0/fp",
                                            "s1   ",
                                            "a0   ",
                                            "a1   ",
                                            "a2   ",
                                            "a3   ",
                                            "a4   ",
                                            "a5   ",
                                            "a6   ",
                                            "a7   ",
                                            "s2   ",
                                            "s3   ",
                                            "s4   ",
                                            "s5   ",
                                            "s6   ",
                                            "s7   ",
                                            "s8   ",
                                            "s9   ",
                                            "s10  ",
                                            "s11  ",
                                            "t3   ",
                                            "t4   ",
                                            "t5   ",
                                            "t6   "
                                        );

    function pars_pipe_stage(pipe_slv : std_logic_vector ; param_str : string := "lv_1") return string;

    function ret_i_code(instr_cf_in : instr_cf) return std_logic_vector;

    function update_pipe_str(str_in : string ; str_len : integer) return string;

    function write_txt_table(reg_file : mem_t) return string;

end package nf_tb_def;

package body nf_tb_def is

    function ret_i_code( instr_cf_in : instr_cf )
    return std_logic_vector is
        variable ret_v : std_logic_vector(16 downto 0);
    begin
        ret_v := instr_cf_in.F7 & instr_cf_in.F3 & instr_cf_in.OP & instr_cf_in.IT;
        return ret_v;
    end function;

    function pars_pipe_stage(pipe_slv : std_logic_vector ; param_str : string := "lv_1") return string is
        -- destination and sources registers
        variable ra1        : std_logic_vector(4  downto 0) := pipe_slv(19 downto 15);
        variable ra2        : std_logic_vector(4  downto 0) := pipe_slv(24 downto 20);
        variable wa3        : std_logic_vector(4  downto 0) := pipe_slv(11 downto  7);
        -- immediate data
        variable imm_data_u : std_logic_vector(19 downto 0) := pipe_slv(31 downto 12);
        variable imm_data_i : std_logic_vector(11 downto 0) := pipe_slv(31 downto 20);
        variable imm_data_b : std_logic_vector(11 downto 0) := pipe_slv(31) & pipe_slv(7) & pipe_slv(30 downto 25) & pipe_slv(11 downto 8);
        variable imm_data_s : std_logic_vector(11 downto 0) := pipe_slv(31 downto 25) & pipe_slv(11 downto 7);
        variable imm_data_j : std_logic_vector(19 downto 0) := pipe_slv(31) & pipe_slv(19 downto 12) & pipe_slv(20) & pipe_slv(30 downto 21);
        -- operation type fields
        variable instr_type : std_logic_vector(1  downto 0) := pipe_slv(1  downto  0);
        variable opcode     : std_logic_vector(4  downto 0) := pipe_slv(6  downto  2);
        variable funct3     : std_logic_vector(2  downto 0) := pipe_slv(14 downto 12);
        variable funct7     : std_logic_vector(6  downto 0) := pipe_slv(31 downto 25);
        --
        variable pipe_str   : string(6 downto 1) := "      ";

        variable exit_loop  : boolean := false;
        variable i          : integer := 0;
    begin
        pars_loop : loop
                if( std_match(ret_i_code(I_C_LIST(i)) , ( funct7 & funct3 & opcode & instr_type ) ) ) then
                    exit_loop := true;
                end if;
                exit pars_loop when exit_loop;
                i := i + 1;
        end loop;
        pipe_str := I_C_LIST(i).I_NAME;
        if( i = I_C_LIST'length - 1 ) then
            return ("ERROR! Unknown instruction = " & to_string(pipe_slv));
        end if;
        if( i = I_C_LIST'length - 2 ) then
            return "Flushed instruction";
        end if;
        if( instr_type = RVI ) then
            if( opcode = U_OP0 ) then
                if(param_str = "lv_1") then
                    return "RVI " & (I_C_LIST(i).I_NAME & " rd  = " & reg_list(to_integer(unsigned(wa3))) & ", Imm = 0x" & to_hstring(imm_data_u));
                elsif(param_str = "lv_0") then
                    return ("U-type  : " & to_string(imm_data_u) & "_" & to_string(wa3) & "_" & to_string(opcode) & "_" & to_string(instr_type) );
                end if;
            end if;
            if( opcode = B_OP0 ) then
                if(param_str = "lv_1") then
                    return "RVI " & (I_C_LIST(i).I_NAME & " rs1 = " & reg_list(to_integer(unsigned(ra1))) & ", rs2 = " & reg_list(to_integer(unsigned(ra2))) & ", Imm = 0x" & to_hstring(imm_data_b));
                elsif(param_str = "lv_0") then
                    return ("B-type  : " & to_string(pipe_slv(31)) & "_" & to_string(pipe_slv(30 downto 25)) & "_" & to_string(ra2) & "_" & to_string(ra1) & "_" & to_string(funct3) & "_" & to_string(pipe_slv(12 downto 8)) & "_" & to_string(pipe_slv(7)) & "_" & to_string(opcode) & "_" & to_string(instr_type) );
                end if;
            end if;
            if( opcode = S_OP0 ) then
                if(param_str = "lv_1") then
                    return "RVI " & (I_C_LIST(i).I_NAME & " rs1 = " & reg_list(to_integer(unsigned(ra1))) & ", rs2 = " & reg_list(to_integer(unsigned(ra2))) & ", Imm = 0x" & to_hstring(imm_data_s));
                elsif(param_str = "lv_0") then
                    return ("S-type  : " & to_string(pipe_slv(31 downto 25)) & "_" & to_string(ra2) & "_" & to_string(ra1) & "_" & to_string(funct3) & "_" & to_string(pipe_slv(11 downto 7)) & "_" & to_string(opcode) & "_" & to_string(instr_type) );
                end if;
            end if;
            if( ( opcode = I_OP0 ) or ( opcode = I_OP1 ) or ( opcode = I_OP2 ) ) then
                if(param_str = "lv_1") then
                    return "RVI " & (I_C_LIST(i).I_NAME & " rd  = " & reg_list(to_integer(unsigned(wa3))) & ", rs1 = " & reg_list(to_integer(unsigned(ra1))) & ", Imm = 0x" & to_hstring(imm_data_i));
                elsif(param_str = "lv_0") then
                    return ("I-type  : " & to_string(imm_data_i) & "_" & to_string(ra1) & "_" & to_string(funct3) & "_" & to_string(wa3) & "_" & to_string(opcode) & "_" & to_string(instr_type) );
                end if;
            end if;
            if( opcode = R_OP0 ) then
                if(param_str = "lv_1") then
                    return "RVI " & (I_C_LIST(i).I_NAME & " rd  = " & reg_list(to_integer(unsigned(wa3))) & ", rs1 = " & reg_list(to_integer(unsigned(ra1))) & ", rs2 = " & reg_list(to_integer(unsigned(ra2))));
                elsif(param_str = "lv_0") then
                    return ("R-type  : " & to_string(funct7) & "_" & to_string(ra2) & "_" & to_string(ra1) & "_" & to_string(funct3) & "_" & to_string(wa3) & "_" & to_string(opcode) & "_" & to_string(instr_type) );
                end if;
            end if;
            if( opcode = J_OP0 ) then
                if(param_str = "lv_1") then
                    return "RVI " & (I_C_LIST(i).I_NAME & " rd  = " & reg_list(to_integer(unsigned(wa3))) & ", Imm = 0x" & to_hstring(imm_data_j));
                elsif(param_str = "lv_0") then
                    return ("J-type  : " & to_string(pipe_slv(31)) & "_" & to_string(pipe_slv(30 downto 21)) & "_" & to_string(pipe_slv(20)) & "_" & to_string(pipe_slv(19 downto 12)) & "_" & to_string(wa3) & "_" & to_string(opcode) & "_" & to_string(instr_type) );
                end if;
            end if;
        end if;
        return ("ERROR! Unknown instruction = " & to_string(pipe_slv));
    end function;

    function update_pipe_str(str_in : string ; str_len : integer) return string is
    begin
        return ( str_in & ( str_len - str_in'length downto 1 => ' ' ) );
    end function;

    function write_txt_table(reg_file : mem_t) return string is
        variable reg_addr : integer := 0;
        variable reg_line : line;
    begin
        reg_loop : loop 
            write(reg_line, reg_list(reg_addr) & " = 0x" & to_hstring( reg_file(reg_addr) ) & " | " );
            reg_addr := reg_addr + 1;
            exit when reg_addr = 32;
            if( reg_addr mod 4 = 0 ) then
                write(reg_line, LF );
            end if;
        end loop;

        return string'(reg_line.all);
    end function; -- write_txt_table

end nf_tb_def;