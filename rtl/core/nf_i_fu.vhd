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
use nf.nf_components.all;

entity nf_i_fu is
    port
    (
        -- clock and reset
        clk             : in   std_logic;                       -- clock
        resetn          : in   std_logic;                       -- reset
        -- program counter inputs   
        pc_branch       : in   std_logic_vector(31 downto 0);   -- program counter branch value from decode stage
        pc_src          : in   std_logic;                       -- next program counter source
        stall_if        : in   std_logic;                       -- stalling instruction fetch stage
        instr_if        : out  std_logic_vector(31 downto 0);   -- instruction fetch
        last_pc         : out  std_logic_vector(31 downto 0);   -- last program_counter
        mtvec_v         : in   std_logic_vector(31 downto 0);   -- machine trap-handler base address
        m_ret           : in   std_logic;                       -- m return
        m_ret_pc        : in   std_logic_vector(31 downto 0);   -- m return pc value
        addr_misalign   : out  std_logic;                       -- address misaligned
        lsu_err         : in   std_logic;                       -- load store unit error
        -- memory inputs/outputs
        addr_i          : out  std_logic_vector(31 downto 0);   -- address instruction memory
        rd_i            : in   std_logic_vector(31 downto 0);   -- read instruction memory
        wd_i            : out  std_logic_vector(31 downto 0);   -- write instruction memory
        we_i            : out  std_logic;                       -- write enable instruction memory signal
        size_i          : out  std_logic_vector(1  downto 0);   -- size for load/store instructions
        req_i           : out  std_logic;                       -- request instruction memory signal
        req_ack_i       : in   std_logic                        -- request acknowledge instruction memory signal
    );
end nf_i_fu;

architecture rtl of nf_i_fu is
    signal addr_misalign_i      : std_logic;                        -- address misaligned (internal)
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
    -- flush instruction decode 
    signal flush_id_ff          : std_logic_vector(0  downto 0);    -- flush id stage
    signal flush_id_branch      : std_logic_vector(0  downto 0);    -- flush id stage ( branch operation )
    signal flush_id_sw_instr    : std_logic_vector(0  downto 0);    -- flush id stage ( store data instruction )
begin

    -- working with instruction fetch instruction (stalled and not stalled)
    instr_if      <= 32X"00000000" when flush_id else instr_if_stalled when sel_if_instr(0) else rd_i;  -- from fetch stage
    we_if_stalled <= stall_if and ( not sel_if_instr(0) );  -- for sw and branch stalls
    sel_if_in(0)  <= stall_if;
    -- finding pc values
    pc_not_branch <= addr_i_i + 4;
    addr_i <= addr_i_i;
    addr_misalign <= addr_misalign_i;
    -- finding flush instruction decode signals
    flush_id_sw_instr(0) <= not req_ack_i;
    flush_id_branch(0) <= ( pc_src and ( not stall_if ) ) or m_ret;
    flush_id <= flush_id_ff(0) or flush_id_branch(0) or flush_id_sw_instr(0) or addr_misalign_i;
    -- setting instruction interface signals
    req_i  <= '1';
    we_i   <= '0';
    wd_i   <= 32X"0";
    size_i <= "10";  -- word

    addr_misalign_i <= '1' when ( addr_i_i(1 downto 0) /= "00" ) else '0';
    
    -- finding next program counter value
    pc_next_proc : process( all )
        variable sel : std_logic_vector(2 downto 0);
    begin
        pc_i <= pc_not_branch;
        sel  := ( m_ret & ( addr_misalign_i or lsu_err ) & pc_src );
        case ?( sel ) is
            when "000"  => pc_i <= pc_not_branch;
            when "001"  => pc_i <= pc_branch;
            when "01-"  => pc_i <= mtvec_v;
            when "1--"  => pc_i <= m_ret_pc;
            when others =>
        end case ?;
    end process;
    --
    flush_id_ff_proc : process( clk , resetn )
        variable en : std_logic;
    begin
        en := flush_id_branch(0) or addr_misalign_i or lsu_err;
        if( not resetn ) then
            flush_id_ff <= "1"; -- flushing if-id after reset
        elsif( rising_edge( clk ) ) then
            flush_id_ff <= "0";
            if( en ) then 
                flush_id_ff <= "1"; -- set if branch and stall instruction fetch
            end if;
        end if;
    end process;

    -- selecting instruction fetch stage instruction
    sel_id_ff               : nf_register       generic map( 1  )             port map ( clk , resetn , sel_if_in , sel_if_instr );
    -- stalled instruction fetch instruction
    instr_if_stall          : nf_register_we    generic map( 32 )             port map ( clk , resetn , we_if_stalled , rd_i, instr_if_stalled );
    -- creating program counter and last pc
    register_pc             : nf_register_we_r  generic map( 32, PROG_START ) port map ( clk , resetn , not stall_if , pc_i     , addr_i_i );
    last_pc_ff              : nf_register_we    generic map( 32 )             port map ( clk , resetn , not stall_if , addr_i_i , last_pc  );

end rtl; -- nf_i_fu
