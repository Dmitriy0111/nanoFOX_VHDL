--
-- File            :   nf_uart_top.sv
-- Autor           :   Vlasov D.V.
-- Data            :   2019.02.21
-- Language        :   SystemVerilog
-- Description     :   This uart top module
-- Copyright(c)    :   2018 - 2019 Vlasov D.V.
--

library ieee;
use ieee.std_logic_1164.all;
library nf;
use nf.nf_settings.all;
use nf.nf_uart_pkg.all;
use nf.nf_help_pkg.all;
use nf.nf_components.all;

entity nf_uart_top is
    port
    (
        -- reset and clock
        clk     : in    std_logic;                      -- clk
        resetn  : in    std_logic;                      -- resetn
        -- bus side
        addr    : in    std_logic_vector(31 downto 0);  -- address
        we      : in    std_logic;                      -- write enable
        wd      : in    std_logic_vector(31 downto 0);  -- write data
        rd      : out   std_logic_vector(31 downto 0);  -- read data
        -- uart side
        uart_tx : out   std_logic;                      -- UART tx wire
        uart_rx : in    std_logic                       -- UART rx wire
    );
end nf_uart_top;

architecture rtl of nf_uart_top is
    -- write enable signals 
    signal uart_cr_we   : std_logic;                        -- UART control register write enable
    signal uart_tx_we   : std_logic;                        -- UART transmitter register write enable
    signal uart_dv_we   : std_logic;                        -- UART divider register write enable
    -- uart transmitter other signals
    signal req          : std_logic;                        -- request transmit
    signal req_ack      : std_logic;                        -- request acknowledge transmit
    -- uart receiver other signals
    signal rx_valid     : std_logic;                        -- rx byte received
    signal rx_val_set   : std_logic;                        -- receiver data valid set
    --
    signal udvr         : std_logic_vector(15 downto 0);    -- "dividing frequency"
    signal udr_tx       : std_logic_vector(7  downto 0);    -- transmitting data
    signal udr_rx       : std_logic_vector(7  downto 0);    -- received data   
    signal cri          : ucr;                              -- control register input
    signal cro          : ucr;                              -- control register output
begin
    -- assign write enable signals
    uart_cr_we <= we and bool2sl( addr(3 downto 0) = NF_UART_CR );
    uart_tx_we <= we and bool2sl( addr(3 downto 0) = NF_UART_TX );
    uart_dv_we <= we and bool2sl( addr(3 downto 0) = NF_UART_DR );

    cri.tx_req(0) <= wd(0);
    cri.rx_val(0) <= wd(1);
    cri.tx_en(0)  <= wd(2);
    cri.rx_en(0)  <= wd(3);
    cri.un        <= (others => '0');
    cro.un        <= (others => '0');

    -- mux for routing one register value
    mux_proc : process(all)
    begin
        rd <= (31 downto 8 => '0') & ucr2slv(cro);
        case( addr(3 downto 0) ) is
            when NF_UART_CR => rd <= (31 downto  8 => '0') & ucr2slv(cro);
            when NF_UART_TX => rd <= (31 downto  8 => '0') & udr_tx;
            when NF_UART_RX => rd <= (31 downto  8 => '0') & udr_rx;
            when NF_UART_DR => rd <= (31 downto 16 => '0') & udvr;
            when others     => 
        end case;
    end process;

    -- creating control and data registers
    nf_uart_tx_reg : nf_register_we generic map(  8 ) port map( clk , resetn , uart_tx_we , wd(7  downto 0) , udr_tx    );
    nf_uart_dv_reg : nf_register_we generic map( 16 ) port map( clk , resetn , uart_dv_we , wd(15 downto 0) , udvr      );
    nf_uart_tx_en  : nf_register_we generic map(  1 ) port map( clk , resetn , uart_cr_we , cri.tx_en       , cro.tx_en );
    nf_uart_rx_en  : nf_register_we generic map(  1 ) port map( clk , resetn , uart_cr_we , cri.rx_en       , cro.rx_en );
    -- creating one cross domain crossing for tx request
    nf_cdc_req : nf_cdc 
    port map
    (  
        resetn_1    => resetn,          -- controller side reset
        resetn_2    => resetn,          -- uart side reset
        clk_1       => clk,             -- controller side clock
        clk_2       => clk,             -- uart side clock
        we_1        => uart_cr_we,      -- controller side write enable
        we_2        => req_ack,         -- uart side write enable
        data_1_in   => cri.tx_req(0),   -- controller side request
        data_2_in   => not req_ack,     -- uart side request
        data_1_out  => cro.tx_req(0),   -- controller side request out
        data_2_out  => req,             -- uart side request out
        wait_1      => open,
        wait_2      => open
    );
    -- creating one cross domain crossing for rx valid
    nf_cdc_valid : nf_cdc 
    port map
    (  
        resetn_1    => resetn,          -- controller side reset
        resetn_2    => resetn,          -- uart side reset
        clk_1       => clk,             -- controller side clock
        clk_2       => clk,             -- uart side clock
        we_1        => uart_cr_we,      -- controller side write enable
        we_2        => rx_valid,        -- uart side write enable
        data_1_in   => cri.rx_val(0),   -- controller side valid
        data_2_in   => rx_valid,        -- uart side valid
        data_1_out  => cro.rx_val(0),   -- controller side valid out
        data_2_out  => rx_val_set,      -- uart side valid out
        wait_1      => open,
        wait_2      => open
    );
    -- creating one uart transmitter 
    nf_uart_transmitter_0 : nf_uart_transmitter 
    port map
    (
        -- reset and clock
        clk         => clk,             -- clk
        resetn      => resetn,          -- resetn
        -- controller side interface
        tr_en       => cro.tx_en(0),    -- transmitter enable
        comp        => udvr,            -- compare input for setting baudrate
        tx_data     => udr_tx,          -- data for transfer
        req         => req,             -- request signal
        req_ack     => req_ack,         -- acknowledgent signal
        -- uart tx side
        uart_tx     => uart_tx          -- UART tx wire
    );
    -- creating one uart receiver 
    nf_uart_receiver_0 : nf_uart_receiver 
    port map
    (
        -- reset and clock
        clk         => clk,             -- clk
        resetn      => resetn,          -- resetn
        -- controller side interface
        rec_en      => cro.rx_en(0),    -- receiver enable
        comp        => udvr,            -- compare input for setting baudrate
        rx_data     => udr_rx,          -- received data
        rx_valid    => rx_valid,        -- receiver data valid
        rx_val_set  => rx_val_set,      -- receiver data valid set
        -- uart rx side
        uart_rx     => uart_rx          -- UART rx wire
    );

end rtl; -- nf_uart_top
