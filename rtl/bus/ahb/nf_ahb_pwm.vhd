--
-- File            :   nf_ahb_pwm.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.04.26
-- Language        :   VHDL
-- Description     :   This is AHB PWM module
-- Copyright(c)    :   2019 Vlasov D.V.
--

library ieee;
use ieee.std_logic_1164.all;
library nf;
use nf.nf_settings.all;
use nf.nf_ahb_pkg.all;
use nf.nf_help_pkg.all;
use nf.nf_components.all;

entity nf_ahb_pwm is
    generic
    (
        pwm_width   : integer := 8
    );
    port
    (
        -- clock and reset
        hclk        : in    std_logic;                      -- hclk
        hresetn     : in    std_logic;                      -- hresetn
        -- AHB PWM slave side
        haddr_s     : in    std_logic_vector(31 downto 0);  -- AHB - PWM-slave HADDR
        hwdata_s    : in    std_logic_vector(31 downto 0);  -- AHB - PWM-slave HWDATA
        hrdata_s    : out   std_logic_vector(31 downto 0);  -- AHB - PWM-slave HRDATA
        hwrite_s    : in    std_logic;                      -- AHB - PWM-slave HWRITE
        htrans_s    : in    std_logic_vector(1  downto 0);  -- AHB - PWM-slave HTRANS
        hsize_s     : in    std_logic_vector(2  downto 0);  -- AHB - PWM-slave HSIZE
        hburst_s    : in    std_logic_vector(2  downto 0);  -- AHB - PWM-slave HBURST
        hresp_s     : out   std_logic_vector(1  downto 0);  -- AHB - PWM-slave HRESP
        hready_s    : out   std_logic;                      -- AHB - PWM-slave HREADYOUT
        hsel_s      : in    std_logic;                      -- AHB - PWM-slave HSEL
        -- PWM side
        pwm_clk     : in    std_logic;                      -- PWM_clk
        pwm_resetn  : in    std_logic;                      -- PWM_resetn
        pwm         : out   std_logic                       -- PWM output signal
    );
end nf_ahb_pwm;

architecture rtl of nf_ahb_pwm is
    -- wires 
    signal pwm_request  : std_logic_vector(0  downto 0);    -- pwm request
    signal pwm_wrequest : std_logic_vector(0  downto 0);    -- pwm write request
    signal pwm_addr     : std_logic_vector(31 downto 0);    -- pwm address
    signal pwm_we       : std_logic_vector(0  downto 0);    -- pwm write enable

    signal addr         : std_logic_vector(31 downto 0);    -- address for pwm module
    signal rd           : std_logic_vector(31 downto 0);    -- read data from pwm module
    signal wd           : std_logic_vector(31 downto 0);    -- write data for pwm module
    signal we           : std_logic;                        -- write enable for pwm module

    signal hready_s_i   : std_logic_vector(0  downto 0);    -- hready_s internal
begin

    addr     <= pwm_addr;
    we       <= pwm_we(0);
    wd       <= hwdata_s;
    hrdata_s <= rd;
    hresp_s  <= AHB_HRESP_OKAY;
    hready_s <= hready_s_i(0);
    pwm_request  <= sl2slv( hsel_s and bool2sl( htrans_s /= AHB_HTRANS_IDLE) );
    pwm_wrequest <= pwm_request and sl2slv(hwrite_s);

    -- creating control and address registers
    pwm_addr_ff : nf_register_we generic map( 32 ) port map ( hclk, hresetn, pwm_request(0) , haddr_s, pwm_addr );
    pwm_wreq_ff : nf_register    generic map(  1 ) port map ( hclk, hresetn, pwm_wrequest , pwm_we     );
    hready_ff   : nf_register    generic map(  1 ) port map ( hclk, hresetn, pwm_request  , hready_s_i );
    -- creating one pwm module
    nf_pwm_0 : nf_pwm
    generic map
    (
        pwm_width   => pwm_width
    )
    port map
    (
        -- reset and clock
        clk         => hclk,        -- clk
        resetn      => hresetn,     -- resetn
        -- bus side
        addr        => addr,        -- address
        we          => we,          -- write enable
        wd          => wd,          -- write data
        rd          => rd,          -- read data
        -- pmw_side
        pwm_clk     => pwm_clk,     -- PWM clock in
        pwm_resetn  => pwm_resetn,  -- PWM reset in
        pwm         => pwm          -- PWM out signal
    );

end rtl; -- nf_ahb_pwm
