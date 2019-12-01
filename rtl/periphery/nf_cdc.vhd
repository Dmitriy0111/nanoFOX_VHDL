--
-- File            :   nf_cdc.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.04.24
-- Language        :   VHDL
-- Description     :   This is cross domain crossing module
-- Copyright(c)    :   2019 Vlasov D.V.
--

library ieee;
use ieee.std_logic_1164.all;

entity nf_cdc is
    port
    (
        resetn_1    : in   std_logic;   -- first reset
        resetn_2    : in   std_logic;   -- second reset
        clk_1       : in   std_logic;   -- first clock
        clk_2       : in   std_logic;   -- second clock
        we_1        : in   std_logic;   -- first write enable
        we_2        : in   std_logic;   -- second write enable
        data_1_in   : in   std_logic;   -- first data input
        data_2_in   : in   std_logic;   -- second data input
        data_1_out  : out  std_logic;   -- first data output
        data_2_out  : out  std_logic;   -- second data output
        wait_1      : out  std_logic;   -- first wait
        wait_2      : out  std_logic    -- second wait
    );
end nf_cdc;

architecture rtl of nf_cdc is
    signal int_reg1 : std_logic;    -- internal register 1
    signal int_reg2 : std_logic;    -- internal register 2
    signal req_1    : std_logic;    -- request 1
    signal ack_1    : std_logic;    -- request acknowledge 1
    signal req_2    : std_logic;    -- request 2
    signal ack_2    : std_logic;    -- request acknowledge 2
begin

    wait_1 <= req_1 or ack_2;
    wait_2 <= req_2 or ack_1;

    data_1_out <= int_reg1;
    data_2_out <= int_reg2;

    write2first_reg : process( clk_1 )
    begin
        if( rising_edge(clk_1) ) then
            if( not resetn_1 ) then
                int_reg1 <= '0';
            elsif( we_1 ) then
                int_reg1 <= data_1_in;
            elsif( req_2 ) then
                int_reg1 <= int_reg2;
            end if;
        end if;
    end process;

    answer_first : process( clk_1, resetn_1 )
    begin
        if( rising_edge(clk_1) ) then
            if( not resetn_1 ) then
                ack_1 <= '0';
            else
                ack_1 <= req_2;
            end if;
        end if;
    end process;

    request_first : process( clk_1 )
    begin
        if( rising_edge(clk_1) ) then
            if( not resetn_1 ) then
                req_1 <= '0';
            elsif( we_1 ) then
                req_1 <= '1';
            elsif( ack_2 ) then
                req_1 <= '0';
            end if;
        end if;
    end process;

    write2second_reg : process( clk_2 )
    begin
        if( rising_edge(clk_2) ) then
            if( not resetn_2 ) then
                int_reg2 <= '0';
            elsif( we_2 ) then
                int_reg2 <= data_2_in;
            elsif( req_1 ) then
                int_reg2 <= int_reg1;
            end if;
        end if;
    end process;

    answer_second : process( clk_2 )
    begin
        if( rising_edge(clk_2) ) then
            if( not resetn_2 ) then
                ack_2 <= '0';
            else
                ack_2 <= req_1;
            end if;
        end if;
    end process;

    request_second : process( clk_2 )
    begin
        if( rising_edge(clk_2) ) then
            if( not resetn_2 ) then
                req_2 <= '0';
            elsif( we_2 ) then
                req_2 <= '1';
            elsif( ack_1 ) then
                req_2 <= '0';
            end if;
        end if;
    end process;

end rtl; -- nf_cdc
