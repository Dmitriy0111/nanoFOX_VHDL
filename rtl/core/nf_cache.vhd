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
use nf.nf_components.all;

entity nf_cache is
    generic
    (
        addr_w  : integer := 6;                                 -- actual address memory width
        depth   : integer := 2 ** 6;                            -- depth of memory array
        tag_w   : integer := 6                                  -- tag width
    );
    port
    (
        clk     : in    std_logic;                              -- clock
        raddr   : in    std_logic_vector(31      downto 0);     -- read address
        waddr   : in    std_logic_vector(31      downto 0);     -- write address
        we_cb   : in    std_logic_vector(3       downto 0);     -- write cache enable
        we_ctv  : in    std_logic;                              -- write tag valid enable
        wd      : in    std_logic_vector(31      downto 0);     -- write data
        vld     : in    std_logic_vector(3       downto 0);     -- write valid
        wtag    : in    std_logic_vector(tag_w-1 downto 0);     -- write tag
        rd      : out   std_logic_vector(31      downto 0);     -- read data
        hit     : out   std_logic_vector(3       downto 0)      -- cache hit
    );
end nf_cache;

architecture rtl of nf_cache is

    signal addr_tag     : std_logic_vector(31-(addr_w+2) downto 0);     -- tag address for comparing
    signal raddr_cache  : std_logic_vector(addr_w-1      downto 0);     -- read cache address
    signal waddr_cache  : std_logic_vector(addr_w-1      downto 0);     -- write cache address
    signal cache_tag    : std_logic_vector(tag_w-1       downto 0);     -- cache tag field
    signal cache_v      : std_logic_vector(3             downto 0);     -- cache valid field
    signal cache_tv_r   : std_logic_vector(tag_w-1+4     downto 0);     -- cache tag valid fields read data
    signal cache_tv_w   : std_logic_vector(tag_w-1+4     downto 0);     -- cache tag valid fields write data
    signal addr_eq      : std_logic;                                    -- address equal
    signal rd_i         : std_logic_vector(31            downto 0);

    signal cache_f      : mem_t(2**(addr_w+2)-1 downto 0)(7 downto 0);

begin

    waddr_cache <= waddr(addr_w+2-1 downto 2);          -- finding write cache address
    raddr_cache <= raddr(addr_w+2-1 downto 2);          -- finding read cache address
    addr_tag    <= raddr(31 downto addr_w+2);           -- finding read address tag field
    cache_tag   <= cache_tv_r(tag_w-1   downto 0);      -- finding cache tag field
    cache_v     <= cache_tv_r(tag_w+4-1 downto tag_w);  -- finding cache valid field
    cache_tv_w  <= ( vld & wtag );                      -- finding value write data for tag and valid cache fields

    addr_eq <= '1' when ( ( ( 31-(tag_w+addr_w+2) downto 0 => '0' ) & cache_tag ) = addr_tag ) else '0';    -- finding address equality

    hit(0) <= '1' when ( cache_v(0) and addr_eq ) else '0';   -- finding hit value for bank 0
    hit(1) <= '1' when ( cache_v(1) and addr_eq ) else '0';   -- finding hit value for bank 1
    hit(2) <= '1' when ( cache_v(2) and addr_eq ) else '0';   -- finding hit value for bank 2
    hit(3) <= '1' when ( cache_v(3) and addr_eq ) else '0';   -- finding hit value for bank 3

    rd(7  downto  0) <= wd(7  downto  0) when ( (waddr = raddr) and ( we_cb(0) = '1' ) ) else rd_i(7  downto  0);
    rd(15 downto  8) <= wd(15 downto  8) when ( (waddr = raddr) and ( we_cb(1) = '1' ) ) else rd_i(15 downto  8);
    rd(23 downto 16) <= wd(23 downto 16) when ( (waddr = raddr) and ( we_cb(2) = '1' ) ) else rd_i(23 downto 16);
    rd(31 downto 24) <= wd(31 downto 24) when ( (waddr = raddr) and ( we_cb(3) = '1' ) ) else rd_i(31 downto 24);

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
        rd      => rd_i(7  downto  0)             -- read data
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
        rd      => rd_i(15 downto  8)             -- read data
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
        rd      => rd_i(23 downto 16)             -- read data
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
        rd      => rd_i(31 downto 24)             -- read data
    );
    -- creating cache tag and valid bank
    cache_tag_valid : nf_param_mem
    generic map
    (
        addr_w  => addr_w,                      -- actual address memory width
        data_w  => tag_w+4,                     -- actual data width
        depth   => depth                        -- depth of memory array
    )
    port map
    (
        clk     => clk,                         -- clock
        waddr   => waddr_cache,                 -- write address
        raddr   => raddr_cache,                 -- read address
        we      => we_ctv,                      -- write enable
        wd      => cache_tv_w,                  -- write data
        rd      => cache_tv_r                   -- read data
    );

    -- for verification
    -- synthesis translate_off

    full_cache_mem_write_proc : process( clk )
    begin
        if( rising_edge(clk) ) then
            if( we_cb(3) ) then
                cache_f( to_integer( unsigned( (waddr_cache & "00") + 3 ) ) ) <= wd(31 downto 24);
            end if;
            if( we_cb(2) ) then
                cache_f( to_integer( unsigned( (waddr_cache & "00") + 2 ) ) ) <= wd(23 downto 16);
            end if;
            if( we_cb(1) ) then
                cache_f( to_integer( unsigned( (waddr_cache & "00") + 1 ) ) ) <= wd(15 downto  8);
            end if;
            if( we_cb(0) ) then
                cache_f( to_integer( unsigned( (waddr_cache & "00") + 0 ) ) ) <= wd(7  downto  0);
            end if;
        end if;
    end process;

    -- synthesis translate_on

end rtl; -- nf_cache
