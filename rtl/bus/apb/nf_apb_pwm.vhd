--
-- File            :   nf_apb_pwm.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.12.02
-- Language        :   VHDL
-- Description     :   This is APB PWM module
-- Copyright(c)    :   2019 Vlasov D.V.
--

library ieee;
use ieee.std_logic_1164.all;
library nf;
use nf.nf_settings.all;
use nf.nf_ahb_pkg.all;
use nf.nf_help_pkg.all;
use nf.nf_components.all;

entity nf_apb_pwm is
    generic
    (
        pwm_width   : integer := 8;
        apb_addr_w  : integer
    );
    port
    (
        -- clock and reset
        pclk        : in    std_logic;                                  -- pclk
        presetn     : in    std_logic;                                  -- presetn
        -- APB PWM slave side
        paddr_s     : in    std_logic_vector(apb_addr_w-1 downto 0);    -- APB - PWM-slave PADDR
        pwdata_s    : in    std_logic_vector(31           downto 0);    -- APB - PWM-slave PWDATA
        prdata_s    : out   std_logic_vector(31           downto 0);    -- APB - PWM-slave PRDATA
        pwrite_s    : in    std_logic;                                  -- APB - PWM-slave PWRITE
        psel_s      : in    std_logic;                                  -- APB - PWM-slave PSEL
        penable_s   : in    std_logic;                                  -- APB - PWM-slave PENABLE
        pready_s    : out   std_logic;                                  -- APB - PWM-slave PREADY
        -- PWM side
        pwm_clk     : in    std_logic;                                  -- PWM clk
        pwm_resetn  : in    std_logic;                                  -- PWM resetn
        pwm         : out   std_logic                                   -- PWM output signal
    );
end nf_apb_pwm;

architecture rtl of nf_apb_pwm is
    signal pready_ff        : std_logic_vector(0  downto 0);
    signal psel_slv         : std_logic_vector(0  downto 0);

    signal addr             : std_logic_vector(31 downto 0);    -- address for gpio module
    signal rd               : std_logic_vector(31 downto 0);    -- read data from gpio module
    signal wd               : std_logic_vector(31 downto 0);    -- write data for gpio module
    signal we               : std_logic;                        -- write enable for gpio module
begin

    addr     <= ( 31 downto (paddr_s'left+1) => '0' ) & paddr_s;
    we       <= pwrite_s and penable_s and psel_s;
    wd       <= pwdata_s;
    prdata_s <= rd;

    psel_slv(0) <= psel_s;
    pready_s <= pready_ff(0);

    -- creating control and address registers
    pready_reg : nf_register    generic map( 1 ) port map ( pclk, presetn, psel_slv, pready_ff );
    -- creating one pwm module
    nf_pwm_0 : nf_pwm
    generic map
    (
        pwm_width   => pwm_width
    )
    port map
    (
        -- reset and clock
        clk         => pclk,        -- clk
        resetn      => presetn,     -- resetn
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

end rtl; -- nf_apb_pwm
