--
-- File            :   nf_uart_receiver.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.04.25
-- Language        :   VHDL
-- Description     :   This uart receiver module
-- Copyright(c)    :   2019 Vlasov D.V.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library nf;
use nf.nf_help_pkg.all;

entity nf_uart_receiver is
    port
    (
        -- reset and clock
        clk         : in    std_logic;                      -- clk
        resetn      : in    std_logic;                      -- resetn
        -- controller side interface
        rec_en      : in    std_logic;                      -- receiver enable
        comp        : in    std_logic_vector(15 downto 0);  -- compare input for setting baudrate
        rx_data     : out   std_logic_vector(7  downto 0);  -- received data
        rx_valid    : out   std_logic;                      -- receiver data valid
        rx_val_set  : in    std_logic;                      -- receiver data valid set
        -- uart rx side
        uart_rx     : in    std_logic                       -- UART rx wire
    );
end nf_uart_receiver;

architecture rtl of nf_uart_receiver is
    signal int_reg      : std_logic_vector(7  downto 0);    -- internal register
    signal bit_counter  : std_logic_vector(3  downto 0);    -- bit counter for internal register
    signal counter      : std_logic_vector(15 downto 0);    -- counter for baudrate
    signal idle2rec     : std_logic;                        -- idle to receive
    signal rec2wait     : std_logic;                        -- receive to wait
    signal wait2idle    : std_logic;                        -- wait to idle 
    -- fsm settings
    type   fsm_state is (IDLE_s , RECEIVE_s , WAIT_s);
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

    idle2rec  <= bool2sl( uart_rx = '0' ) ;
    rec2wait  <= bool2sl( bit_counter = 4X"9" );
    wait2idle <= rx_val_set;
    
    rx_data <= int_reg;
    --FSM state change
    fsm_state_change_proc : process(all)
    begin
        if( not resetn ) then
            state <= IDLE_s;
        elsif( rising_edge(clk) ) then
            state <= next_state;
            if( not rec_en ) then
                state <= IDLE_s;
            end if;
        end if;  
    end process;
    -- Finding next state for FSM
    find_next_state_proc : process(all)
    begin
        next_state <= state;
        case( state ) is
            when IDLE_s     => next_state <= sel_st( idle2rec  , RECEIVE_s , state );
            when RECEIVE_s  => next_state <= sel_st( rec2wait  , WAIT_s    , state );
            when WAIT_s     => next_state <= sel_st( wait2idle , IDLE_s    , state );
            when others     => next_state <= IDLE_s;
        end case;
    end process;
    -- Other FSM sequence logic
    fsm_seq_proc : process(all)
    begin
        if( not resetn ) then
            counter  <= (others => '0');
            int_reg  <= (others => '0');
            rx_valid <= '0';
            bit_counter <= (others => '0');
        elsif( rising_edge(clk) ) then
            if( rec_en ) then
                case( state ) is
                    when IDLE_s     => 
                        bit_counter <= (others => '0');
                        counter <= (others => '0');
                        rx_valid <= '0';
                    when RECEIVE_s  => 
                        counter <= counter + 1;
                        if( counter >= comp ) then
                            counter <= (others => '0');
                            bit_counter <= bit_counter + 1;
                        end if;
                        if( counter = ( '0' & comp(15 downto 1) ) ) then
                            int_reg <= uart_rx & int_reg(7 downto 1);
                        end if;
                    when WAIT_s     => 
                        rx_valid <= '1';
                    when others     =>
                end case;
            else
                counter <= (others => '0');
                bit_counter <= (others => '0');
                rx_valid <= '0';
            end if;
        end if;
    end process;

end rtl; -- nf_uart_receiver
