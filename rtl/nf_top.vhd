--
-- File            :   nf_top.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.04.19
-- Language        :   VHDL
-- Description     :   This is top unit
-- Copyright(c)    :   2019 Vlasov D.V.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity nf_top is
    port 
    (
        -- clock and reset
        clk         : in    std_logic;                      -- clock
        resetn      : in    std_logic;                      -- reset
        div         : in    std_logic_vector(25 downto 0);  -- clock divide input
        -- for debug
        reg_addr    : in    std_logic_vector(4  downto 0);  -- scan register address
        reg_data    : out   std_logic_vector(31 downto 0)   -- scan register data
    );
end nf_top;

architecture rtl of nf_top is

    signal instr_addr   :   std_logic_vector(31 downto 0);  -- instruction address
    signal instr_addr_i :   std_logic_vector(31 downto 0);  -- instruction address internal
    signal instr        :   std_logic_vector(31 downto 0);  -- instruction data
    signal cpu_en       :   std_logic;                      -- cpu enable ( "dividing" clock )
    -- component definition
    -- nf_cpu
    component nf_cpu
        port 
        (
            -- clock and reset
            clk         : in    std_logic;                      -- clock
            resetn      : in    std_logic;                      -- reset
            cpu_en      : in    std_logic;                      -- cpu enable signal
            -- instruction memory
            instr_addr  : out   std_logic_vector(31 downto 0);  -- instruction address
            instr       : in    std_logic_vector(31 downto 0);  -- instruction data
            -- for debug
            reg_addr    : in    std_logic_vector(4  downto 0);  -- register address
            reg_data    : out   std_logic_vector(31 downto 0)   -- register data
        );
    end component;
    -- nf_instr_mem
    component nf_instr_mem
        generic
        (
            depth   : integer := 64                         -- depth of memory array
        );
        port 
        (
            addr    : in    std_logic_vector(31 downto 0);  -- instruction address
            instr   : out   std_logic_vector(31 downto 0)   -- instruction data
        );
    end component;
    -- nf_clock_div
    component nf_clock_div
        port 
        (
            -- clock and reset
            clk     : in    std_logic;                      -- clock
            resetn  : in    std_logic;                      -- reset
            -- strobbing
            div     : in    std_logic_vector(25 downto 0);  -- div_number
            en      : out   std_logic                       -- enable strobe
        );
    end component;

begin

    instr_addr_i <= "00" & instr_addr(31 downto 2);

    -- creating one register file
    nf_cpu_0: nf_cpu 
    port map    (
                    clk         => clk,             -- clock
                    resetn      => resetn,          -- reset
                    instr_addr  => instr_addr,      -- cpu enable signal
                    instr       => instr,           -- instruction address
                    cpu_en      => cpu_en,          -- instruction data
                    reg_addr    => reg_addr,        -- register address
                    reg_data    => reg_data         -- register data
                );
    -- creating one instruction memory 
    nf_instr_mem_0: nf_instr_mem 
    generic map (
                    depth       => 64               -- depth of memory array
                ) 
    port map    (
                    addr        => instr_addr_i,    -- instruction address
                    instr       => instr            -- instruction data
                );
    -- creating one strob generating unit for "dividing" clock
    nf_clock_div_0: nf_clock_div 
    port map    (
                    clk         => clk,             -- clock
                    resetn      => resetn,          -- reset
                    div         => div,             -- div_number
                    en          => cpu_en           -- enable strobe
                );

end rtl; -- nf_top
