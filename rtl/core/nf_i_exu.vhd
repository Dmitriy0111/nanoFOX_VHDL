--
-- File            :   nf_i_exu.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.04.23
-- Language        :   VHDL
-- Description     :   This is instruction execution unit
-- Copyright(c)    :   2019 Vlasov D.V.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
library nf;
use nf.nf_cpu_def.all;
use nf.nf_components.all;

entity nf_i_exu is
    port
    (
        rd1         : in    std_logic_vector(31 downto 0);  -- read data from reg file (port1)
        rd2         : in    std_logic_vector(31 downto 0);  -- read data from reg file (port2)
        ext_data    : in    std_logic_vector(31 downto 0);  -- sign extended immediate data
        pc_v        : in    std_logic_vector(31 downto 0);  -- program-counter value
        srcA_sel    : in    std_logic_vector(1  downto 0);  -- source A enable signal for ALU
        srcB_sel    : in    std_logic_vector(1  downto 0);  -- source B enable signal for ALU
        shift_sel   : in    std_logic_vector(1  downto 0);  -- for selecting shift input
        shamt       : in    std_logic_vector(4  downto 0);  -- for shift operation
        ALU_Code    : in    std_logic_vector(3  downto 0);  -- ALU code from control unit
        result      : out   std_logic_vector(31 downto 0)   -- result of ALU operation
    );
end nf_i_exu;

architecture rtl of nf_i_exu is
    -- wires for ALU inputs
    signal srcA     : std_logic_vector(31 downto 0);    -- source A ALU
    signal srcB     : std_logic_vector(31 downto 0);    -- source B ALU
    signal shift    : std_logic_vector(4  downto 0);    -- for shamt ALU input
begin

    -- finding srcA value
    srcA_proc : process( all )
    begin
        srcA <= rd1;
        case( srcA_sel ) is
            when SRCA_IMM   => srcA <= ext_data;
            when SRCA_RD1   => srcA <= rd1;
            when SRCA_PC    => srcA <= pc_v;
            when others     =>
        end case;
    end process;
    -- finding srcB value
    srcB_proc : process( all )
    begin
        srcB <= rd2;
        case( srcB_sel ) is
            when SRCB_RD2   => srcB <= rd2;
            when SRCB_IMM   => srcB <= ext_data;
            when SRCB_12    => srcB <= std_logic_vector( shift_left ( unsigned( ext_data ) , 12) );
            when others     =>
        end case;
    end process;
    -- finding shift value
    shift_proc : process( all )
    begin
        shift <= rd2(4 downto 0);
        case( shift_sel ) is
            when SRCS_SHAMT => shift <= shamt;
            when SRCS_RD2   => shift <= rd2(4 downto 0);
            when SRCS_12    => shift <= 5D"12";
            when others     =>
        end case;
    end process;
    -- creating ALU unit
    nf_alu_0 : nf_alu
    port map
    (
        srcA        => srcA,        -- source A for ALU unit
        srcB        => srcB,        -- source B for ALU unit
        shift       => shift,       -- for shift operation
        ALU_Code    => ALU_Code,    -- ALU code from control unit
        result      => result       -- result of ALU operation
    );

end rtl; -- nf_i_exu
