--
-- File            :   nf_ahb2apb_bridge.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.11.29
-- Language        :   VHDL
-- Description     :   This is AHB to APB bridge module
-- Copyright(c)    :   2019 Vlasov D.V.
--

library ieee;
use ieee.std_logic_1164.all;
library nf;
use nf.nf_settings.all;
use nf.nf_components.all;
use nf.nf_help_pkg.all;
use nf.nf_ahb_pkg.all;

entity nf_ahb2apb_bridge is
    generic
    (
        apb_addr_w  : integer := 8;
        cdc_use     : integer := 1
    );
    port
    (
        -- AHB clock and reset
        hclk        : in        std_logic;                                  -- AHB clk
        hresetn     : in        std_logic;                                  -- AHB resetn
        -- AHB - Slave side
        haddr_s     : in        std_logic_vector(31           downto 0);    -- AHB - slave HADDR
        hwdata_s    : in        std_logic_vector(31           downto 0);    -- AHB - slave HWDATA
        hrdata_s    : out       std_logic_vector(31           downto 0);    -- AHB - slave HRDATA
        hwrite_s    : in        std_logic;                                  -- AHB - slave HWRITE
        htrans_s    : in        std_logic_vector(1            downto 0);    -- AHB - slave HTRANS
        hsize_s     : in        std_logic_vector(2            downto 0);    -- AHB - slave HSIZE
        hburst_s    : in        std_logic_vector(2            downto 0);    -- AHB - slave HBURST
        hresp_s     : out       std_logic_vector(1            downto 0);    -- AHB - slave HRESP
        hready_s    : buffer    std_logic;                                  -- AHB - slave HREADYOUT
        hsel_s      : in        std_logic;                                  -- AHB - slave HSEL
        -- APB clock and reset
        pclk        : in        std_logic;                                  -- APB clk
        presetn     : in        std_logic;                                  -- APB resetn
        -- APB - Master side
        paddr_m     : out       std_logic_vector(apb_addr_w-1 downto 0);    -- APB - master PADDR
        pwdata_m    : out       std_logic_vector(31           downto 0);    -- APB - master PWDATA
        prdata_m    : in        std_logic_vector(31           downto 0);    -- APB - master PRDATA
        pwrite_m    : out       std_logic;                                  -- APB - master PWRITE
        penable_m   : out       std_logic;                                  -- APB - master PENABLE
        pready_m    : in        std_logic;                                  -- APB - master PREADY
        psel_m      : out       std_logic                                   -- APB - master PSEL
    );
end nf_ahb2apb_bridge;

architecture rtl of nf_ahb2apb_bridge is
    signal trans_req        : std_logic;
    -- AHB signals
    signal ahb_req          : std_logic;
    signal ahb_ack          : std_logic;
    signal ahb_addr         : std_logic_vector(31           downto 0);
    signal ahb_wd           : std_logic_vector(31           downto 0);
    signal ahb_rd           : std_logic_vector(31           downto 0);
    signal ahb_wr_rd        : std_logic;
    signal ahb_idle2trans   : std_logic;
    signal ahb_trans2idle   : std_logic;
    -- APB signals
    signal apb_req          : std_logic;
    signal apb_ack          : std_logic;
    signal apb_addr         : std_logic_vector(apb_addr_w-1 downto 0);
    signal apb_wd           : std_logic_vector(31           downto 0);
    signal apb_rd           : std_logic_vector(31           downto 0);
    signal apb_wr_rd        : std_logic;
    signal apb_idle2setup   : std_logic;
    signal apb_setup2enable : std_logic;
    signal apb_enable2idle  : std_logic;
    -- apb fsm settings
    type   apb_fsm_state is (APB_IDLE_s , APB_SETUP_s , APB_ENABLE_s);
    attribute enum_encoding : string;
    attribute enum_encoding of apb_fsm_state : type is "one-hot";
    signal apb_state        : apb_fsm_state;                            -- current state of fsm
    signal apb_next_state   : apb_fsm_state;                            -- next state for fsm
    function sel_apb_st(logic_cond : std_logic; st_1 : apb_fsm_state; st_0 : apb_fsm_state) return apb_fsm_state is
        begin
            if logic_cond then
                return st_1;
            else 
                return st_0;
            end if;
    end function;
    -- ahb fsm settings
    type   ahb_fsm_state is (AHB_IDLE_s , AHB_TRANS_s);
    attribute enum_encoding of ahb_fsm_state : type is "one-hot";
    signal ahb_state        : ahb_fsm_state;                            -- current state of fsm
    signal ahb_next_state   : ahb_fsm_state;                            -- next state for fsm
    function sel_ahb_st(logic_cond : std_logic; st_1 : ahb_fsm_state; st_0 : ahb_fsm_state) return ahb_fsm_state is
        begin
            if logic_cond then
                return st_1;
            else 
                return st_0;
            end if;
    end function;
    -- CDC
    signal req_sync : std_logic_vector(2 downto 0);
    signal ack_sync : std_logic_vector(2 downto 0);
begin

    trans_req <= ( hsel_s and bool2sl( htrans_s /= AHB_HTRANS_IDLE) );

    ahb_idle2trans <= trans_req and (not hready_s);
    ahb_trans2idle <= ahb_ack;

    hrdata_s <= ahb_rd;
    ahb_wd <= hwdata_s;
    apb_wd <= ahb_wd;
    apb_addr <= ahb_addr(apb_addr'range);
    apb_wr_rd <= ahb_wr_rd;

    req_ack_gen:
    if with_cdc : (cdc_use = 1) generate
        apb_req <= req_sync(2) xor req_sync(1);
        ahb_ack <= ack_sync(2) xor ack_sync(1);
    else without_cdc : generate
        apb_req <= ahb_req;
        ahb_ack <= apb_ack;
    end generate req_ack_gen;

    apb_idle2setup   <= apb_req;
    apb_setup2enable <= '1';
    apb_enable2idle  <= pready_m;

    hresp_s <= AHB_HRESP_OKAY;

    --------------------------------------------------------------------------------
    --                              AHB statemachine                              --
    --------------------------------------------------------------------------------
    ahb_req_proc : process( hclk )
    begin
        if( rising_edge(hclk) ) then
            if( not hresetn ) then
                ahb_req <= '0';
            else
                ahb_req <= sel_sl( (cdc_use = 1) , ahb_req , '0' );
                if( bool2sl( ahb_state = AHB_IDLE_s ) and ahb_idle2trans ) then
                    ahb_req <= sel_sl( (cdc_use = 1) , not ahb_req , '1' );
                end if;
            end if;
        end if;
    end process ahb_req_proc;

    ack_cdc_proc : process( hclk )
    begin
        if( rising_edge(hclk) ) then
            if( not hresetn ) then
                ack_sync <= (others => '0');
            else
                ack_sync <= ack_sync(1 downto 0) & apb_ack;
            end if;
        end if;
    end process ack_cdc_proc;
   
    -- ahb fsm state change
    ahb_fsm_state_change_proc : process( hclk )
    begin
        if( rising_edge(hclk) ) then
            if( not hresetn ) then
                ahb_state <= AHB_IDLE_s;
            else
                ahb_state <= ahb_next_state;
            end if;
        end if;  
    end process ahb_fsm_state_change_proc;
    -- Finding next state for FSM
    ahb_find_next_state_proc : process(all)
    begin
        ahb_next_state <= ahb_state;
        case( ahb_state ) is
            when AHB_IDLE_s     => ahb_next_state <= sel_ahb_st( ahb_idle2trans , AHB_TRANS_s , ahb_state );
            when AHB_TRANS_s    => ahb_next_state <= sel_ahb_st( ahb_trans2idle , AHB_IDLE_s  , ahb_state );
            when others         => ahb_next_state <= AHB_IDLE_s;
        end case;
    end process ahb_find_next_state_proc;
    -- Other FSM sequence logic
    ahb_fsm_seq_proc : process( hclk )
    begin
        if( rising_edge(hclk) ) then
            if( not hresetn ) then
                ahb_wr_rd <= '0';
                ahb_addr <= (others => '0');
                hready_s <= '0';
            else
                case( ahb_state ) is
                    when AHB_IDLE_s     => 
                        ahb_wr_rd <= hwrite_s;
                        ahb_addr <= haddr_s;
                        hready_s <= '0';
                    when AHB_TRANS_s    => 
                        if( ahb_trans2idle ) then
                            hready_s <= '1';
                            ahb_rd <= apb_rd;
                        end if;
                    when others         =>
                end case;
            end if;
        end if;
    end process ahb_fsm_seq_proc;

    --------------------------------------------------------------------------------
    --                              APB statemachine                              --
    --------------------------------------------------------------------------------

    req_cdc_proc : process( pclk )
    begin
        if( rising_edge(pclk) ) then
            if( not presetn ) then
                req_sync <= (others => '0');
            else
                req_sync <= req_sync(1 downto 0) & ahb_req;
            end if;
        end if;
    end process req_cdc_proc;

    apb_ack_proc : process( pclk )
    begin
        if( rising_edge(pclk) ) then
            if( not presetn ) then
                apb_ack <= '0';
            else
                apb_ack <= sel_sl( (cdc_use = 1) , apb_ack , '0' );
                if( bool2sl( apb_state = APB_ENABLE_s ) and apb_enable2idle ) then
                    apb_ack <= sel_sl( (cdc_use = 1) , not apb_ack , '1' );
                end if;
            end if;
        end if;
    end process apb_ack_proc;
    
    -- apb fsm state change
    apb_fsm_state_change_proc : process( pclk )
    begin
        if( rising_edge(pclk) ) then
            if( not presetn ) then
                apb_state <= APB_IDLE_s;
            else
                apb_state <= apb_next_state;
            end if;
        end if;  
    end process apb_fsm_state_change_proc;
    -- Finding next state for FSM
    apb_find_next_state_proc : process(all)
    begin
        apb_next_state <= apb_state;
        case( apb_state ) is
            when APB_IDLE_s     => apb_next_state <= sel_apb_st( apb_idle2setup   , APB_SETUP_s  , apb_state );
            when APB_SETUP_s    => apb_next_state <= sel_apb_st( apb_setup2enable , APB_ENABLE_s , apb_state );
            when APB_ENABLE_s   => apb_next_state <= sel_apb_st( apb_enable2idle  , APB_IDLE_s   , apb_state );
            when others         => apb_next_state <= APB_IDLE_s;
        end case;
    end process apb_find_next_state_proc;
    -- Other FSM sequence logic
    apb_fsm_seq_proc : process( pclk )
    begin
        if( rising_edge(pclk) ) then
            if( not presetn ) then
                pwdata_m <= (others => '0');
                pwrite_m <= '0';
                paddr_m <= (others => '0');
                penable_m <= '0';
                psel_m <= '0';
            else
                case( apb_state ) is
                    when APB_IDLE_s     => 
                        if( apb_idle2setup ) then
                            psel_m <= '1';
                            penable_m <= '0';
                            pwrite_m <= apb_wr_rd;
                            paddr_m <= apb_addr;
                            pwdata_m <= apb_wd;
                        end if;
                    when APB_SETUP_s    => 
                        penable_m <= '1';
                    when APB_ENABLE_s   => 
                        if( apb_enable2idle ) then
                            penable_m <= '0';
                            psel_m <= '0';
                            apb_rd <= prdata_m;
                        end if;
                    when others         =>
                end case;
            end if;
        end if;
    end process apb_fsm_seq_proc;

end rtl; -- nf_ahb2apb_bridge
