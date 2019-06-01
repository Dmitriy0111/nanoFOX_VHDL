--
-- File            :   nf_router_dec.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.04.22
-- Language        :   VHDL
-- Description     :   This is decoder unit for routing lw sw command's
-- Copyright(c)    :   2019 Vlasov D.V.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library nf;
use nf.nf_settings.all;

entity nf_router_dec is
    generic
    (
        Slave_n     : integer := SLAVE_NUMBER
    );
    port 
    (
        addr_m      : in    std_logic_vector(31        downto 0);   -- master address
        slave_sel   : out   std_logic_vector(Slave_n-1 downto 0)    -- slave select
    );
end nf_router_dec;

architecture rtl of nf_router_dec is
begin
    
    -- RAM  address range  0x0000_0000 - 0x0000_ffff
    slave_sel(0) <= '1' when ( addr_m(31 downto 16) = NF_RAM_ADDR_MATCH  ) else '0';

    -- GPIO address range  0x0001_0000 - 0x0001_ffff
    slave_sel(1) <= '1' when ( addr_m(31 downto 16) = NF_GPIO_ADDR_MATCH ) else '0';

    -- PWM  address range  0x0002_0000 - 0x0002_ffff
    slave_sel(2) <= '1' when ( addr_m(31 downto 16) = NF_PWM_ADDR_MATCH  ) else '0';
    
    -- For future devices
    slave_sel(3) <= '0';

end rtl; -- nf_router_dec
