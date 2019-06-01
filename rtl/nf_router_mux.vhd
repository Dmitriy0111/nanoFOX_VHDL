--
-- File            :   nf_router_mux.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.04.22
-- Language        :   VHDL
-- Description     :   This is mux unit for routing lw sw command's
-- Copyright(c)    :   2019 Vlasov D.V.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

library nf;
use nf.nf_settings.all;

entity nf_router_mux is
    generic
    (
        Slave_n     : integer := SLAVE_NUMBER
    );
    port 
    (
        slave_sel   : in    std_logic_vector(Slave_n-1 downto 0);               -- slave select
        rd_s        : in    logic_v_array   (Slave_n-1 downto 0)(31 downto 0);  -- read data array slave
        rd_m        : out   std_logic_vector(31        downto 0)                -- read data master
    );
end nf_router_mux;

architecture rtl of nf_router_mux is
begin
    
    -- mux for routing one register value
    mux_out : process(all)
    begin
        rd_m <= rd_s(0);
        case ?( slave_sel ) is
            when "---1" => rd_m <= rd_s(0);
            when "--10" => rd_m <= rd_s(1);
            when "-100" => rd_m <= rd_s(2);
            when "1000" => rd_m <= rd_s(2);
            when others =>
        end case ?;
    end process;

end rtl; -- nf_router_mux
