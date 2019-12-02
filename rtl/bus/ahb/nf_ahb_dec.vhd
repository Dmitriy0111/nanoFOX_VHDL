--
-- File            :   nf_ahb_dec.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.04.25
-- Language        :   VHDL
-- Description     :   This is AHB decoder module
-- Copyright(c)    :   2019 Vlasov D.V.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library nf;
use nf.nf_settings.all;
use nf.nf_ahb_pkg.all;

entity nf_ahb_dec is
    generic
    (
        slave_c : integer := SLAVE_COUNT
    );
    port
    (
        haddr   : in    std_logic_vector(31        downto 0);   -- AHB address 
        hsel    : out   std_logic_vector(slave_c-1 downto 0)    -- hsel signal
    );
end nf_ahb_dec;

architecture rtl of nf_ahb_dec is
begin

    dec_proc : process(all)
        begin
            hsel <= 5X"0";
            case?( haddr ) is
                when NF_RAM_ADDR_MATCH  => hsel <= 5X"01";
                when NF_GPIO_ADDR_MATCH => hsel <= 5X"02";
                when NF_PWM_ADDR_MATCH  => hsel <= 5X"04";
                when NF_UART_ADDR_MATCH => hsel <= 5X"08";
                when NF_AHB_APB_MATCH   => hsel <= 5X"10";
                when others         =>
            end case ?;
        end process;

end rtl; -- nf_ahb_dec
