--
-- File            :   nf_uart_transmitter.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.04.24
-- Language        :   VHDL
-- Description     :   This uart transmitter module
-- Copyright(c)    :   2018 Vlasov D.V.
--

entity nf_uart_transmitter is
    port
    (
        -- reset and clock
        clk     : in    std_logic;                      -- clk
        resetn  : in    std_logic;                      -- resetn
        -- controller side interface
        tr_en   : in    std_logic;                      -- transmitter enable
        comp    : in    std_logic_vector(15 downto 0);  -- compare input for setting baudrate
        tx_data : in    std_logic_vector(7  downto 0);  -- data for transfer
        req     : in    std_logic;                      -- request signal
        req_ack : out   std_logic;                      -- acknowledgent signal
        -- uart tx side
        uart_tx : out   std_logic                       -- UART tx wire
    );
end nf_uart_transmitter;

architecture rtl of nf_uart_transmitter is
    signal int_reg      : std_logic_vector(7  downto 0);    -- internal register
    signal bit_counter  : std_logic_vector(3  downto 0);    -- bit counter for internal register
    signal counter      : std_logic_vector(15 downto 0);    -- counter for baudrate
    signal idle2start   : std_logic;                        -- idle to start
    signal start2tr     : std_logic;                        -- start to transmit
    signal tr2stop      : std_logic;                        -- transmit to stop
    signal stop2wait    : std_logic;                        -- stop to wait
    signal wait2idle    : std_logic;                        -- wait to idle
begin

    idle2start <= req;
    start2tr   <= counter >= comp;
    tr2stop    <= bit_counter = 4X"8";
    stop2wait  <= counter >= comp;
    wait2idle  <= req_ack;
    
    --FSM state change
    fsm_state_change_proc : process(all)
    begin
        if( not resetn ) then
            state <= IDLE_s;
        elsif( rising_edge(clk) ) then
            state <= next_state;
            if( not tr_en ) then
                state <= IDLE_s;
            end if;
        end if;  
    end process;

end rtl; -- nf_uart_transmitter
