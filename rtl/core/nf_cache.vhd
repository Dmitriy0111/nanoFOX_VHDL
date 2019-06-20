--
-- File            :   nf_cache.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.06.19
-- Language        :   VHDL
-- Description     :   This is cache memory
-- Copyright(c)    :   2019 Vlasov D.V.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use std.standard.boolean;
library nf;
use nf.nf_mem_pkg.all;

entity nf_cache is
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
end nf_cache;

architecture rtl of nf_cache is

    constant tag_v_size : integer := 32 + 1 - addr_w - 2;
    constant index_size : integer := addr_w;

    signal addr_tag     : std_logic_vector(tag_v_size-2 downto 0);
    signal raddr_cache  : std_logic_vector(addr_w-1 downto 0);
    signal waddr_cache  : std_logic_vector(addr_w-1 downto 0);
    signal cache_tag    : std_logic_vector(tag_v_size-2 downto 0);
    signal cache_v      : std_logic;
    signal cache_tag_v  : std_logic_vector(tag_v_size-1 downto 0);
    signal cache_tv     : std_logic_vector(tag_v_size-1 downto 0);

    component nf_param_mem
        generic
        (
            addr_w  : integer := 6;                                 -- actual address memory width
            data_w  : integer := 32;                                -- actual data width
            depth   : integer := 2 ** 6                             -- depth of memory array
        );
        port 
        (
            clk     : in    std_logic;                              -- clock
            waddr   : in    std_logic_vector(addr_w-1 downto 0);    -- write address
            raddr   : in    std_logic_vector(addr_w-1 downto 0);    -- read address
            we      : in    std_logic;                              -- write enable
            wd      : in    std_logic_vector(data_w-1 downto 0);    -- write data
            rd      : out   std_logic_vector(data_w-1 downto 0)     -- read data
        );
    end component;
begin

    waddr_cache <= waddr(addr_w+2-1 downto 2);
    raddr_cache <= raddr(addr_w+2-1 downto 2);
    cache_tag   <= cache_tag_v(tag_v_size-2 downto 0);
    cache_v     <= cache_tag_v(tag_v_size-1);
    addr_tag    <= raddr(31 downto addr_w+2);
    cache_tv    <= ( vld & wtag );

    hit <= '1' when ( ( cache_v = '1' ) and ( cache_tag = addr_tag ) ) else '0';
    -- creating cache bank 0
    cache_b0 : nf_param_mem
    generic map
    (
        addr_w  => addr_w,                      -- actual address memory width
        data_w  => 8,                           -- actual data width
        depth   => depth                        -- depth of memory array
    )
    port map
    (
        clk     => clk,                         -- clock
        waddr   => waddr_cache,                 -- write address
        raddr   => raddr_cache,                 -- read address
        we      => we_cb(0),                    -- write enable
        wd      => wd(7  downto  0),            -- write data
        rd      => rd(7  downto  0)             -- read data
    );
    -- creating cache bank 1
    cache_b1 : nf_param_mem
    generic map
    (
        addr_w  => addr_w,                      -- actual address memory width
        data_w  => 8,                           -- actual data width
        depth   => depth                        -- depth of memory array
    )
    port map
    (
        clk     => clk,                         -- clock
        waddr   => waddr_cache,                 -- write address
        raddr   => raddr_cache,                 -- read address
        we      => we_cb(1),                    -- write enable
        wd      => wd(15 downto  8),            -- write data
        rd      => rd(15 downto  8)             -- read data
    );
    -- creating cache bank 2
    cache_b2 : nf_param_mem
    generic map
    (
        addr_w  => addr_w,                      -- actual address memory width
        data_w  => 8,                           -- actual data width
        depth   => depth                        -- depth of memory array
    )
    port map
    (
        clk     => clk,                         -- clock
        waddr   => waddr_cache,                 -- write address
        raddr   => raddr_cache,                 -- read address
        we      => we_cb(2),                    -- write enable
        wd      => wd(23 downto 16),            -- write data
        rd      => rd(23 downto 16)             -- read data
    );
    -- creating cache bank 3
    cache_b3 : nf_param_mem
    generic map
    (
        addr_w  => addr_w,                      -- actual address memory width
        data_w  => 8,                           -- actual data width
        depth   => depth                        -- depth of memory array
    )
    port map
    (
        clk     => clk,                         -- clock
        waddr   => waddr_cache,                 -- write address
        raddr   => raddr_cache,                 -- read address
        we      => we_cb(3),                    -- write enable
        wd      => wd(31 downto 24),            -- write data
        rd      => rd(31 downto 24)             -- read data
    );
    -- creating cache tag and valid bank
    cache_tag_valid : nf_param_mem
    generic map
    (
        addr_w  => addr_w,                      -- actual address memory width
        data_w  => tag_v_size,                  -- actual data width
        depth   => depth                        -- depth of memory array
    )
    port map
    (
        clk     => clk,                         -- clock
        waddr   => waddr_cache,                 -- write address
        raddr   => raddr_cache,                 -- read address
        we      => we_ctv,                      -- write enable
        wd      => cache_tv,                    -- write data
        rd      => cache_tag_v                  -- read data
    );

end rtl; -- nf_cache
