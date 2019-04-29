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
use ieee.std_logic_unsigned.all;
library nf;
use nf.nf_cpu_def.all;
use nf.nf_help_pkg.all;

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
begin

    instr_cf_0.IT <= instr_type;
    instr_cf_0.OP <= opcode;
    instr_cf_0.F3 <= funct3;
    instr_cf_0.F7 <= funct7;

    branch_hf  <= not instr_cf_0.F3(0);
    branch_src <= bool2sl( instr_cf_0.OP = I_OP2 );
    we_dm      <= bool2sl( instr_cf_0.OP = S_OP0 );
    size_dm    <= instr_cf_0.F3(1 downto 0);
    -- immediate source selecting
    imm_proc : process(all)
    begin
        imm_src <= I_SEL;
        case( instr_cf_0.IT ) is
            when RVI    =>
                case( instr_cf_0.OP ) is
                    when J_OP0                  => imm_src <= J_SEL;
                    when S_OP0                  => imm_src <= S_SEL;
                    when B_OP0                  => imm_src <= B_SEL;
                    when U_OP0 | U_OP1          => imm_src <= U_SEL;
                    when I_OP0 | I_OP1 | I_OP2  => imm_src <= I_SEL;
                    when others                 =>
                end case;
            when others =>
        end case;
    end process;
    -- register file source selecting
    rf_src_proc : process(all)
    begin
        rf_src <= RF_ALUR;
        case( instr_cf_0.IT ) is
            when RVI    =>
                case( instr_cf_0.OP ) is
                    when I_OP1                  => rf_src <= RF_DMEM;
                    when others                 =>
                end case;
            when others =>
        end case;
    end process;
    -- write enable register file
    we_rf_proc : process(all)
    begin
        we_rf <= '0';
        case( instr_cf_0.IT ) is
            when RVI    =>
                case( instr_cf_0.OP ) is
                    when R_OP0                  => we_rf <= '1';
                    when J_OP0                  => we_rf <= '1';
                    when S_OP0                  => we_rf <= '0';
                    when B_OP0                  => we_rf <= '0';
                    when U_OP0 | U_OP1          => we_rf <= '1';
                    when I_OP0 | I_OP1 | I_OP2  => we_rf <= '1';
                    when others                 =>
                end case;
            when others =>
        end case;
    end process;
    -- source B for ALU selecting
    srcBsel_proc : process(all)
    begin
        srcBsel <= SRCB_IMM(0);
        case( instr_cf_0.IT ) is
            when RVI    =>
                case( instr_cf_0.OP ) is
                    when R_OP0 | B_OP0  => srcBsel <= SRCB_RD2(0) ;
                    when others         =>
                end case;
            when others =>
        end case;
    end process;
    -- branch type finding
    branch_type_proc : process(all)
    begin
        branch_type <= B_NONE;
        case( instr_cf_0.IT ) is
            when RVI    =>
                case( instr_cf_0.OP ) is
                    when B_OP0          => 
                        case( instr_cf_0.F3(2 downto 1) ) is
                            when "00"   => branch_type <= B_EQ_NEQ;
                            when others => 
                        end case;
                    when J_OP0 | I_OP2  => branch_type <= B_UB;
                    when others                 =>
                end case;
            when others =>
        end case;
    end process;
    -- result select
    res_sel_proc : process(all)
    begin
        res_sel <= RES_ALU;
        case( instr_cf_0.IT ) is
            when RVI    =>
                case( instr_cf_0.OP ) is
                    when J_OP0 | I_OP2  => res_sel <= RES_UB;   -- JAL or JALR
                    when others         =>
                end case;
            when others =>
        end case;
    end process;
    -- setting code for ALU    
    ALU_Code_proc : process(all)
    begin
        ALU_Code <= ALU_ADD;
        case( instr_cf_0.IT ) is
            when RVI    =>
                case( instr_cf_0.OP ) is
                    when U_OP0          => ALU_Code <= ALU_LUI;
                    when R_OP0 | I_OP0  => 
                        case( instr_cf_0.F3 )is
                            when    I_ADD   =>  ALU_Code <= ALU_ADD;
                            when    I_AND   =>  ALU_Code <= ALU_AND;
                            when    I_OR    =>  ALU_Code <= ALU_OR;
                            when    I_SLL   =>  ALU_Code <= ALU_SLL;
                            when    others  =>
                        end case;    
                    when others         =>
                end case;
            when others =>
        end case;
    end process;

end rtl; -- nf_control_unit
