--
-- File            :   nf_param_mem.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.06.19
-- Language        :   VHDL
-- Description     :   This is memory with parameter
-- Copyright(c)    :   2019 Vlasov D.V.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use std.standard.boolean;
library nf;
use nf.nf_mem_pkg.all;

entity nf_param_mem is
    generic
    (
        addr_w  : integer := 6;                         -- actual address memory width
        data_w  : integer := 32;                        -- actual data width
        depth   : integer := 2 ** 6                     -- depth of memory array
    );
    port 
    (
        clk     : in    std_logic;                              -- clock
        waddr   : in    std_logic_vector(addr_w-1 downto 0);    -- write address
        raddr   : in    std_logic_vector(addr_w-1 downto 0);    -- read address
        we      : in    std_logic;                              -- write enable
        wd      : in    std_logic_vector(data_w-1 downto 0);    -- write data
        rd      : out   std_logic_vector(data_w-1 downto 0)     -- read data
    );
end nf_param_mem;

architecture rtl of nf_param_mem is
    signal mem  : mem_t(depth-1 downto 0)(data_w-1 downto 0) := ( others => ( others => 'X' ) );
begin

    rd <= mem( to_integer( unsigned( raddr ) ) );

    mem_write_proc : process( clk )
    begin
        if( rising_edge(clk) ) then
            if( we ) then
                mem( to_integer( unsigned( waddr ) ) ) <= wd; 
            end if;
        end if;
    end process;

end rtl; -- nf_param_mem
