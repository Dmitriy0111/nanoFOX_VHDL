--
-- File            :   nf_clock_div.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.04.19
-- Language        :   SystemVerilog
-- Description     :   This is unit for creating clock enable strobe
-- Copyright(c)    :   2019 Vlasov D.V.
--

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

-- simple register with reset and clock 
entity nf_clock_div is
    port 
    (
        -- clock and reset
        clk     : in    std_logic;                      -- clock
        resetn  : in    std_logic;                      -- reset
        -- strobbing
        div     : in    std_logic_vector(25 downto 0);  -- div_number
        en      : out   std_logic                       -- enable strobe
    );
end nf_clock_div;

architecture rtl of nf_clock_div is
    signal int_div  : std_logic_vector (25 downto 0);   -- internal divider register
    signal int_c    : std_logic_vector (25 downto 0);   -- internal compare register
begin

    en <= '1' when ( int_div = int_c ) else '0';

    process(all)
    begin
        if( not resetn ) then
            int_c   <= (others => '0');
            int_div <= (others => '0');
        elsif( rising_edge(clk) ) then
            int_div <= int_div + 1;
            if( int_div = int_c ) then
                int_div <= (others => '0');
                int_c   <= div;
            end if;
        end if;
    end process;
    
end rtl; -- nf_clock_div
