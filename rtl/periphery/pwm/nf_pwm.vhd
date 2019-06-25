--
-- File            :   nf_pwm.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.04.22
-- Language        :   VHDL
-- Description     :   This is PWM module
-- Copyright(c)    :   2019 Vlasov D.V.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
library nf;
use nf.nf_settings.all;

entity nf_pwm is
    generic
    (
        pwm_width   : integer := 8                                  -- width pwm register
    );
    port
    (
        -- clock and reset
        clk         : in    std_logic;                              -- clock
        resetn      : in    std_logic;                              -- reset
        -- nf_router side
        addr        : in    std_logic_vector(31       downto 0);    -- address
        we          : in    std_logic;                              -- write enable
        wd          : in    std_logic_vector(31       downto 0);    -- write data
        rd          : out   std_logic_vector(31       downto 0);    -- read data
        -- pmw_side
        pwm_clk     : in    std_logic;                              -- PWM clock input
        pwm_resetn  : in    std_logic;                              -- PWM reset input
        pwm         : out   std_logic                               -- PWM output signal
    );
end nf_pwm;

architecture rtl of nf_pwm is
    signal pwm_i    : std_logic_vector(pwm_width-1 downto 0);   -- internal counter register
    signal pwm_c    : std_logic_vector(pwm_width-1 downto 0);   -- internal compare register
begin
    
    pwm <= '1' when (pwm_i >= pwm_c) else '0';
    rd  <= (31 downto pwm_width => '0') & pwm_c;

    pwm_i_inc : process( pwm_clk, pwm_resetn )
    begin
        if( not pwm_resetn ) then
            pwm_i <= (others => '0');
        elsif( rising_edge(pwm_clk) ) then
            pwm_i <= pwm_i + 1;
        end if;
    end process;

    pwm_c_set : process( clk, resetn )
    begin
        if( not resetn ) then
            pwm_c <= (others => '0');
        elsif( rising_edge(clk) ) then
            if( we ) then
                pwm_c <= wd(pwm_width-1 downto 0);
            end if;
        end if;
    end process;

end rtl; -- nf_pwm
