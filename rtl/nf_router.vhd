--
-- File            :   nf_router.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.04.22
-- Language        :   VHDL
-- Description     :   This is unit for routing lw sw command's
-- Copyright(c)    :   2019 Vlasov D.V.
--

library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.nf_settings.all;

entity nf_router is
    generic
    (
        Slave_n : integer := SLAVE_NUMBER
    );
    port 
    (
        -- clock and reset
        clk         : in    std_logic;                                      -- clock
        resetn      : in    std_logic;                                      -- reset
        -- cpu side (master)
        addr_dm_m   : in    std_logic_vector(31 downto 0);                  -- master address
        we_dm_m     : in    std_logic;                                      -- master write enable
        wd_dm_m     : in    std_logic_vector(31 downto 0);                  -- master write data
        rd_dm_m     : out   std_logic_vector(31 downto 0);                  -- master read data
        -- devices side (slave's)
        clk_s       : out   std_logic;                                      -- slave clock
        resetn_s    : out   std_logic;                                      -- slave reset
        addr_dm_s   : out   logic_v_array(Slave_n-1 downto 0)(31 downto 0); -- slave address
        we_dm_s     : out   logic_array  (Slave_n-1 downto 0);              -- slave write enable
        wd_dm_s     : out   logic_v_array(Slave_n-1 downto 0)(31 downto 0); -- slave write data
        rd_dm_s     : in    logic_v_array(Slave_n-1 downto 0)(31 downto 0)  -- slave read data
    );
end nf_router;

architecture rtl of nf_router is
    signal slave_sel : std_logic_vector(Slave_n-1 downto 0);
    -- nf_router_mux
    component nf_router_mux
        generic
        (
            Slave_n     : integer := SLAVE_NUMBER
        );
        port 
        (
            slave_sel   : in    std_logic_vector(Slave_n-1 downto 0);               -- slave select
            rd_s        : in    logic_v_array   (Slave_n-1 downto 0)(31 downto 0);  -- read data array slave
            rd_m        : out   std_logic_vector(31        downto 0)                -- read data master
        );
    end component;
    -- nf_router_dec
    component nf_router_dec
        generic
        (
            Slave_n     : integer := SLAVE_NUMBER
        );
        port 
        (
            addr_m      : in    std_logic_vector(31        downto 0);   -- master address
            slave_sel   : out   std_logic_vector(Slave_n-1 downto 0)    -- slave select
        );
    end component;
begin

    clk_s       <= clk;
    resetn_s    <= resetn;
    wd_dm_s     <= (SLAVE_NUMBER-1 downto 0 => wd_dm_m);
    addr_dm_s   <= (SLAVE_NUMBER-1 downto 0 => addr_dm_m);

    we_dm_s_convertors: 
    for i in 0 to slave_sel'length-1 generate
        we_dm_s(i) <= we_dm_m and slave_sel(i);
    end generate we_dm_s_convertors;
    --we_dm_s     <= slv_2_la( slave_sel );
    --we_dm_s(0)  <= we_dm_m and slave_sel(0);
    --we_dm_s(1)  <= we_dm_m and slave_sel(1);
    --we_dm_s(2)  <= we_dm_m and slave_sel(2);
    --we_dm_s(3)  <= we_dm_m and slave_sel(3);

    -- creating one router decoder
    nf_router_dec_0 : nf_router_dec
    generic map
    (
        Slave_n     => SLAVE_NUMBER
    )
    port map
    (
        addr_m      => addr_dm_m,   -- master address
        slave_sel   => slave_sel    -- slave select
    );
    -- creating one router mux
    nf_router_mux_0 : nf_router_mux
    generic map
    (
        Slave_n     => SLAVE_NUMBER
    )
    port map
    (
        slave_sel   => slave_sel,   -- slave select
        rd_s        => rd_dm_s,     -- read data array slave
        rd_m        => rd_dm_m      -- read data master
    );  

end rtl; -- nf_router
    