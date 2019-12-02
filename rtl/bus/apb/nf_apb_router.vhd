--
-- File            :   nf_apb_router.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.11.29
-- Language        :   VHDL
-- Description     :   This is APB router module
-- Copyright(c)    :   2019 Vlasov D.V.
--

library ieee;
use ieee.std_logic_1164.all;
library nf;
use nf.nf_settings.all;
use nf.nf_components.all;

entity nf_apb_router is
    generic
    (
        apb_slave_c : integer := 2;
        apb_addr_w  : integer := 8
    );
    port
    (
        pclk        : in    std_logic;                                                      -- pclk
        presetn     : in    std_logic;                                                      -- presetn
        -- Master side
        paddr_m     : in    std_logic_vector(apb_addr_w-1 downto 0);                        -- APB - master PADDR
        pwdata_m    : in    std_logic_vector(31 downto 0);                                  -- APB - master PWDATA
        prdata_m    : out   std_logic_vector(31 downto 0);                                  -- APB - master PRDATA
        pwrite_m    : in    std_logic;                                                      -- APB - master PWRITE
        penable_m   : in    std_logic;                                                      -- APB - master PENABLE
        pready_m    : out   std_logic;                                                      -- APB - master PREADY
        psel_m      : in    std_logic;                                                      -- APB - master PSEL
        -- Slaves side
        paddr_s     : out   logic_v_array(apb_slave_c-1 downto 0)(apb_addr_w-1 downto 0);   -- APB - slave PADDR
        pwdata_s    : out   logic_v_array(apb_slave_c-1 downto 0)(31 downto 0);             -- APB - slave PWDATA
        prdata_s    : in    logic_v_array(apb_slave_c-1 downto 0)(31 downto 0);             -- APB - slave PRDATA
        pwrite_s    : out   logic_array  (apb_slave_c-1 downto 0);                          -- APB - slave PWRITE
        penable_s   : out   logic_array  (apb_slave_c-1 downto 0);                          -- APB - slave PENABLE
        pready_s    : in    logic_array  (apb_slave_c-1 downto 0);                          -- APB - slave PREADY
        psel_s      : out   logic_array  (apb_slave_c-1 downto 0);                          -- APB - slave PSEL
        --
        bus_error   : out   std_logic
    );
end nf_apb_router;

architecture rtl of nf_apb_router is
begin

    -- generating wires for all slaves
    apb_wires_gen:
    for i in 0 to apb_slave_c-1 generate
        paddr_s  (i) <= paddr_m;
        pwdata_s (i) <= pwdata_m;
        pwrite_s (i) <= pwrite_m;
        penable_s(i) <= penable_m;
    end generate apb_wires_gen;

    -- creating one APB multiplexer module
    nf_apb_mux_0 : nf_apb_mux
    generic map
    (
        apb_slave_c => apb_slave_c,
        apb_addr_w  => apb_addr_w
    )
    port map
    (
        -- clock and reset
        pclk        => pclk,        -- pclock
        presetn     => presetn,     -- presetn
        -- APB master side
        paddr_m     => paddr_m,     -- APB - master PADDR
        prdata_m    => prdata_m,    -- APB - master PRDATA
        pready_m    => pready_m,    -- APB - master PREADY
        psel_m      => psel_m,      -- APB - master PSEL
        -- APB slave side
        prdata_s    => prdata_s,    -- APB - slave PRDATA
        psel_s      => psel_s,      -- APB - slave PSEL
        pready_s    => pready_s,    -- APB - slave PREADY
        --
        bus_error   => bus_error
    );

end rtl; -- nf_apb_router
