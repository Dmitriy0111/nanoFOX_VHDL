--
-- File            :   nf_control_unit.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.04.19
-- Language        :   VHDL
-- Description     :   This is controll unit
-- Copyright(c)    :   2019 Vlasov D.V.
--

library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.nf_cpu_def.all;

entity nf_control_unit is
    port 
    (
        instr_type  : in    std_logic_vector(1 downto 0);   -- instruction type
        opcode      : in    std_logic_vector(4 downto 0);   -- operation code field in instruction code
        funct3      : in    std_logic_vector(2 downto 0);   -- funct 3 field in instruction code
        funct7      : in    std_logic_vector(6 downto 0);   -- funct 7 field in instruction code
        imm_src     : out   std_logic_vector(4 downto 0);   -- for selecting immediate data
        srcBsel     : out   std_logic;                      -- for selecting srcB ALU
        res_sel     : out   std_logic;                      -- for selecting result
        branch_type : out   std_logic_vector(3 downto 0);   -- for executing branch instructions
        branch_hf   : out   std_logic;                      -- branch help field
        branch_src  : out   std_logic;                      -- for selecting branch source (JALR)
        we_rf       : out   std_logic;                      -- write enable signal for register file    
        we_dm       : out   std_logic;                      -- write enable signal for data memory and other's
        rf_src      : out   std_logic;                      -- write data select for register file
        size_dm     : out   std_logic_vector(1 downto 0);   -- size for load/store instructions
        ALU_Code    : out   std_logic_vector(3 downto 0)    -- output code for ALU unit
    );
end nf_control_unit;

architecture rtl of nf_control_unit is
    signal instr_cf_0 : instr_cf;

    function ret_code( instr_cf_in : instr_cf )
    return std_logic_vector is
        variable ret_v : std_logic_vector(8 downto 0);
    begin
        ret_v(8 downto 4) := instr_cf_in.OP;
        ret_v(3 downto 1) := instr_cf_in.F3;
        ret_v(0) := instr_cf_in.F7(5);
        return ret_v;
    end function;
begin

    instr_cf_0.IT <= instr_type;
    instr_cf_0.OP <= opcode;
    instr_cf_0.F3 <= funct3;
    instr_cf_0.F7 <= funct7;

    branch_hf  <= not instr_cf_0.F3(0);
    branch_src <= '1' when ( instr_cf_0.OP = I_JALR.OP ) else '0';
    we_dm      <= '1' when ( instr_cf_0.OP = I_SW.OP   ) else '0';
    size_dm    <= instr_cf_0.F3(1 downto 0);

    -- finding values of control wires
    control_process : process(all)
    begin
        we_rf       <= '0';
        rf_src      <= RF_ALUR;
        ALU_Code    <= ALU_ADD;
        srcBsel     <= SRCB_IMM(0);
        res_sel     <= RES_ALU;
        imm_src     <= I_SEL;
        branch_type <= B_NONE;
        case( instr_cf_0.IT ) is
            when RVI    =>
                case? ( ret_code(instr_cf_0) ) is
                    -- R - type command's
                    when ret_code( I_ADD  ) => we_rf <= '1' ; ALU_Code <= ALU_ADD ; srcBsel <= SRCB_RD2(0) ; res_sel <= RES_ALU ;
                    when ret_code( I_AND  ) => we_rf <= '1' ; ALU_Code <= ALU_AND ; srcBsel <= SRCB_RD2(0) ; res_sel <= RES_ALU ;
                    when ret_code( I_SUB  ) => we_rf <= '1' ; ALU_Code <= ALU_SUB ; srcBsel <= SRCB_RD2(0) ; res_sel <= RES_ALU ;
                    when ret_code( I_SLL  ) => we_rf <= '1' ; ALU_Code <= ALU_SLL ; srcBsel <= SRCB_RD2(0) ; res_sel <= RES_ALU ;
                    when ret_code( I_OR   ) => we_rf <= '1' ; ALU_Code <= ALU_OR  ; srcBsel <= SRCB_RD2(0) ; res_sel <= RES_ALU ;
                    -- I - type command's
                    when ret_code( I_ADDI ) => we_rf <= '1' ; ALU_Code <= ALU_ADD ; srcBsel <= SRCB_IMM(0) ; res_sel <= RES_ALU ; imm_src <= I_SEL ;
                    when ret_code( I_ORI  ) => we_rf <= '1' ; ALU_Code <= ALU_OR  ; srcBsel <= SRCB_IMM(0) ; res_sel <= RES_ALU ; imm_src <= I_SEL ;
                    when ret_code( I_SLLI ) => we_rf <= '1' ; ALU_Code <= ALU_SLL ; srcBsel <= SRCB_IMM(0) ; res_sel <= RES_ALU ; imm_src <= I_SEL ;
                    when ret_code( I_LW   ) => we_rf <= '1' ; ALU_Code <= ALU_ADD ; srcBsel <= SRCB_IMM(0) ; res_sel <= RES_ALU ; imm_src <= I_SEL ;                          rf_src <= RF_DMEM;
                    when ret_code( I_JALR ) => we_rf <= '1' ; ALU_Code <= ALU_ADD ; srcBsel <= SRCB_IMM(0) ; res_sel <= RES_UB  ; imm_src <= I_SEL ; branch_type <= B_UB;
                    -- U - type command's
                    when ret_code( I_LUI  ) => we_rf <= '1' ; ALU_Code <= ALU_LUI ; srcBsel <= SRCB_IMM(0) ; res_sel <= RES_ALU ; imm_src <= U_SEL ;
                    -- B - type command's
                    when ret_code( I_BEQ  ) => we_rf <= '0' ; ALU_Code <= ALU_ADD ; srcBsel <= SRCB_RD2(0) ; res_sel <= RES_ALU ; imm_src <= B_SEL ; branch_type <= B_EQ_NEQ;
                    when ret_code( I_BNE  ) => we_rf <= '0' ; ALU_Code <= ALU_ADD ; srcBsel <= SRCB_RD2(0) ; res_sel <= RES_ALU ; imm_src <= B_SEL ; branch_type <= B_EQ_NEQ;
                    -- S - type command's
                    when ret_code( I_SW   ) => we_rf <= '0' ; ALU_Code <= ALU_ADD ; srcBsel <= SRCB_IMM(0) ; res_sel <= RES_ALU ; imm_src <= S_SEL ;                                              
                    -- J - type command's
                    when ret_code( I_JAL  ) => we_rf <= '1' ; ALU_Code <= ALU_ADD ; srcBsel <= SRCB_IMM(0) ; res_sel <= RES_UB  ; imm_src <= J_SEL ; branch_type <= B_UB;
                    -- in the future
                    when others => 
                end case ?;
            when others => 
        end case;
    end process;

end rtl; -- nf_control_unit
