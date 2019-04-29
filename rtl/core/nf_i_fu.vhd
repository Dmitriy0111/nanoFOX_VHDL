--
-- File            :   nf_i_fu.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.04.29
-- Language        :   VHDL
-- Description     :   This is instruction fetch unit
-- Copyright(c)    :   2019 Vlasov D.V.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
library nf;
use nf.nf_settings.all;

entity nf_i_fu is
    port
    (
        -- clock and reset
        clk         : in   std_logic;                       -- clock
        resetn      : in   std_logic;                       -- reset
        -- program counter inputs   
        pc_branch   : in   std_logic_vector(31 downto 0);   -- program counter branch value from decode stage
        pc_src      : in   std_logic;                       -- next program counter source
        branch_type : in   std_logic_vector(3  downto 0);   -- branch type
        stall_if    : in   std_logic;                       -- stalling instruction fetch stage
        instr_if    : out  std_logic_vector(31 downto 0);   -- instruction fetch
        -- memory inputs/outputs
        addr_i      : out  std_logic_vector(31 downto 0);   -- address instruction memory
        rd_i        : in   std_logic_vector(31 downto 0);   -- read instruction memory
        wd_i        : out  std_logic_vector(31 downto 0);   -- write instruction memory
        we_i        : out  std_logic;                       -- write enable instruction memory signal
        size_i      : out  std_logic_vector(1  downto 0);   -- size for load/store instructions
        req_i       : out  std_logic;                       -- request instruction memory signal
        req_ack_i   : in   std_logic                        -- request acknowledge instruction memory signal
    );
end nf_i_fu;

architecture rtl of nf_i_fu is
    signal flush_id             : std_logic;                        -- for flushing instruction decode stage
    -- instruction fetch stage
    signal sel_if_instr         : std_logic_vector(0  downto 0);    -- selected instruction 
    signal we_if_stalled        : std_logic;                        -- write enable for stall ( fetch stage )
    signal instr_if_stalled     : std_logic_vector(31 downto 0);    -- stalled instruction ( fetch stage )
    signal sel_if_in            : std_logic_vector(0  downto 0);
    signal addr_i_i             : std_logic_vector(31 downto 0);    -- address internal
    -- program counters values
    signal pc_i                 : std_logic_vector(31 downto 0);    -- program counter value
    signal pc_not_branch        : std_logic_vector(31 downto 0);    -- program counter not branch value
    signal branch_type_delayed  : std_logic_vector(3  downto 0);    -- branch type delayed
    -- flush instruction decode 
    signal flush_id_ifu         : std_logic_vector(0  downto 0);    -- flush id stage
    signal flush_id_branch      : std_logic_vector(0  downto 0);    -- flush id stage ( branch operation )
    signal flush_id_delayed     : std_logic_vector(0  downto 0);    -- flush id stage
    signal flush_id_sw_instr    : std_logic_vector(0  downto 0);    -- flush id stage ( store data instruction )
    -- nf_register
    component nf_register
        generic
        (
            width   : integer   := 1
        );
        port
        (
            clk     : in    std_logic;                          -- clk
            resetn  : in    std_logic;                          -- resetn
            datai   : in    std_logic_vector(width-1 downto 0); -- input data
            datao   : out   std_logic_vector(width-1 downto 0)  -- output data
        );
    end component;
    -- nf_register_we
    component nf_register_we
        generic
        (
            width   : integer   := 1
        );
        port
        (
            clk     : in    std_logic;                          -- clk
            resetn  : in    std_logic;                          -- resetn
            we      : in    std_logic;                          -- write enable
            datai   : in    std_logic_vector(width-1 downto 0); -- input data
            datao   : out   std_logic_vector(width-1 downto 0)  -- output data
        );
    end component; 
    -- nf_register_we_r
    component nf_register_we_r
        generic
        (
            width   : integer   := 1;
            rst_val : integer   := 0
        );
        port
        (
            clk     : in    std_logic;                          -- clk
            resetn  : in    std_logic;                          -- resetn
            we      : in    std_logic;                          -- write enable
            datai   : in    std_logic_vector(width-1 downto 0); -- input data
            datao   : out   std_logic_vector(width-1 downto 0)  -- output data
        );
    end component;
begin

    -- working with instruction fetch instruction (stalled and not stalled)
    instr_if      <= 32X"00000000" when flush_id else instr_if_stalled when sel_if_instr(0) else rd_i;  -- from fetch stage
    we_if_stalled <= stall_if and ( not sel_if_instr(0) ) and ( not branch_type_delayed(3) );  -- for sw and branch stalls
    sel_if_in(0)  <= stall_if and ( not branch_type_delayed(3) );
    -- finding pc values
    pc_i <= pc_branch when pc_src else pc_not_branch;
    pc_not_branch <= addr_i_i + 4;
    addr_i <= addr_i_i;
    -- finding flush instruction decode signals
    flush_id_sw_instr(0) <= not req_ack_i;
    flush_id_branch(0) <= pc_src and ( not stall_if );
    flush_id <= flush_id_ifu(0) or flush_id_delayed(0) or flush_id_branch(0) or flush_id_sw_instr(0);
    -- setting instruction interface signals
    req_i  <= '1';
    we_i   <= '0';
    wd_i   <= 32X"0";
    size_i <= "10";  -- word

    -- selecting instruction fetch stage instruction
    sel_id_ff               : nf_register       generic map( 1  )             port map ( clk , resetn , sel_if_in , sel_if_instr );
    -- stalled instruction fetch instruction
    instr_if_stall          : nf_register_we    generic map( 32 )             port map ( clk , resetn , we_if_stalled, rd_i, instr_if_stalled );
    -- flush instruction decode signals
    reg_flush_id_ifu        : nf_register_we_r  generic map( 1, 0 )           port map ( clk , resetn , '1', "0", flush_id_ifu );
    reg_flush_id_delayed    : nf_register       generic map( 1  )             port map ( clk , resetn , flush_id_branch, flush_id_delayed );
    branch_type_delayed_ff  : nf_register       generic map( 4  )             port map ( clk , resetn , branch_type, branch_type_delayed );
    -- creating program counter
    register_pc             : nf_register_we_r  generic map( 32, PROG_START ) port map ( clk , resetn , not stall_if, pc_i, addr_i_i );

end rtl; -- nf_i_fu
