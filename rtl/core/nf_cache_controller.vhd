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

entity nf_cache_controller is
    generic
    (
        addr_w  : integer := 6;                         -- actual address memory width
        depth   : integer := 2 ** 6                     -- depth of memory array
    );
    port 
    (
        clk     : in    std_logic;                      -- clock
        raddr   : in    std_logic_vector(31 downto 0);  -- address
        waddr   : in    std_logic_vector(31 downto 0);  -- address
        swe     : in    std_logic;                      -- store write enable
        lwe     : in    std_logic;                      -- load write enable
        req_l   : in    std_logic;                      -- requets load
        size_d  : in    std_logic_vector(1  downto 0);  -- data size
        sd      : in    std_logic_vector(31 downto 0);  -- store data
        ld      : in    std_logic_vector(31 downto 0);  -- load data
        rd      : out   std_logic_vector(31 downto 0);  -- read data
        hit     : out   std_logic
    );
end nf_cache_controller;

architecture rtl of nf_cache_controller is

    constant tag_v_size : integer := 32 + 1 - addr_w - 2;
    constant index_size : integer := addr_w;

    signal we_ctv       : std_logic;
    signal vld          : std_logic;
    signal wtag         : std_logic_vector(31 - addr_w - 2 downto 0);
    signal we_cb        : std_logic_vector(3  downto 0);
    signal wd_sl        : std_logic_vector(31 downto 0);
    signal hit_i        : std_logic;

    component nf_cache
        generic
        (
            addr_w  : integer := 6;                         -- actual address memory width
            depth   : integer := 2 ** 6                     -- depth of memory array
        );
        port 
        (
            clk     : in    std_logic;                      -- clock
            raddr   : in    std_logic_vector(31 downto 0);  -- address
            waddr   : in    std_logic_vector(31 downto 0);  -- address
            we_cb   : in    std_logic_vector(3  downto 0);  -- write cache enable
            we_ctv  : in    std_logic;                      -- write tag valid enable
            wd      : in    std_logic_vector(31 downto 0);  -- write data
            vld     : in    std_logic;                      -- valid
            wtag    : in    std_logic_vector(31 - addr_w - 2 downto 0);
            rd      : out   std_logic_vector(31 downto 0);  -- read data
            hit     : out   std_logic                       -- cache hit
        );
    end component;
begin

    we_ctv <= '1' when ( ( swe = '1' ) or ( ( lwe and not hit_i and req_l ) = '1' ) ) else '0';
    vld    <= '1' when ( ( swe = '1' ) or ( ( lwe and not hit_i and req_l ) = '1' ) ) else '0';
    hit    <= hit_i;

    -- finding write enable for ram
    we_cb(0) <= '1' when ( ( ( size_d = "10" ) or 
                ( ( size_d = "01" ) and ( waddr(1 downto 0) = "00" ) ) or 
                ( ( size_d = "00"  ) and ( waddr(1 downto 0) = "00" ) ) ) and
                ( ( swe = '1' ) or ( ( lwe and not hit_i and req_l ) = '1' ) ) ) else '0';
    -- finding write enable for ram
    we_cb(1) <= '1' when ( ( ( size_d = "10" ) or 
                ( ( size_d = "01" ) and ( waddr(1 downto 0) = "00" ) ) or 
                ( ( size_d = "00"  ) and ( waddr(1 downto 0) = "01" ) ) ) and
                ( ( swe = '1' ) or ( ( lwe and not hit_i and req_l ) = '1' ) ) ) else '0';
    -- finding write enable for ram
    we_cb(2) <= '1' when ( ( ( size_d = "10" ) or 
                ( ( size_d = "01" ) and ( waddr(1 downto 0) = "10" ) ) or 
                ( ( size_d = "00"  ) and ( waddr(1 downto 0) = "10" ) ) ) and
                ( ( swe = '1' ) or ( ( lwe and not hit_i and req_l ) = '1' ) ) ) else '0';
    -- finding write enable for ram
    we_cb(3) <= '1' when ( ( ( size_d = "10" ) or 
                ( ( size_d = "01" ) and ( waddr(1 downto 0) = "10" ) ) or 
                ( ( size_d = "00"  ) and ( waddr(1 downto 0) = "11" ) ) ) and
                ( ( swe = '1' ) or ( ( lwe and not hit_i and req_l ) = '1' ) ) ) else '0';

    wd_sl <= ld when ( ( lwe and not hit_i and req_l ) = '1' ) else sd;
    wtag  <= raddr(31 downto addr_w+2) when ( ( lwe and not hit_i and req_l ) = '1' ) else waddr(31 downto addr_w+2);

    nf_cache_0 : nf_cache
    generic map
    (
        addr_w  => 6,           -- actual address memory width
        depth   => 2 ** 6       -- depth of memory array
    )
    port map
    (
        clk     => clk,         -- clock
        raddr   => raddr,       -- address
        waddr   => waddr,       -- address
        we_cb   => we_cb,       -- write enable
        we_ctv  => we_ctv,      -- write tag valid enable
        wd      => wd_sl,       -- write data
        vld     => vld,         -- valid
        wtag    => wtag,        -- write tag
        rd      => rd,          -- read data
        hit     => hit_i          -- cache hit
    );

end rtl; -- nf_cache_controller
