--
-- File            :   nf_ram.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.04.22
-- Language        :   VHDL
-- Description     :   This is common ram memory
-- Copyright(c)    :   2019 Vlasov D.V.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.nf_mem_pkg.all;
use work.nf_program.all;

entity nf_ram is
    generic
    (
        addr_w  : integer := 6;                         -- actual address memory width
        depth   : integer := 2 ** 6                     -- depth of memory array
    );
    port 
    (
        clk     : in    std_logic;                      -- clock
        addr    : in    std_logic_vector(31 downto 0);  -- address
        we      : in    std_logic_vector(3  downto 0);  -- write enable
        wd      : in    std_logic_vector(31 downto 0);  -- write data
        rd      : out   std_logic_vector(31 downto 0)   -- read data
    );
end nf_ram;

architecture rtl of nf_ram is
    signal  bank_0  : mem_t(depth-1   downto 0)(7 downto 0) := bank_init(0,program,depth);
    signal  bank_1  : mem_t(depth-1   downto 0)(7 downto 0) := bank_init(1,program,depth);
    signal  bank_2  : mem_t(depth-1   downto 0)(7 downto 0) := bank_init(2,program,depth);
    signal  bank_3  : mem_t(depth-1   downto 0)(7 downto 0) := bank_init(3,program,depth);
begin

    rd(31 downto 24) <= bank_3(to_integer(unsigned(addr(addr_w-1 downto 0))));
    rd(23 downto 16) <= bank_2(to_integer(unsigned(addr(addr_w-1 downto 0))));
    rd(15 downto  8) <= bank_1(to_integer(unsigned(addr(addr_w-1 downto 0))));
    rd(7  downto  0) <= bank_0(to_integer(unsigned(addr(addr_w-1 downto 0))));

    bank_0_write_proc : process(all)
    begin
        if( rising_edge(clk) ) then
            if( we(0) ) then
                bank_0(to_integer(unsigned(addr(addr_w-1 downto 0)))) <= wd(7  downto  0); 
            end if;
        end if;
    end process;
    bank_1_write_proc : process(all)
    begin
        if( rising_edge(clk) ) then
            if( we(1) ) then
                bank_1(to_integer(unsigned(addr(addr_w-1 downto 0)))) <= wd(15 downto  8); 
            end if;
        end if;
    end process;
    bank_2_write_proc : process(all)
    begin
        if( rising_edge(clk) ) then
            if( we(2) ) then
                bank_2(to_integer(unsigned(addr(addr_w-1 downto 0)))) <= wd(23 downto 16); 
            end if;
        end if;
    end process;
    bank_3_write_proc : process(all)
    begin
        if( rising_edge(clk) ) then
            if( we(3) ) then
                bank_3(to_integer(unsigned(addr(addr_w-1 downto 0)))) <= wd(31 downto 24); 
            end if;
        end if;
    end process;

end rtl; -- nf_ram
