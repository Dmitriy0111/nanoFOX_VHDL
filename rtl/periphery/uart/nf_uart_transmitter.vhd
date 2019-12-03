--
-- File            :   nf_uart_transmitter.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.04.24
-- Language        :   VHDL
-- Description     :   This uart transmitter module
-- Copyright(c)    :   2019 Vlasov D.V.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library nf;
use nf.nf_help_pkg.all;

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
        busy_tx : out   std_logic;
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
    signal stop2idle    : std_logic;                        -- stop to idle
    -- fsm settings
    type   fsm_state is (IDLE_s , START_s , TRANSMIT_s , STOP_s , WAIT_s);
	attribute enum_encoding : string;
    attribute enum_encoding of fsm_state : type is "one-hot";
    signal state        : fsm_state;                        -- current state of fsm
    signal next_state   : fsm_state;                        -- next state for fsm
    function sel_st(logic_cond : std_logic; st_1 : fsm_state; st_0 : fsm_state) return fsm_state is
        begin
            if logic_cond then
                return st_1;
            else 
                return st_0;
            end if;
    end function;
begin

    idle2start <= req;
    start2tr   <= bool2sl( counter >= comp );
    tr2stop    <= bool2sl( bit_counter = 4X"8" );
    stop2idle  <= bool2sl( counter >= comp );
    busy_tx    <= '1' when ( state /= IDLE_s ) else '0';
    
    --FSM state change
    fsm_state_change_proc : process( clk )
    begin
        if( rising_edge(clk) ) then
            if( not resetn ) then
                state <= IDLE_s;
            else
                state <= next_state;
                if( not tr_en ) then
                    state <= IDLE_s;
                end if;
            end if;
        end if;  
    end process;
    -- Finding next state for FSM
    find_next_state_proc : process(all)
    begin
        next_state <= state;
        case( state ) is
            when IDLE_s     => next_state <= sel_st( idle2start , START_s    , state );
            when START_s    => next_state <= sel_st( start2tr   , TRANSMIT_s , state );
            when TRANSMIT_s => next_state <= sel_st( tr2stop    , STOP_s     , state );
            when STOP_s     => next_state <= sel_st( stop2idle  , IDLE_s     , state );
            when others     => next_state <= IDLE_s;
        end case;
    end process;
    -- Other FSM sequence logic
    fsm_seq_proc : process( clk )
    begin
        if( rising_edge(clk) ) then
            if( not resetn ) then
                bit_counter <= (others => '0');
                int_reg <= (others => '1');
                uart_tx <= '1';
                counter <= (others => '0');
            elsif( tr_en ) then
                case( state ) is
                    when IDLE_s     => 
                        uart_tx <= '1';
                        if( idle2start ) then 
                            bit_counter <= (others => '0');
                            counter <= (others => '0');
                            int_reg <= tx_data;
                        end if;
                    when START_s    => 
                        uart_tx <= '0';
                        counter <= counter + 1;
                        if( counter >= comp ) then
                            counter <= (others => '0');
                        end if;
                    when TRANSMIT_s => 
                        uart_tx <= int_reg( to_integer(unsigned(bit_counter(2 downto 0))) );
                        counter <= counter + 1;
                        if( counter >= comp ) then
                            counter <= (others => '0');
                            bit_counter <= bit_counter + 1;
                        end if;
                        if( bit_counter = 4X"8" ) then
                            bit_counter <= (others => '0');
                            uart_tx <= '1';
                        end if;
                    when STOP_s     => 
                        counter <= counter + 1;
                        if( counter >= comp ) then
                            counter <= (others => '0');
                        end if;
                    when others     =>
                end case;
            else
                bit_counter <= (others => '0');
                int_reg <= (others => '1');
                uart_tx <= '1';
            end if;
        end if;
    end process;

end rtl; -- nf_uart_transmitter
