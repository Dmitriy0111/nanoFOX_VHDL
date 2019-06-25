--
-- File            :   nf_cache_controller.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.06.19
-- Language        :   VHDL
-- Description     :   This is cache memory controller
-- Copyright(c)    :   2019 Vlasov D.V.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use std.standard.boolean;

library nf;
use nf.nf_components.all;

entity nf_cache_controller is
    generic
    (
        addr_w  : integer := 6;                         -- actual address memory width
        depth   : integer := 2 ** 6;                    -- depth of memory array
        tag_w   : integer := 6                          -- tag width
    );
    port
    (
        clk     : in    std_logic;                      -- clock
        raddr   : in    std_logic_vector(31 downto 0);  -- read address
        waddr   : in    std_logic_vector(31 downto 0);  -- write address
        swe     : in    std_logic;                      -- store write enable
        lwe     : in    std_logic;                      -- load write enable
        req_l   : in    std_logic;                      -- requets load
        size_d  : in    std_logic_vector(1  downto 0);  -- data size
        size_r  : in    std_logic_vector(1  downto 0);  -- read data size
        sd      : in    std_logic_vector(31 downto 0);  -- store data
        ld      : in    std_logic_vector(31 downto 0);  -- load data
        rd      : out   std_logic_vector(31 downto 0);  -- read data
        hit     : out   std_logic                       -- cache hit
    );
end nf_cache_controller;

architecture rtl of nf_cache_controller is

    signal we_ctv       : std_logic;                            -- write enable cache tag and valid
    signal vld          : std_logic_vector(3       downto 0);   -- valid signal
    signal wtag         : std_logic_vector(tag_w-1 downto 0);   -- write tag field
    signal we_cb        : std_logic_vector(3       downto 0);   -- write enable cache bank
    signal wd_sl        : std_logic_vector(31      downto 0);   -- write data store/load
    signal hit_i        : std_logic_vector(3       downto 0);   -- hit internal

    signal byte_en_w    : std_logic_vector(3       downto 0);   -- byte enable for write
    signal byte_en_r    : std_logic_vector(3       downto 0);   -- byte enable for read

begin

    we_ctv <= '1' when ( ( swe = '1' ) or ( ( lwe and req_l ) = '1' ) ) else '0';                   -- finding write enable for tag and valid fields
    vld(0) <= '1' when ( ( ( swe or ( lwe and req_l ) ) and byte_en_w(0) ) or hit_i(0) ) else '0';  -- finding valid value for bank 0
    vld(1) <= '1' when ( ( ( swe or ( lwe and req_l ) ) and byte_en_w(1) ) or hit_i(1) ) else '0';  -- finding valid value for bank 1
    vld(2) <= '1' when ( ( ( swe or ( lwe and req_l ) ) and byte_en_w(2) ) or hit_i(2) ) else '0';  -- finding valid value for bank 2
    vld(3) <= '1' when ( ( ( swe or ( lwe and req_l ) ) and byte_en_w(3) ) or hit_i(3) ) else '0';  -- finding valid value for bank 3
    hit    <=   ( not byte_en_r(0) or hit_i(0) ) and    -- finding resulting hit for bank 0
                ( not byte_en_r(1) or hit_i(1) ) and    -- finding resulting hit for bank 1
                ( not byte_en_r(2) or hit_i(2) ) and    -- finding resulting hit for bank 2
                ( not byte_en_r(3) or hit_i(3) ) and    -- finding resulting hit for bank 3
                '1';
    -- byte enable for write operations
    byte_en_w(0) <= '1' when 
                        ( ( size_d = "10" ) or                                      -- word
                        ( ( size_d = "01" ) and ( waddr(1 downto 0) = "00" ) ) or   -- half word
                        ( ( size_d = "00" ) and ( waddr(1 downto 0) = "00" ) ) )    -- byte
                    else '0';

    byte_en_w(1) <= '1' when 
                        ( ( size_d = "10" ) or                                      -- word
                        ( ( size_d = "01" ) and ( waddr(1 downto 0) = "00" ) ) or   -- half word
                        ( ( size_d = "00" ) and ( waddr(1 downto 0) = "01" ) ) )    -- byte
                    else '0';

    byte_en_w(2) <= '1' when 
                        ( ( size_d = "10" ) or                                      -- word
                        ( ( size_d = "01" ) and ( waddr(1 downto 0) = "10" ) ) or   -- half word
                        ( ( size_d = "00" ) and ( waddr(1 downto 0) = "10" ) ) )    -- byte
                    else '0';

    byte_en_w(3) <= '1' when 
                        ( ( size_d = "10" ) or                                      -- word
                        ( ( size_d = "01" ) and ( waddr(1 downto 0) = "10" ) ) or   -- half word
                        ( ( size_d = "00" ) and ( waddr(1 downto 0) = "11" ) ) )    -- byte
                    else '0';
    -- byte enable for read operations
    byte_en_r(0) <= '1' when 
                        ( ( size_r = "10" ) or                                      -- word
                        ( ( size_r = "01" ) and ( raddr(1 downto 0) = "00" ) ) or   -- half word
                        ( ( size_r = "00" ) and ( raddr(1 downto 0) = "00" ) ) )    -- byte
                    else '0';

    byte_en_r(1) <= '1' when 
                        ( ( size_r = "10" ) or                                      -- word
                        ( ( size_r = "01" ) and ( raddr(1 downto 0) = "00" ) ) or   -- half word
                        ( ( size_r = "00" ) and ( raddr(1 downto 0) = "01" ) ) )    -- byte
                    else '0';

    byte_en_r(2) <= '1' when 
                        ( ( size_r = "10" ) or                                      -- word
                        ( ( size_r = "01" ) and ( raddr(1 downto 0) = "10" ) ) or   -- half word
                        ( ( size_r = "00" ) and ( raddr(1 downto 0) = "10" ) ) )    -- byte
                    else '0';

    byte_en_r(3) <= '1' when 
                        ( ( size_r = "10" ) or                                      -- word
                        ( ( size_r = "01" ) and ( raddr(1 downto 0) = "10" ) ) or   -- half word
                        ( ( size_r = "00" ) and ( raddr(1 downto 0) = "11" ) ) )    -- byte
                    else '0';

    -- finding write enable cache bank 0
    we_cb(0) <= '1' when ( byte_en_w(0) and
                ( swe or ( lwe and req_l ) ) ) else '0';
    -- finding write enable cache bank 1
    we_cb(1) <= '1' when ( byte_en_w(1) and
                ( swe or ( lwe and req_l ) ) ) else '0';
    -- finding write enable cache bank 2
    we_cb(2) <= '1' when ( byte_en_w(2) and
                ( swe or ( lwe and req_l ) ) ) else '0';
    -- finding write enable cache bank 3
    we_cb(3) <= '1' when ( byte_en_w(3) and
                ( swe or ( lwe and req_l ) ) ) else '0';

    wd_sl <= ld when ( ( lwe and req_l ) = '1' ) else sd;   -- finding write data store/load
    wtag  <= raddr(tag_w-1+addr_w+2 downto addr_w+2) when ( ( lwe and req_l ) = '1' ) else waddr(tag_w-1+addr_w+2 downto addr_w+2);

    nf_cache_0 : nf_cache
    generic map
    (
        addr_w  => 6,           -- actual address memory width
        depth   => 2 ** 6,      -- depth of memory array
        tag_w   => 6            -- tag width
    )
    port map
    (
        clk     => clk,         -- clock
        raddr   => raddr,       -- read address
        waddr   => waddr,       -- write address
        we_cb   => we_cb,       -- write enable
        we_ctv  => we_ctv,      -- write tag valid enable
        wd      => wd_sl,       -- write data
        vld     => vld,         -- write valid
        wtag    => wtag,        -- write tag
        rd      => rd,          -- read data
        hit     => hit_i        -- cache hit
    );

end rtl; -- nf_cache_controller
