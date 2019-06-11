--
-- File            :   nf_csr_pkg.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.06.11
-- Language        :   VHDL
-- Description     :   This is file for CSR
-- Copyright(c)    :   2019 Vlasov D.V.
--

library ieee;
use ieee.std_logic_1164.all;

package nf_csr_pkg is

    constant MISA_A     : std_logic_vector(11 downto 0) := 12X"301";    
    constant MTVEC_A    : std_logic_vector(11 downto 0) := 12X"305";    -- Machine trap-handler base address
    constant MSCRATCH_A : std_logic_vector(11 downto 0) := 12X"340";    -- Scratch register for machine trap handlers
    constant MEPC_A     : std_logic_vector(11 downto 0) := 12X"341";    -- Machine exception program counter
    constant MCAUSE_A   : std_logic_vector(11 downto 0) := 12X"342";    -- Machine trap cause
    constant MTVAL_A    : std_logic_vector(11 downto 0) := 12X"343";    -- Machine bad address or instruction
    constant MCYCLE_A   : std_logic_vector(11 downto 0) := 12X"B00";    -- Machine cycle counter
    -- MXL_WIRI_Extensions
    constant MISA_V     : std_logic_vector(31 downto 0) := "01000000000000000000000100000000";    -- RV32I

end package nf_csr_pkg;

package body nf_csr_pkg is

end package body nf_csr_pkg;
