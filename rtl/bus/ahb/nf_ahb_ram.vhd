--
-- File            :   nf_ahb_ram.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.04.26
-- Language        :   VHDL
-- Description     :   This is AHB RAM module
-- Copyright(c)    :   2019 Vlasov D.V.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
library nf;
use nf.nf_settings.all;
use nf.nf_ahb_pkg.all;
use nf.nf_help_pkg.all;
use nf.nf_components.all;

entity nf_ahb_ram is
    port
    (
        -- clock and reset
        hclk        : in    std_logic;                      -- hclk
        hresetn     : in    std_logic;                      -- hresetn
        -- AHB RAM slave side
        haddr_s     : in    std_logic_vector(31 downto 0);  -- AHB - RAM-slave HADDR
        hwdata_s    : in    std_logic_vector(31 downto 0);  -- AHB - RAM-slave HWDATA
        hrdata_s    : out   std_logic_vector(31 downto 0);  -- AHB - RAM-slave HRDATA
        hwrite_s    : in    std_logic;                      -- AHB - RAM-slave HWRITE
        htrans_s    : in    std_logic_vector(1  downto 0);  -- AHB - RAM-slave HTRANS
        hsize_s     : in    std_logic_vector(2  downto 0);  -- AHB - RAM-slave HSIZE
        hburst_s    : in    std_logic_vector(2  downto 0);  -- AHB - RAM-slave HBURST
        hresp_s     : out   std_logic_vector(1  downto 0);  -- AHB - RAM-slave HRESP
        hready_s    : out   std_logic;                      -- AHB - RAM-slave HREADYOUT
        hsel_s      : in    std_logic;                      -- AHB - RAM-slave HSEL
        -- RAM side
        ram_addr    : out   std_logic_vector(31 downto 0);  -- addr memory
        ram_wd      : out   std_logic_vector(31 downto 0);  -- write data
        ram_rd      : in    std_logic_vector(31 downto 0);  -- read data
        ram_we      : out   std_logic_vector(3  downto 0)   -- write enable
    );
end nf_ahb_ram;

architecture rtl of nf_ahb_ram is
    -- wires 
    signal ram_request  : std_logic_vector(0  downto 0);    -- ram request
    signal ram_wrequest : std_logic_vector(0  downto 0);    -- ram write request
    signal ram_addr_i   : std_logic_vector(31 downto 0);    -- ram address
    signal ram_we_i     : std_logic_vector(0  downto 0);    -- ram write enable
    signal hsize_s_ff   : std_logic_vector(2  downto 0);    -- hsize flip-flop

    signal hready_s_i   : std_logic_vector(0  downto 0);    -- hready_s internal
begin

    ram_addr <= ram_addr_i;
    ram_wd   <= hwdata_s;
    hrdata_s <= ram_rd;
    hresp_s  <= AHB_HRESP_OKAY;
    hready_s <= hready_s_i(0);
    ram_request  <= sl2slv( hsel_s and bool2sl( htrans_s /= AHB_HTRANS_IDLE) );
    ram_wrequest <= ram_request and sl2slv(hwrite_s);

    -- finding write enable for ram
    ram_we(0) <= '1' when ( ( ( hsize_s_ff = AHB_HSIZE_W ) or 
                ( ( hsize_s_ff = AHB_HSIZE_HW ) and ( ram_addr_i(1 downto 0) = "00" ) ) or 
                ( ( hsize_s_ff = AHB_HSIZE_B  ) and ( ram_addr_i(1 downto 0) = "00" ) ) ) and
                ( ram_we_i = "1" ) ) else '0';
    -- finding write enable for ram
    ram_we(1) <= '1' when ( ( ( hsize_s_ff = AHB_HSIZE_W ) or 
                ( ( hsize_s_ff = AHB_HSIZE_HW ) and ( ram_addr_i(1 downto 0) = "00" ) ) or 
                ( ( hsize_s_ff = AHB_HSIZE_B  ) and ( ram_addr_i(1 downto 0) = "01" ) ) ) and
                ( ram_we_i = "1" ) ) else '0';
    -- finding write enable for ram
    ram_we(2) <= '1' when ( ( ( hsize_s_ff = AHB_HSIZE_W ) or 
                ( ( hsize_s_ff = AHB_HSIZE_HW ) and ( ram_addr_i(1 downto 0) = "10" ) ) or 
                ( ( hsize_s_ff = AHB_HSIZE_B  ) and ( ram_addr_i(1 downto 0) = "10" ) ) ) and
                ( ram_we_i = "1" ) ) else '0';
    -- finding write enable for ram
    ram_we(3) <= '1' when ( ( ( hsize_s_ff = AHB_HSIZE_W ) or 
                ( ( hsize_s_ff = AHB_HSIZE_HW ) and ( ram_addr_i(1 downto 0) = "10" ) ) or 
                ( ( hsize_s_ff = AHB_HSIZE_B  ) and ( ram_addr_i(1 downto 0) = "11" ) ) ) and
                ( ram_we_i = "1" ) ) else '0';

    -- creating control and address registers
    ram_addr_ff : nf_register_we generic map( 32 ) port map ( hclk, hresetn, ram_request(0) , haddr_s, ram_addr_i );
    ram_wreq_ff : nf_register    generic map(  1 ) port map ( hclk, hresetn, ram_wrequest , ram_we_i   );
    hready_ff   : nf_register    generic map(  1 ) port map ( hclk, hresetn, ram_request  , hready_s_i );
    hsize_ff    : nf_register    generic map(  3 ) port map ( hclk, hresetn, hsize_s      , hsize_s_ff );

end rtl; -- nf_ahb_ram
