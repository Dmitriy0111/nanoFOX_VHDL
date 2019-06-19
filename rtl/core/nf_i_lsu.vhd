--
-- File            :   nf_i_lsu.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.04.24
-- Language        :   VHDL
-- Description     :   This is instruction load store unit
-- Copyright(c)    :   2019 Vlasov D.V.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
library nf;
use nf.nf_cpu_def.all;
use nf.nf_help_pkg.all;

entity nf_i_lsu is
    port 
    (
        -- clock and reset
        clk             : in    std_logic;                      -- clock
        resetn          : in    std_logic;                      -- reset
        -- pipeline wires
        result_imem     : in    std_logic_vector(31 downto 0);  -- result from imem stage
        rd2_imem        : in    std_logic_vector(31 downto 0);  -- read data 2 from imem stage
        we_dm_imem      : in    std_logic;                      -- write enable data memory from imem stage
        rf_src_imem     : in    std_logic;                      -- register file source enable from imem stage
        sign_dm_imem    : in    std_logic;                      -- sign for load operations
        size_dm_imem    : in    std_logic_vector(1  downto 0);  -- size data memory from imem stage
        rd_dm_iwb       : out   std_logic_vector(31 downto 0);  -- read data for write back stage
        lsu_busy        : out   std_logic;                      -- load store unit busy
        lsu_err         : out   std_logic;                      -- load store error
        s_misaligned    : out   std_logic;                      -- store misaligned
        l_misaligned    : out   std_logic;                      -- load misaligned
        stall_if        : in    std_logic;                      -- stall instruction fetch
        -- data memory and other's
        addr_dm         : out   std_logic_vector(31 downto 0);  -- address data memory
        rd_dm           : in    std_logic_vector(31 downto 0);  -- read data memory
        wd_dm           : out   std_logic_vector(31 downto 0);  -- write data memory
        we_dm           : out   std_logic;                      -- write enable data memory signal
        size_dm         : out   std_logic_vector(1  downto 0);  -- size for load/store instructions
        req_dm          : out   std_logic;                      -- request data memory signal
        req_ack_dm      : in    std_logic                       -- request acknowledge data memory signal
    );
end nf_i_lsu;

architecture rtl of nf_i_lsu is
    signal lsu_busy_i       : std_logic;                        -- lsu busy (internal)
    signal addr_dm_i        : std_logic_vector(31 downto 0);    -- address data memory (internal)
    signal size_dm_i        : std_logic_vector(1  downto 0);    -- size for load/store instructions (internal)
    signal wd_dm_i          : std_logic_vector(31 downto 0);    -- write data memory
    signal we_dm_i          : std_logic;                        -- write enable data memory signal
    -- load data wires
    signal l_data_3         : std_logic_vector(7  downto 0);    -- load data 3
    signal l_data_2         : std_logic_vector(7  downto 0);    -- load data 2
    signal l_data_1         : std_logic_vector(7  downto 0);    -- load data 1
    signal l_data_0         : std_logic_vector(7  downto 0);    -- load data 0
    signal l_data_f         : std_logic_vector(31 downto 0);    -- full load data
    -- store data wires     
    signal s_data_3         : std_logic_vector(7  downto 0);    -- store data 3
    signal s_data_2         : std_logic_vector(7  downto 0);    -- store data 2
    signal s_data_1         : std_logic_vector(7  downto 0);    -- store data 1
    signal s_data_0         : std_logic_vector(7  downto 0);    -- store data 0
    signal s_data_f         : std_logic_vector(31 downto 0);    -- full store data
    signal lsu_err_ff       : std_logic;                        -- load store unit error sequential
    signal lsu_err_c        : std_logic;                        -- load store unit error combinational

    signal s_misaligned_i   : std_logic;                        -- store misaligned (internal)
    signal l_misaligned_i   : std_logic;                        -- load misaligned (internal)

    signal sign_dm          : std_logic;                        -- unsigned load data memory?
    signal misaligned       : std_logic;                        -- load or store address misaligned

    component nf_cache
        generic
        (
            addr_w  : integer := 6;                         -- actual address memory width
            depth   : integer := 2 ** 6                     -- depth of memory array
        );
        port 
        (
            clk     : in    std_logic;                      -- clock
            raddr   : in    std_logic_vector(31 downto 0);  -- address
            waddr   : in    std_logic_vector(31 downto 0);  -- address
            we_d    : in    std_logic;                      -- write enable
            size_d  : in    std_logic_vector(1  downto 0);  
            we_tv   : in    std_logic;
            wd      : in    std_logic_vector(31 downto 0);  -- write data
            wv      : in    std_logic;                      -- write valid
            rd      : out   std_logic_vector(31 downto 0);  -- read data
            hit     : out   std_logic
        );
    end component;
begin

    
    misaligned   <= ( ( bool2sl( size_dm_imem = "10" ) and bool2sl( result_imem(1 downto 0) /= 0 ) ) or 
                      ( bool2sl( size_dm_imem = "01" ) and bool2sl( result_imem(0)          /= '0' ) ) );
    s_misaligned_i <= misaligned and we_dm_imem;
    l_misaligned_i <= misaligned and rf_src_imem;
    s_misaligned   <= s_misaligned_i;
    l_misaligned   <= l_misaligned_i;
    lsu_err_c    <= s_misaligned_i or l_misaligned_i;
    lsu_err      <= lsu_err_c or lsu_err_ff;
    lsu_busy     <= lsu_busy_i;
    req_dm       <= lsu_busy_i;
    l_data_f     <= l_data_3 & l_data_2 & l_data_1 & l_data_0;
    s_data_f     <= s_data_3 & s_data_2 & s_data_1 & s_data_0;
    addr_dm      <= addr_dm_i;
    size_dm      <= size_dm_i;
    wd_dm        <= wd_dm_i;
    we_dm        <= we_dm_i;

    lsu_err_proc : process( clk, resetn )
    begin
        if( not resetn ) then
            lsu_err_ff <= '0';
        elsif( rising_edge(clk) ) then
            if( lsu_err_c ) then
                lsu_err_ff <= '1';
            end if;
            if( not stall_if ) then
                lsu_err_ff <= '0';
            end if;
        end if;
    end process;

    busy_proc : process( clk, resetn )
    begin
        if( not resetn ) then
            lsu_busy_i <= '0';
        elsif( rising_edge(clk) ) then
            if( ( we_dm_imem or rf_src_imem ) and not lsu_err_c ) then
                lsu_busy_i <= '1';
            end if;
            if( req_ack_dm ) then
                lsu_busy_i <= '0';
            end if;
        end if;
    end process;

    -- form load data value
    form_load_data_proc : process( all )
    begin
        l_data_3 <= rd_dm(31 downto 24);
        l_data_2 <= rd_dm(23 downto 16);
        l_data_1 <= rd_dm(15 downto  8);
        l_data_0 <= rd_dm(7  downto  0);
        case( addr_dm_i(1 downto 0) ) is
            when "00"   => l_data_0 <= rd_dm(7  downto  0);
            when "01"   => l_data_0 <= rd_dm(15 downto  8);
            when "10"   => l_data_0 <= rd_dm(23 downto 16);
            when "11"   => l_data_0 <= rd_dm(31 downto 24);
            when others =>
        end case;
        case( addr_dm_i(1 downto 0) ) is
            when "00"   => l_data_1 <= rd_dm(15 downto  8);
            when "01"   => l_data_1 <= rd_dm(15 downto  8);
            when "10"   => l_data_1 <= rd_dm(31 downto 24);
            when "11"   => l_data_1 <= rd_dm(31 downto 24);
            when others =>
        end case;
    end process;

    -- form store data value
    form_store_data_proc : process( all )
    begin
        s_data_3 <= rd2_imem(31 downto 24);
        s_data_2 <= rd2_imem(23 downto 16);
        s_data_1 <= rd2_imem(15 downto  8);
        s_data_0 <= rd2_imem(7  downto  0);
        case( result_imem(1 downto 0) ) is
            when "00"   => s_data_1 <= rd2_imem(15 downto  8);
            when "01"   => s_data_1 <= rd2_imem(7  downto  0);
            when others =>
        end case;
        case( result_imem(1 downto 0) ) is
            when "00"   => s_data_2 <= rd2_imem(23 downto 16);
            when "10"   => s_data_2 <= rd2_imem(7  downto  0);
            when others =>
        end case;
        case( result_imem(1 downto 0) ) is
            when "00"   => s_data_3 <= rd2_imem(31 downto 24);
            when "10"   => s_data_3 <= rd2_imem(15 downto  8);
            when "11"   => s_data_3 <= rd2_imem(7  downto  0);
            when others =>
        end case;
    end process;

    dm_proc : process( clk, resetn )
    begin
        if( not resetn ) then
            addr_dm_i <= (others => '0');
            wd_dm_i   <= (others => '0');
            we_dm_i   <= '0';
            size_dm_i <= (others => '0');
            sign_dm   <= '0';
        elsif( rising_edge(clk) ) then
            if( ( we_dm_imem or rf_src_imem ) and not lsu_busy_i ) then
                addr_dm_i <= result_imem;
                wd_dm_i   <= s_data_f;
                we_dm_i   <= we_dm_imem;
                size_dm_i <= size_dm_imem;
                sign_dm   <= sign_dm_imem;
            end if;
        end if;
    end process;
    
    rd_dm_iwb_proc : process( clk, resetn )
    begin
        if( not resetn ) then
            rd_dm_iwb <= (others => '0');
        elsif( rising_edge(clk) ) then
            if( req_ack_dm ) then
                case( size_dm_i ) is
                    when "00"   => rd_dm_iwb <= repbit( l_data_f( 7) and sign_dm , 24 ) & l_data_f(7  downto 0);
                    when "01"   => rd_dm_iwb <= repbit( l_data_f(15) and sign_dm , 16 ) & l_data_f(15 downto 0);
                    when "10"   => rd_dm_iwb <= l_data_f;
                    when others => rd_dm_iwb <= l_data_f;
                end case;
            end if;
        end if;
    end process;

    nf_d_cache : nf_cache
    generic map
    (
        addr_w  => 6,           -- actual address memory width
        depth   => 2 ** 6       -- depth of memory array
    )
    port map
    (
        clk     => clk,         -- clock
        raddr   => 32X"0000",   -- address
        waddr   => addr_dm_i,   -- address
        we_d    => we_dm_i,     -- write enable
        size_d  => size_dm_i,  
        we_tv   => we_dm_i, 
        wd      => wd_dm_i,     -- write data
        wv      => we_dm_i,     -- write valid
        rd      => open,        -- read data
        hit     => open
    );

end rtl; -- nf_i_lsu
