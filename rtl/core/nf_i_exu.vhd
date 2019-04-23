--
-- File            :   nf_i_exu.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.04.23
-- Language        :   VHDL
-- Description     :   This is instruction execution unit
-- Copyright(c)    :   2019 Vlasov D.V.
--

library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.nf_cpu_def.all;

entity nf_i_exu is
    port 
    (
        rd1         : in    std_logic_vector(31 downto 0);  -- read data from reg file (port1)
        rd2         : in    std_logic_vector(31 downto 0);  -- read data from reg file (port2)
        ext_data    : in    std_logic_vector(31 downto 0);  -- sign extended immediate data
        srcB_sel    : in    std_logic;                      -- source enable signal for ALU
        shamt       : in    std_logic_vector(4  downto 0);  -- for shift operation
        ALU_Code    : in    std_logic_vector(3  downto 0);  -- ALU code from control unit
        result      : out   std_logic_vector(31 downto 0)   -- result of ALU operation
    );
end nf_i_exu;

architecture rtl of nf_i_exu is
    -- wires for ALU inputs
    signal srcA : std_logic_vector(31 downto 0);    -- source A ALU
    signal srcB : std_logic_vector(31 downto 0);    -- source B ALU
    -- nf_alu
    component nf_alu
        port 
        (
            srcA        : in    std_logic_vector(31 downto 0);  -- source A for ALU unit
            srcB        : in    std_logic_vector(31 downto 0);  -- source B for ALU unit
            shamt       : in    std_logic_vector(4  downto 0);  -- for shift operation
            ALU_Code    : in    std_logic_vector(3  downto 0);  -- ALU code from control unit
            result      : out   std_logic_vector(31 downto 0)   -- result of ALU operation
        );
    end component;
begin

    -- assign's ALU signals
    srcA <= rd1;
    srcB <= rd2 when ( srcB_sel = SRCB_RD2(0) ) else ext_data;
    -- creating ALU unit
    nf_alu_0 : nf_alu
    port map
    (
        srcA        => srcA,        -- source A for ALU unit
        srcB        => srcB,        -- source B for ALU unit
        shamt       => shamt,       -- for shift operation
        ALU_Code    => ALU_Code,    -- ALU code from control unit
        result      => result       -- result of ALU operation
    );

end rtl; -- nf_i_exu
