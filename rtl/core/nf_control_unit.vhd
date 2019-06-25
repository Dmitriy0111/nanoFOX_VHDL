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
        instr_type  : in   std_logic_vector(1  downto 0);   -- instruction type
        opcode      : in   std_logic_vector(4  downto 0);   -- operation code field in instruction code
        funct3      : in   std_logic_vector(2  downto 0);   -- funct 3 field in instruction code
        funct7      : in   std_logic_vector(6  downto 0);   -- funct 7 field in instruction code
        funct12     : in   std_logic_vector(11 downto 0);   -- funct 12 field in instruction code
        wa3         : in   std_logic_vector(4  downto 0);   -- write address field
        imm_src     : out  std_logic_vector(4  downto 0);   -- for enable immediate data
        srcB_sel    : out  std_logic_vector(1  downto 0);   -- for selecting srcB ALU
        srcA_sel    : out  std_logic_vector(1  downto 0);   -- for selecting srcA ALU
        shift_sel   : out  std_logic_vector(1  downto 0);   -- for selecting shift input
        res_sel     : out  std_logic;                       -- for selecting result
        branch_type : out  std_logic_vector(3  downto 0);   -- for executing branch instructions
        branch_hf   : out  std_logic;                       -- branch help field
        branch_src  : out  std_logic;                       -- for selecting branch source (JALR)
        we_rf       : out  std_logic;                       -- write enable signal for register file
        we_dm       : out  std_logic;                       -- write enable signal for data memory and others
        rf_src      : out  std_logic;                       -- write data select for register file
        size_dm     : out  std_logic_vector(1  downto 0);   -- size for load/store instructions
        sign_dm     : out  std_logic;                       -- sign extended data memory for load instructions
        csr_cmd     : out  std_logic_vector(1  downto 0);   -- csr command
        csr_rreq    : out  std_logic;                       -- read request to csr
        csr_wreq    : out  std_logic;                       -- write request to csr
        csr_sel     : out  std_logic;                       -- csr select ( zimm or rd1 )
        m_ret       : out  std_logic;                       -- m return
        ALU_Code    : out  std_logic_vector(3  downto 0)    -- output code for ALU unit
    );
end nf_control_unit;

architecture rtl of nf_control_unit is
    signal instr_cf_0 : instr_cf;
begin

    instr_cf_0.IT  <= instr_type;
    instr_cf_0.OP  <= opcode;
    instr_cf_0.F3  <= funct3;
    instr_cf_0.F7  <= funct7;
    instr_cf_0.F12 <= funct12;

    branch_hf  <= not instr_cf_0.F3(0);
    branch_src <= '1' when ( instr_cf_0.OP = I_JALR.OP ) else '0';
    we_dm      <= bool2sl( instr_cf_0.OP = S_OP0 );
    size_dm    <= instr_cf_0.F3(1 downto 0);
    sign_dm    <= not instr_cf_0.F3(2);

    csr_rreq <= bool2sl( instr_cf_0.OP = CSR_OP ) and bool2sl( instr_cf_0.F3 /= 0 ) and bool2sl( wa3 /= 0 );
    csr_wreq <= bool2sl( instr_cf_0.OP = CSR_OP ) and bool2sl( instr_cf_0.F3 /= 0 );
    csr_sel  <= bool2sl( instr_cf_0.F3(2) = '1' );

    m_ret <= bool2sl( instr_cf_0.OP = CSR_OP ) and bool2sl( not ( instr_cf_0.F3 ) /= 0 ) and bool2sl( instr_cf_0.F12 = I_MRET.F12 );

    -- csr command select
    csr_cmd_sel : process( all )
    begin
        csr_cmd <= CSR_NONE;
        if( instr_cf_0.IT = RVI ) then
            case( instr_cf_0.OP ) is
                when CSR_OP => csr_cmd <= sel_slv( ( instr_cf_0.F3 /= 0 ) , instr_cf_0.F3(1 downto 0) , CSR_NONE );
                when others =>
            end case;
        end if;
    end process;
    -- shift input selecting
    shift_sel_proc : process( all )
    begin
        shift_sel <= SRCS_RD2;
        if( instr_cf_0.IT = RVI ) then
            case( instr_cf_0.OP ) is 
                when R_OP0  => shift_sel <= SRCS_RD2;
                when I_OP0  => shift_sel <= SRCS_SHAMT;
                when U_OP0  => shift_sel <= SRCS_12;
                when others =>
            end case;
        end if;
    end process;
    -- immediate source selecting
    imm_proc : process( all )
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
                    when I_OP1  => rf_src <= RF_DMEM;
                    when others =>
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
                    when CSR_OP                 => we_rf <= bool2sl( wa3 /= 0 );
                    when others                 =>
                end case;
            when others =>
        end case;
    end process;
    -- source A for ALU selecting
    srcA_sel_proc : process( all )
    begin
        srcA_sel <= SRCA_RD1;
        case( instr_cf_0.IT ) is
            when RVI    =>
                case( instr_cf_0.OP ) is
                    when R_OP0  => srcA_sel <= SRCA_RD1;
                    when U_OP0  => srcA_sel <= SRCA_IMM;
                    when U_OP1  => srcA_sel <= SRCA_PC;
                    when others =>
                end case;
            when others =>
        end case;
    end process;
    -- source B for ALU selecting
    srcB_sel_proc : process(all)
    begin
        srcB_sel <= SRCB_IMM;
        case( instr_cf_0.IT ) is
            when RVI    =>
                case( instr_cf_0.OP ) is
                    when U_OP1          => srcB_sel <= SRCB_12;
                    when R_OP0 | B_OP0  => srcB_sel <= SRCB_RD2;
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
                            when "10"   => branch_type <= B_GE_LT;
                            when "11"   => branch_type <= B_GEU_LTU;
                            when others => 
                        end case;
                    when J_OP0 | I_OP2  => branch_type <= B_UB;
                    when others         =>
                end case;
            when others =>
        end case;
    end process;
    -- result select
    res_sel_proc : process(all)
    begin
        res_sel <= RES_ALU(0);
        case( instr_cf_0.IT ) is
            when RVI    =>
                case( instr_cf_0.OP ) is
                    when J_OP0 | I_OP2  => res_sel <= RES_UB(0);   -- JAL or JALR
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
                    when U_OP0          => ALU_Code <= ALU_SLL;
                    when R_OP0 | I_OP0  => 
                        case( instr_cf_0.F3 )is
                            when    I_ADD.F3    => ALU_Code <= sel_slv( ( ( instr_cf_0.F7(5) = '1' ) and (instr_cf_0.OP = R_OP0) ) , ALU_SUB , ALU_ADD );
                            when    I_AND.F3    => ALU_Code <= ALU_AND;
                            when    I_OR.F3     => ALU_Code <= ALU_OR;
                            when    I_SLL.F3    => ALU_Code <= ALU_SLL;
                            when    I_SRL.F3    => ALU_Code <= sel_slv( ( instr_cf_0.F7(5) = '1' ) , ALU_SRA , ALU_SRL );
                            when    I_XOR.F3    => ALU_Code <= ALU_XOR;
                            when    I_SLT.F3    => ALU_Code <= ALU_SLT;
                            when    I_SLTU.F3   => ALU_Code <= ALU_SLTU;
                            when    others  =>
                        end case;    
                    when others         =>
                end case;
            when others =>
        end case;
    end process;

end rtl; -- nf_control_unit
