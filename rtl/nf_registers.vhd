--
-- File            :   nf_register.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.04.19
-- Language        :   VHDL
-- Description     :   This is file with registers modules
-- Copyright(c)    :   2019 Vlasov D.V.
--
        
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- simple register with reset and clock 
entity nf_register is
    generic
    (
        width : integer := 1
    );
    port 
    (
        clk     : in    std_logic;                          -- clock
        resetn  : in    std_logic;                          -- reset
        datai   : in    std_logic_vector(width-1 downto 0); -- input data
        datao   : out   std_logic_vector(width-1 downto 0)  -- output data
    );
end nf_register;

architecture rtl of nf_register is
begin

    process(all)
    begin
        if( not resetn ) then
            datao <= (others => '0');
        elsif( rising_edge(clk) ) then
            datao <= datai;
        end if;
    end process;

end rtl; -- nf_register

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- register with write enable input
entity nf_register_we is
    generic
    (
        width : integer := 1
    );
    port 
    (
        clk     : in    std_logic;                          -- clock
        resetn  : in    std_logic;                          -- reset
        we      : in    std_logic;                          -- write enable
        datai   : in    std_logic_vector(width-1 downto 0); -- input data
        datao   : out   std_logic_vector(width-1 downto 0)  -- output data
    );
end nf_register_we;

architecture rtl of nf_register_we is
begin

    process(all)
    begin
        if( not resetn ) then
            datao <= (others => '0');
        elsif( rising_edge(clk) ) then
            if( we ) then
                datao <= datai;
            end if;
        end if;
    end process;

end rtl; -- nf_register_we
