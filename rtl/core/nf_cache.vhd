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
        we_d    : in    std_logic;                      -- write enable
        size_d  : in    std_logic_vector(1  downto 0);  
        we_tv   : in    std_logic;
        wd      : in    std_logic_vector(31 downto 0);  -- write data
        wv      : in    std_logic;                      -- write valid
        rd      : out   std_logic_vector(31 downto 0);  -- read data
        hit     : out   std_logic
    );
end nf_cache;

architecture rtl of nf_cache is

    constant tag_v_size : integer := 32 + 1 - addr_w - 2;
    constant index_size : integer := addr_w;

    signal we_de        : std_logic_vector(3 downto 0);
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
    cache_tv    <= ( wv & waddr(31 downto addr_w+2) );

    -- finding write enable for ram
    we_de(0) <= '1' when ( ( ( size_d = "10" ) or 
                ( ( size_d = "01" ) and ( waddr(1 downto 0) = "00" ) ) or 
                ( ( size_d = "00"  ) and ( waddr(1 downto 0) = "00" ) ) ) and
                ( we_d = '1' ) ) else '0';
    -- finding write enable for ram
    we_de(1) <= '1' when ( ( ( size_d = "10" ) or 
                ( ( size_d = "01" ) and ( waddr(1 downto 0) = "00" ) ) or 
                ( ( size_d = "00"  ) and ( waddr(1 downto 0) = "01" ) ) ) and
                ( we_d = '1' ) ) else '0';
    -- finding write enable for ram
    we_de(2) <= '1' when ( ( ( size_d = "10" ) or 
                ( ( size_d = "01" ) and ( waddr(1 downto 0) = "10" ) ) or 
                ( ( size_d = "00"  ) and ( waddr(1 downto 0) = "10" ) ) ) and
                ( we_d = '1' ) ) else '0';
    -- finding write enable for ram
    we_de(3) <= '1' when ( ( ( size_d = "10" ) or 
                ( ( size_d = "01" ) and ( waddr(1 downto 0) = "10" ) ) or 
                ( ( size_d = "00"  ) and ( waddr(1 downto 0) = "11" ) ) ) and
                ( we_d = '1' ) ) else '0';

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
        we      => we_de(0),                    -- write enable
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
        we      => we_de(1),                    -- write enable
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
        we      => we_de(2),                    -- write enable
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
        we      => we_de(3),                    -- write enable
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
        we      => we_tv,                       -- write enable
        wd      => cache_tv,                    -- write data
        rd      => cache_tag_v                  -- read data
    );

end rtl; -- nf_cache
