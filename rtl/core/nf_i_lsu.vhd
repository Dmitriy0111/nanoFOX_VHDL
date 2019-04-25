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
        size_dm_imem    : in    std_logic_vector(1  downto 0);  -- size data memory from imem stage
        rd_dm_iwb       : out   std_logic_vector(31 downto 0);  -- read data for write back stage
        lsu_busy        : out   std_logic;                      -- load store unit busy
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
    signal  lsu_busy_i  : std_logic;    -- lsu busy internal
begin

    lsu_busy <= lsu_busy_i;
    req_dm   <= lsu_busy_i;

    busy_proc : process(all)
    begin
        if( not resetn ) then
            lsu_busy_i <= '0';
        elsif( rising_edge(clk) ) then
            if( we_dm_imem or rf_src_imem ) then
                lsu_busy_i <= '1';
            elsif( req_ack_dm ) then
                lsu_busy_i <= '0';
            end if;
        end if;
    end process;

    dm_proc : process(all)
    begin
        if( not resetn ) then
            addr_dm <= (others => '0');
            wd_dm   <= (others => '0');
            we_dm   <= '0';
            size_dm <= (others => '0');
        elsif( rising_edge(clk) ) then
            if( ( we_dm_imem or rf_src_imem ) and not lsu_busy_i ) then
                addr_dm <= result_imem;
                wd_dm   <= rd2_imem;
                we_dm   <= we_dm_imem;
                size_dm <= size_dm_imem;
            end if;
        end if;
    end process;
    
    rd_dm_iwb_proc : process(all)
    begin
        if( not resetn ) then
            rd_dm_iwb <= (others => '0');
        elsif( rising_edge(clk) ) then
            if( req_ack_dm ) then
                rd_dm_iwb <= rd_dm;
            end if;
        end if;
    end process;

end rtl; -- nf_i_lsu
