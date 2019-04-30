--
-- File            :   nf_reg_file.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.04.19
-- Language        :   VHDL
-- Description     :   This is register file
-- Copyright(c)    :   2019 Vlasov D.V.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library nf;
use nf.nf_mem_pkg.all;

entity nf_reg_file is
    port 
    (
        clk     : in    std_logic;                      -- clock
        ra1     : in    std_logic_vector(4  downto 0);  -- read address 1
        rd1     : out   std_logic_vector(31 downto 0);  -- read data 1
        ra2     : in    std_logic_vector(4  downto 0);  -- read address 2
        rd2     : out   std_logic_vector(31 downto 0);  -- read data 2
        wa3     : in    std_logic_vector(4  downto 0);  -- write address 
        wd3     : in    std_logic_vector(31 downto 0);  -- write data
        we3     : in    std_logic                       -- write enable signal
    );
end nf_reg_file;

architecture rtl of nf_reg_file is
    -- creating register file
    signal  reg_file    :   mem_t(31 downto 0)(31 downto 0) := ( others => 32X"00000000" );
begin

    -- getting read data 1 from register file
    rd1 <= ( others => '0' ) when ( ra1 = 5X"00" ) else wd3 when ( wa3 = ra1 ) else reg_file( to_integer( unsigned( ra1 ) ) );
    -- getting read data 2 from register file
    rd2 <= ( others => '0' ) when ( ra2 = 5X"00" ) else wd3 when ( wa3 = ra2 ) else reg_file( to_integer( unsigned( ra2 ) ) );
    -- writing value in register file
    write2reg_file : process( clk )
    begin
        if( rising_edge( clk ) ) then
            if( ( we3 = '1' ) and ( wa3 /= 5X"00" ) ) then
                reg_file( to_integer( unsigned( wa3 ) ) ) <= wd3;
            end if;
        end if;
    end process;

end rtl; -- nf_reg_file
