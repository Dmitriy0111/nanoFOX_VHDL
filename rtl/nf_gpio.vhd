--
-- File            :   nf_gpio.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.04.22
-- Language        :   VHDL
-- Description     :   This is GPIO module
-- Copyright(c)    :   2019 Vlasov D.V.
--

library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.nf_settings.all;

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
    signal gpio_i   : std_logic_vector(gpio_w-1 downto 0);
    -- gpio output
    signal gpio_o   : std_logic_vector(gpio_w-1 downto 0);
    -- gpio direction
    signal gpio_d   : std_logic_vector(gpio_w-1 downto 0);
    -- write enable signals 
    signal gpo_we   : std_logic;
    signal gpd_we   : std_logic;
    signal gpo_we_h : std_logic;
    signal gpd_we_h : std_logic;
begin
    -- assign inputs/outputs
    gpo    <= gpio_o;
    gpd    <= gpio_d;
    gpio_i <= gpi;
    -- assign write enable signal's
    gpo_we_h <= '1' when (addr(3 downto 0) = NF_GPIO_GPO) else '0'; 
    gpo_we   <= we and gpo_we_h; 
    gpd_we_h <= '1' when (addr(3 downto 0) = NF_GPIO_DIR) else '0'; 
    gpd_we   <= we and gpd_we_h; 

    -- mux for routing one register value
    mux_out : process(all)
    begin
        rd <= (31 downto gpio_w => '0') & gpio_i;
        case( addr(3 downto 0) ) is
            when NF_GPIO_GPI    => rd <= (31 downto gpio_w => '0') & gpio_i;
            when NF_GPIO_GPO    => rd <= (31 downto gpio_w => '0') & gpio_o;
            when NF_GPIO_DIR    => rd <= (31 downto gpio_w => '0') & gpio_d;
            when others         =>
        end case;
    end process;

    gpo_set : process(all)
    begin
        if( not resetn ) then
            gpio_o <= (others => '0');
        elsif( rising_edge(clk) ) then
            if( gpo_we ) then
                gpio_o <= wd(gpio_w-1 downto 0);
            end if;
        end if;
    end process;

    gpd_set : process(all)
    begin
        if( not resetn ) then
            gpio_d <= (others => '0');
        elsif( rising_edge(clk) ) then
            if( gpd_we ) then
                gpio_d <= wd(gpio_w-1 downto 0);
            end if;
        end if;
    end process;

end rtl; -- nf_gpio
