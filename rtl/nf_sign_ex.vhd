--
-- File            :   nf_sign_ex.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.04.19
-- Language        :   VHDL
-- Description     :   This is module for sign extending
-- Copyright(c)    :   2019 Vlasov D.V.
--

library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.nf_cpu_def.all;

entity nf_sign_ex is
    port 
    (
        imm_data_i  : in    std_logic_vector(11 downto 0);  -- immediate data in i-type instruction
        imm_data_u  : in    std_logic_vector(19 downto 0);  -- immediate data in u-type instruction
        imm_data_b  : in    std_logic_vector(11 downto 0);  -- immediate data in b-type instruction
        imm_src     : in    std_logic_vector(1  downto 0);  -- selection immediate data input
        imm_ex      : out   std_logic_vector(31 downto 0)   -- extended immediate data
    );
end nf_sign_ex;

architecture rtl of nf_sign_ex is
begin

    alu_process : process(all)
    begin
        imm_ex <= (others => '0');
        case( imm_src ) is
            when I_SEL  => imm_ex <= ( 31 downto 12 => imm_data_i(11) ) & imm_data_i;
            when U_SEL  => imm_ex <= ( 31 downto 20 => '0'            ) & imm_data_u;
            when B_SEL  => imm_ex <= ( 31 downto 12 => imm_data_b(11) ) & imm_data_b;
            when others => imm_ex <= ( 31 downto 12 => imm_data_i(11) ) & imm_data_i;
        end case;
    end process;

end rtl; -- nf_sign_ex
