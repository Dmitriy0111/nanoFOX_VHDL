--
-- File            :   nf_csr.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.06.11
-- Language        :   VHDL
-- Description     :   This is CSR unit
-- Copyright(c)    :   2019 Vlasov D.V.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

library nf;
use nf.nf_cpu_def.all;
use nf.nf_help_pkg.all;
use nf.nf_csr_pkg.all;

entity nf_csr is
    port
    (
        -- clock and reset
        clk             : in   std_logic;                       -- clk  
        resetn          : in   std_logic;                       -- resetn
        -- csr interface
        csr_addr        : in   std_logic_vector(11 downto 0);   -- csr address
        csr_rd          : out  std_logic_vector(31 downto 0);   -- csr read data
        csr_wd          : in   std_logic_vector(31 downto 0);   -- csr write data
        csr_cmd         : in   std_logic_vector(1  downto 0);   -- csr command
        csr_wreq        : in   std_logic;                       -- csr write request
        csr_rreq        : in   std_logic;                       -- csr read request
        -- scan and control wires
        mtvec_v         : out  std_logic_vector(31 downto 0);   -- machine trap-handler base address
        m_ret_pc        : out  std_logic_vector(31 downto 0);   -- m return pc value
        addr_mis        : in   std_logic_vector(31 downto 0);   -- address misaligned value
        addr_misalign   : in   std_logic;                       -- address misaligned signal
        s_misaligned    : in   std_logic;                       -- store misaligned signal
        l_misaligned    : in   std_logic;                       -- load misaligned signal
        ls_mis          : in   std_logic_vector(31 downto 0);   -- load slore misaligned value
        m_ret_ls        : in   std_logic_vector(31 downto 0)    -- m return pc value for load/store misaligned
    );
end nf_csr;

architecture rtl of nf_csr is
    signal csr_rd_i : std_logic_vector(31 downto 0);    -- csr_rd internal
    signal csr_wd_i : std_logic_vector(31 downto 0);    -- csr_wd internal
    signal mcycle   : std_logic_vector(31 downto 0);    -- Machine cycle counter
    signal mtvec    : std_logic_vector(31 downto 0);    -- Machine trap-handler base address
    signal mscratch : std_logic_vector(31 downto 0);    -- Scratch register for machine trap handlers
    signal mepc     : std_logic_vector(31 downto 0);    -- Machine exception program counter
    signal mcause   : std_logic_vector(31 downto 0);    -- Machine trap cause
    signal mtval    : std_logic_vector(31 downto 0);    -- Machine bad address or instruction

    signal m_out0   : std_logic_vector(31 downto 0);    -- Machine out
    signal m_out1   : std_logic_vector(31 downto 0);    -- Machine out
begin

    mtvec_v <= mtvec;   -- value of mtvec
    
    csr_rd <= csr_rd_i;

    m_ret_pc <= mepc;

    -- write mtval data
    mtval_proc : process( clk )
    begin
        if( rising_edge(clk) ) then
            if( not resetn ) then
                mtval <= (others => '0');
            else
                if( addr_misalign ) then
                    mtval <= addr_mis;
                end if;
                if( s_misaligned or l_misaligned ) then
                    mtval <= ls_mis;
                end if;
            end if;
        end if;
    end process;

    -- write mcause data
    mcause_proc : process( clk )
    begin
        if( rising_edge(clk) ) then
            if( not resetn ) then
                mcause <= (others => '0');
            else
                if( addr_misalign ) then
                    mcause <= 32X"0";
                end if;
                if( s_misaligned ) then
                    mcause <= 32X"6";
                end if;
                if( l_misaligned ) then
                    mcause <= 32X"4";
                end if;
            end if;
        end if;
    end process;
    -- write mscratch data
    mscratch_proc : process( clk )
    begin
        if( rising_edge(clk) ) then
            if( not resetn ) then
                mscratch <= (others => '0');
            else
                if( csr_wreq and bool2sl( csr_addr = MSCRATCH_A ) ) then
                    mscratch <= csr_wd_i;
                end if;
            end if;
        end if;
    end process;
    -- write mtvec data
    mtvec_proc : process( clk )
    begin
        if( rising_edge(clk) ) then
            if( not resetn ) then
                mtvec <= (others => '0');
            else
                if( csr_wreq and bool2sl( csr_addr = MTVEC_A ) ) then
                    mtvec <= csr_wd_i;
                end if;
            end if;
        end if;
    end process;
    -- write mepc data
    mepc_proc : process( clk )
    begin
        if( rising_edge(clk) ) then
            if( not resetn ) then
                mepc <= (others => '0');
            else
                if( csr_wreq and bool2sl( csr_addr = MEPC_A ) ) then
                    mepc <= csr_wd_i;
                end if;
                if( addr_misalign ) then
                    mepc <= addr_mis;
                end if;
                if( s_misaligned or l_misaligned ) then
                    mepc <= m_ret_ls;
                end if;
            end if;
        end if;
    end process;
    -- edit mcycle register
    mcycle_proc : process( clk )
    begin
        if( rising_edge(clk) ) then
            if( not resetn ) then
                mcycle <= (others => '0');
            else
                if( csr_wreq and bool2sl( csr_addr = MCYCLE_A ) ) then
                    mcycle <= csr_wd_i;
                else
                    mcycle <= mcycle + 1;
                end if;
            end if;
        end if;
    end process;
    -- finding csr write data with command
    csr_wd_proc : process( all )
    begin
        csr_wd_i <= (others => '0');
        case( csr_cmd ) is
            when CSR_NONE   => csr_wd_i <=     csr_wd;
            when CSR_WR     => csr_wd_i <=     csr_wd;
            when CSR_SET    => csr_wd_i <=     csr_wd or  csr_rd_i;
            when CSR_CLR    => csr_wd_i <= not csr_wd and csr_rd_i;
            when others     =>
        end case;
    end process;
    -- find csr read data
    m_out_0_proc : process( all )
    begin
        m_out0 <= ( others => '0' );
        case( csr_addr ) is
            when MCYCLE_A   => m_out0 <= mcycle;
            when MISA_A     => m_out0 <= MISA_V; -- read only
            when MSCRATCH_A => m_out0 <= mscratch;
            when MTVEC_A    => m_out0 <= mtvec;
            when others     =>
        end case;
    end process;
    -- find csr read data
    m_out_1_proc : process( all )
    begin
        m_out1 <= ( others => '0' );
        case( csr_addr ) is
            when MEPC_A     => m_out1 <= mepc;
            when MCAUSE_A   => m_out1 <= mcause;
            when MTVAL_A    => m_out1 <= mtval;
            when others     =>
        end case;
    end process;
    -- find csr read data
    scr_rd_proc : process( all )
    begin
        csr_rd_i <= ( others => '0' );
        case( csr_addr ) is
            when MCYCLE_A |
                 MISA_A |
                 MSCRATCH_A |
                 MTVEC_A    => csr_rd_i <= m_out0;
            when MEPC_A |
                 MCAUSE_A |
                 MTVAL_A    => csr_rd_i <= m_out1;
            when others     =>
        end case;
    end process;

end rtl; -- nf_csr
