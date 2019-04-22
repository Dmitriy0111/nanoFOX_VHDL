--
-- File            :   nf_settings.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.04.20
-- Language        :   VHDL
-- Description     :   This is file with common settings
-- Copyright(c)    :   2019 Vlasov D.V.
--

library ieee;
use ieee.std_logic_1164.all;

package nf_settings is
    -- depth of ram module
    constant RAM_DEPTH      : integer := 64;
    -- number of slave device's
    constant SLAVE_NUMBER   : integer := 4;
    -- memory map for devices
    --
    -- 0x0000_0000\
    --             \
    --              RAM
    --             /
    -- 0x0000_ffff/
    -- 0x0001_0000\
    --             \
    --              GPIO
    --             /
    -- 0x0001_ffff/
    -- 0x0002_0000\
    --             \
    --              PWM
    --             /
    -- 0x0002_ffff/
    -- 0x0003_0000\
    --             \
    --              Unused
    --             /
    -- 0xffff_ffff/
    --

    constant NF_RAM_ADDR_MATCH  : std_logic_vector(15 downto 0) := 16X"0000";
    constant NF_GPIO_ADDR_MATCH : std_logic_vector(15 downto 0) := 16X"0001";
    constant NF_PWM_ADDR_MATCH  : std_logic_vector(15 downto 0) := 16X"0002";
    -- constant's for gpio module
    constant NF_GPIO_WIDTH      : integer := 8;
    constant NF_GPIO_GPI        : std_logic_vector(3 downto 0) := 4X"0";
    constant NF_GPIO_GPO        : std_logic_vector(3 downto 0) := 4X"4";
    constant NF_GPIO_DIR        : std_logic_vector(3 downto 0) := 4X"8";

    --
    type    logic_array is array(natural range <>) of std_logic;
    type    logic_v_array is array(natural range <>) of std_logic_vector;
    function slv_2_la(slv : std_logic_vector) return logic_array;

end package nf_settings;

package body nf_settings is

    function slv_2_la(slv : std_logic_vector) 
    return logic_array is
        variable result_l_a : logic_array(slv'length-1 downto 0);
    begin
        for i in 0 to slv'length-1 loop
            result_l_a(i) := slv(i);
        end loop;
        return result_l_a;
    end function;

end package body nf_settings;
