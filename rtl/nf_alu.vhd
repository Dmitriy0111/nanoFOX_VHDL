--
-- File            :   nf_alu.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.04.19
-- Language        :   VHDL
-- Description     :   This is ALU unit
-- Copyright(c)    :   2019 Vlasov D.V.
--

library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.nf_cpu_def.all;

entity nf_alu is
    port 
    (
        srcA        : in    std_logic_vector(31 downto 0);  -- source A for ALU unit
        srcB        : in    std_logic_vector(31 downto 0);  -- source B for ALU unit
        shamt       : in    std_logic_vector(4  downto 0);  -- for shift operation
        ALU_Code    : in    std_logic_vector(2  downto 0);  -- ALU code from control unit
        result      : out   std_logic_vector(31 downto 0)   -- result of ALU operation
    );
end nf_alu;

architecture rtl of nf_alu is
begin
    -- finding result of ALU operation
    alu_process : process(all)
    begin
        result <= (others => '0');
        case( ALU_Code ) is
            when ALU_LUI    => result <= std_logic_vector( shift_left( unsigned( srcB ) , 12 ) );
            when ALU_ADD    => result <= srcA + srcB;
            when ALU_SUB    => result <= srcA - srcB;
            when ALU_SLL    => result <= std_logic_vector( shift_left( unsigned( srcA ) , to_integer( unsigned( shamt ) ) ) );
            when ALU_OR     => result <= srcA or srcB;
            when others     => result <= srcA + srcB;
        end case;
    end process;

end rtl; -- nf_alu
