--
-- File            :   nf_alu.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.04.19
-- Language        :   VHDL
-- Description     :   This is ALU unit
-- Copyright(c)    :   2019 Vlasov D.V.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

library nf;
use nf.nf_cpu_def.all;
use nf.nf_help_pkg.all;

entity nf_alu is
    port
    (
        srcA        : in    std_logic_vector(31 downto 0);  -- source A for ALU unit
        srcB        : in    std_logic_vector(31 downto 0);  -- source B for ALU unit
        shift       : in    std_logic_vector(4  downto 0);  -- for shift operation
        ALU_Code    : in    std_logic_vector(3  downto 0);  -- ALU code from control unit
        result      : out   std_logic_vector(31 downto 0)   -- result of ALU operation
    );
end nf_alu;

architecture rtl of nf_alu is
    signal carry        : std_logic;                        -- carry flag
    signal sign         : std_logic;                        -- sign flag
    signal sof          : std_logic;                        -- substruction overflow flag

    signal add_sub      : std_logic_vector(32 downto 0);    -- addition or substruction result
    signal shift_res    : std_logic_vector(31 downto 0);    -- shift result
    signal logic_res    : std_logic_vector(31 downto 0);    -- result for logic operation
begin

    carry <= add_sub(32);
    sign  <= add_sub(31);
    sof   <= ( not srcA(31) and srcB(31) and add_sub(31) ) or ( srcA(31) and not srcB(31) and not add_sub(31) );

    -- finding ALU shift result
    shift_proc : process( all )
    begin
        shift_res <= std_logic_vector( shift_left ( unsigned( srcA ) , to_integer( unsigned( shift ) ) ) );
        case( ALU_Code ) is
            when ALU_SLL    => shift_res <= std_logic_vector( shift_left ( unsigned( srcA ) , to_integer( unsigned( shift ) ) ) );
            when ALU_SRL    => shift_res <= std_logic_vector( shift_right( unsigned( srcA ) , to_integer( unsigned( shift ) ) ) );
            when ALU_SRA    => shift_res <= std_logic_vector( shift_left ( unsigned( repbit(srcA(31),32) ) , to_integer( unsigned( 31 - shift ) ) ) ) or
                                            std_logic_vector( shift_right( unsigned( srcA ) , to_integer( unsigned( shift ) ) ) );
            when others     =>
        end case;
    end process;

    -- finding ALU logic result
    logic_proc : process( all )
    begin
        logic_res <= srcA or srcB;
        case( ALU_Code ) is
            when ALU_OR     => logic_res <= srcA or srcB;
            when ALU_XOR    => logic_res <= srcA xor srcB;
            when ALU_AND    => logic_res <= srcA and srcB;
            when others     =>
        end case;
    end process;

    -- finding ALU addition or substruction result
    add_sub_proc : process( all )
    begin
        add_sub <= ( '0' & srcA ) + ( '0' & srcB );
        case( ALU_Code ) is
            when ALU_ADD    => add_sub <= ( '0' & srcA ) + ( '0' & srcB );
            when ALU_SLT |
                ALU_SLTU |
                ALU_SUB     => add_sub <= ( '0' & srcA ) - ( '0' & srcB );
            when others     =>
        end case;
    end process;

    -- finding result of ALU operation
    ALU_proc : process( all )
    begin
        result <= add_sub(31 downto 0);
        case( ALU_Code ) is
            when    ALU_ADD |
                    ALU_SUB     => result <= add_sub(31 downto 0);
            when    ALU_SLL |
                    ALU_SRL |
                    ALU_SRA     => result <= shift_res;
            when    ALU_OR  |
                    ALU_XOR |
                    ALU_AND     => result <= logic_res;
            when    ALU_SLT     => result <= 31X"00000000" & ( sign xor sof ); 
            when    ALU_SLTU    => result <= 31X"00000000" & carry;          
            when    others      =>
        end case;
    end process;

end rtl; -- nf_alu
