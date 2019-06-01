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

library nf;
use nf.nf_mem_pkg.all;

entity nf_ram is
    generic
    (
        addr_w  : integer := 6;                         -- actual address memory width
        depth   : integer := 2 ** 6                     -- depth of memory array
    );
    port 
    (
        -- clock and reset
        clk     : in    std_logic;                      -- clock
        -- nf_router side
        addr    : in    std_logic_vector(31 downto 0);  -- address
        we      : in    std_logic;                      -- write enable
        wd      : in    std_logic_vector(31 downto 0);  -- write data
        rd      : out   std_logic_vector(31 downto 0)   -- read data
    );
end nf_ram;

architecture rtl of nf_ram is
    -- creating memory array
    signal  ram : mem_t(depth-1 downto 0)(31 downto 0) := (others => 32X"XXXXXXXX");
begin
    rd <= ram(to_integer(unsigned(addr(addr_w-1 downto 0))));  -- for simulation

    process(all)
    begin
        if( rising_edge(clk) ) then
            if( we ) then
                ram(to_integer(unsigned(addr(addr_w-1 downto 0)))) <= wd;
            end if;
        end if;
    end process;

end rtl; -- nf_ram