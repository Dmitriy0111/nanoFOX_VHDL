--
-- File            :   nf_reg_file.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.04.19
-- Language        :   SystemVerilog
-- Description     :   This is register file
-- Copyright(c)    :   2019 Vlasov D.V.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

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
        we3     : in    std_logic;                      -- write enable signal
        ra0     : in    std_logic_vector(4  downto 0);  -- read address 0
        rd0     : out   std_logic_vector(31 downto 0)   -- read data 0

    );
end nf_reg_file;

architecture rtl of nf_reg_file is
    type    reg_file_t is array (31 downto 0) of std_logic_vector(31 downto 0);
    -- creating register file
    signal  reg_file : reg_file_t := ( others => ( others => '0' ) );
begin
    -- getting read data 1 from register file
    rd0 <= (others => '0') when ( to_integer( unsigned( ra0 ) ) = 0 ) else reg_file( to_integer( unsigned( ra0 ) ) );
    -- getting read data 2 from register file
    rd1 <= (others => '0') when ( to_integer( unsigned( ra1 ) ) = 0 ) else reg_file( to_integer( unsigned( ra1 ) ) );
    -- for debug
    rd2 <= (others => '0') when ( to_integer( unsigned( ra2 ) ) = 0 ) else reg_file( to_integer( unsigned( ra2 ) ) );
    -- writing value in register file
    write2reg_file : process(all)
    begin
        if( rising_edge(clk) ) then
            if( we3 ) then
                reg_file( to_integer( unsigned( wa3 ) ) ) <= wd3;
            end if;
        end if;
    end process;

end rtl; -- nf_reg_file
