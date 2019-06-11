--
-- File            :   nf_ahb_mux.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.04.25
-- Language        :   VHDL
-- Description     :   This is AHB multiplexer module
-- Copyright(c)    :   2019 Vlasov D.V.
--

library ieee;
use ieee.std_logic_1164.all;
library nf;
use nf.nf_settings.all;
use nf.nf_ahb_pkg.all;

entity nf_ahb_mux is
    generic
    (
        slave_c : integer := SLAVE_COUNT
    );
    port
    (
        hsel_ff     : in    std_logic_vector(slave_c-1 downto 0);           -- hsel after flip-flop
        -- slave side
        hrdata_s    : in    logic_v_array(slave_c-1 downto 0)(31 downto 0); -- AHB read data slaves 
        hresp_s     : in    logic_v_array(slave_c-1 downto 0)(1  downto 0); -- AHB response slaves
        hready_s    : in    logic_array  (slave_c-1 downto 0);              -- AHB ready slaves
        -- master side
        hrdata      : out   std_logic_vector(31 downto 0);                  -- AHB read data master 
        hresp       : out   std_logic_vector(1  downto 0);                  -- AHB response master
        hready      : out   std_logic                                       -- AHB ready master
    );
end nf_ahb_mux;

architecture rtl of nf_ahb_mux is
begin

    mux_proc : process( all )
    begin
        hrdata  <= (others => '0'); 
        hresp   <= AHB_HRESP_ERROR; 
        hready  <= '1';
        case?( hsel_ff ) is
            when "---1" =>  hrdata <= hrdata_s(0) ; hresp <= hresp_s(0) ; hready <= hready_s(0) ;
            when "--10" =>  hrdata <= hrdata_s(1) ; hresp <= hresp_s(1) ; hready <= hready_s(1) ;
            when "-100" =>  hrdata <= hrdata_s(2) ; hresp <= hresp_s(2) ; hready <= hready_s(2) ;
            when "1000" =>  hrdata <= hrdata_s(3) ; hresp <= hresp_s(3) ; hready <= hready_s(3) ;
            when others =>
        end case ?;
    end process;

end rtl; -- nf_ahb_mux
