--
-- File            :   nf_gpio.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.04.22
-- Language        :   VHDL
-- Description     :   This is GPIO module
-- Copyright(c)    :   2019 Vlasov D.V.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
library nf;
use nf.nf_settings.all;
use nf.nf_components.all;
use nf.nf_help_pkg.all;

entity nf_gpio is
    generic
    (
        gpio_w  : integer := NF_GPIO_WIDTH                      -- width gpio port
    );
    port
    (
        -- clock and reset
        clk     : in    std_logic;                              -- clock
        resetn  : in    std_logic;                              -- reset
        -- nf_router side
        addr    : in    std_logic_vector(31       downto 0);    -- address
        we      : in    std_logic;                              -- write enable
        wd      : in    std_logic_vector(31       downto 0);    -- write data
        rd      : out   std_logic_vector(31       downto 0);    -- read data
        -- gpio_side
        gpi     : in    std_logic_vector(gpio_w-1 downto 0);    -- GPIO input
        gpo     : out   std_logic_vector(gpio_w-1 downto 0);    -- GPIO output
        gpd     : out   std_logic_vector(gpio_w-1 downto 0)     -- GPIO direction
    );
end nf_gpio;

architecture rtl of nf_gpio is
    -- gpio input
    signal gpio_i       : std_logic_vector(gpio_w-1 downto 0);
    -- gpio output
    signal gpio_o       : std_logic_vector(gpio_w-1 downto 0);
    -- gpio direction
    signal gpio_d       : std_logic_vector(gpio_w-1 downto 0);
    -- write enable signals 
    signal gpo_we       : std_logic;
    signal gpio_en      : std_logic_vector(0        downto 0);
    signal gpio_en_we   : std_logic;
    signal gpd_we       : std_logic;
begin
    -- assign inputs/outputs
    gpo    <= gpio_o;
    gpd    <= gpio_d;
    gpio_i <= gpi;
    -- assign write enable signal's
    gpo_we     <= we and bool2sl( addr(3 downto 0) = NF_GPIO_GPO ) and gpio_en(0);
    gpd_we     <= we and bool2sl( addr(3 downto 0) = NF_GPIO_DIR ) and gpio_en(0);
    gpio_en_we <= we and bool2sl( addr(3 downto 0) = NF_GPIO_EN  );

    -- mux for routing one register value
    mux_out : process(all)
    begin
        rd <= (31 downto gpio_w => '0') & gpio_i;
        case( addr(3 downto 0) ) is
            when NF_GPIO_GPI    => rd <= (31 downto gpio_w => '0') & gpio_i;
            when NF_GPIO_GPO    => rd <= (31 downto gpio_w => '0') & gpio_o;
            when NF_GPIO_DIR    => rd <= (31 downto gpio_w => '0') & gpio_d;
            when NF_GPIO_EN     => rd <= (31 downto 1      => '0') & gpio_en;
            when others         =>
        end case;
    end process;

    gpio_en_ff : nf_register_we generic map( 1      ) port map ( clk, resetn, gpio_en_we, wd(0        downto 0), gpio_en );
    gpio_o_ff  : nf_register_we generic map( gpio_w ) port map ( clk, resetn, gpo_we,     wd(gpio_w-1 downto 0), gpio_o  );
    gpio_d_ff  : nf_register_we generic map( gpio_w ) port map ( clk, resetn, gpd_we,     wd(gpio_w-1 downto 0), gpio_d  );

end rtl; -- nf_gpio
