--
-- File            :   nf_apb_mux.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.11.29
-- Language        :   VHDL
-- Description     :   This is APB MUX module
-- Copyright(c)    :   2019 Vlasov D.V.
--

library ieee;
use ieee.std_logic_1164.all;
library nf;
use nf.nf_settings.all;
use nf.nf_help_pkg.all;
use nf.nf_components.all;

entity nf_apb_mux is
    generic
    (
        apb_slave_c : integer;
        apb_addr_w  : integer
    );
    port
    (
        -- clock and reset
        pclk        : in    std_logic;                                              -- pclock
        presetn     : in    std_logic;                                              -- presetn
        -- APB master side
        paddr_m     : in    std_logic_vector(apb_addr_w-1 downto 0);                -- APB - master PADDR
        prdata_m    : out   std_logic_vector(31           downto 0);                -- APB - master PRDATA
        pready_m    : out   std_logic;                                              -- APB - master PREADY
        psel_m      : in    std_logic;                                              -- APB - master PSEL
        -- APB slave side
        prdata_s    : in    logic_v_array   (apb_slave_c-1 downto 0)(31 downto 0);  -- APB - slave PRDATA
        psel_s      : out   logic_array     (apb_slave_c-1 downto 0);               -- APB - slave PSEL
        pready_s    : in    logic_array     (apb_slave_c-1 downto 0);               -- APB - slave PREADY
        --
        bus_error   : out   std_logic
    );
end nf_apb_mux;

architecture rtl of nf_apb_mux is
begin

    mux_proc : process( all )
    begin
        prdata_m <= (others => '0'); 
        psel_s   <= (others => '0'); 
        pready_m <= '1';
        bus_error <= '0';
        case?( paddr_m ) is
            when NF_APB_GPIO_0_ADDR =>  prdata_m <= prdata_s(0) ; psel_s(0) <= psel_m ; pready_m <= pready_s(0) ;
            when NF_APB_PWM_0_ADDR  =>  prdata_m <= prdata_s(1) ; psel_s(1) <= psel_m ; pready_m <= pready_s(1) ;
            when others             =>  bus_error <= '1';
        end case ?;
    end process;

end rtl; -- nf_apb_mux
