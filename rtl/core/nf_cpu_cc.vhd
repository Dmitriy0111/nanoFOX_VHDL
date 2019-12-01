--
-- File            :   nf_cpu_cc.vhd
-- Autor           :   Vlasov D.V.
-- Data            :   2019.04.24
-- Language        :   VHDL
-- Description     :   This is cpu cross connect unit
-- Copyright(c)    :   2019 Vlasov D.V.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity nf_cpu_cc is
    port
    (
        -- clock and reset
        clk             : in    std_logic;                      -- clock
        resetn          : in    std_logic;                      -- reset
        -- instruction memory (IF)
        addr_i          : in    std_logic_vector(31 downto 0);  -- address instruction memory
        rd_i            : out   std_logic_vector(31 downto 0);  -- read instruction memory
        wd_i            : in    std_logic_vector(31 downto 0);  -- write instruction memory
        we_i            : in    std_logic;                      -- write enable instruction memory signal
        size_i          : in    std_logic_vector(1  downto 0);  -- size for load/store instructions
        req_i           : in    std_logic;                      -- request instruction memory signal
        req_ack_i       : out   std_logic;                      -- request acknowledge instruction memory signal
        -- data memory and other's
        addr_dm         : in    std_logic_vector(31 downto 0);  -- address data memory
        rd_dm           : out   std_logic_vector(31 downto 0);  -- read data memory
        wd_dm           : in    std_logic_vector(31 downto 0);  -- write data memory
        we_dm           : in    std_logic;                      -- write enable data memory signal
        size_dm         : in    std_logic_vector(1  downto 0);  -- size for load/store instructions
        req_dm          : in    std_logic;                      -- request data memory signal
        req_ack_dm      : out   std_logic;                      -- request acknowledge data memory signal
        -- cross connect data
        addr_cc         : out   std_logic_vector(31 downto 0);  -- address cc_data memory
        rd_cc           : in    std_logic_vector(31 downto 0);  -- read cc_data memory
        wd_cc           : out   std_logic_vector(31 downto 0);  -- write cc_data memory
        we_cc           : out   std_logic;                      -- write enable cc_data memory signal
        size_cc         : out   std_logic_vector(1  downto 0);  -- size for load/store instructions
        req_cc          : out   std_logic;                      -- request cc_data memory signal
        req_ack_cc      : in    std_logic                       -- request acknowledge cc_data memory signal
    );
end nf_cpu_cc;

architecture rtl of nf_cpu_cc is
    constant    MASTER_0    : std_logic_vector(1 downto 0) := "01";
    constant    MASTER_1    : std_logic_vector(1 downto 0) := "10";
    constant    MASTER_NONE : std_logic_vector(1 downto 0) := "00";
    -- defining states
    type        state_t is  ( M0_s , M1_s , M_NONE_s);
    -- wires
    signal  master_sel_out  : std_logic_vector(1 downto 0); -- master select output for request, write data, write enable, address signals
    signal  master_sel_in   : std_logic_vector(1 downto 0); -- master select input for request acknowledge, read data signals
    signal  last_master     : std_logic;                    -- last master
    signal  state           : state_t;                      -- current state
begin

    req_ack_i  <= req_ack_cc when ( master_sel_in = MASTER_0 ) else '0';
    rd_i       <= rd_cc      when ( master_sel_in = MASTER_0 ) else (others => '0');

    req_ack_dm <= req_ack_cc when ( master_sel_in = MASTER_1 ) else '0';
    rd_dm      <= rd_cc      when ( master_sel_in = MASTER_1 ) else (others => '0');

    mux_proc : process(all)
    begin
        req_cc  <= '0';
        size_cc <= (others => '0');
        wd_cc   <= (others => '0');
        we_cc   <= '0';
        addr_cc <= (others => '0');
        case( master_sel_out ) is
            when MASTER_0       => req_cc <= req_i  ; wd_cc <= wd_i            ; we_cc <= we_i  ; addr_cc <= addr_i          ; size_cc <= size_i          ;
            when MASTER_1       => req_cc <= req_dm ; wd_cc <= wd_dm           ; we_cc <= we_dm ; addr_cc <= addr_dm         ; size_cc <= size_dm         ;
            when MASTER_NONE    => req_cc <= '0'    ; wd_cc <= (others => '0') ; we_cc <= '0'   ; addr_cc <= (others => '0') ; size_cc <= (others => '0') ;
            when others         =>
        end case;
    end process;

    sel_proc : process( clk, resetn )
    begin
        if( rising_edge( clk ) ) then
            if( not resetn ) then
                master_sel_out <= MASTER_0;
                master_sel_in  <= MASTER_0;
                state <= M0_s;
                last_master <= '0';
            else
                case( state ) is
                    when M0_s   =>
                        if( req_dm ) then
                            state <= M_NONE_s;
                            last_master <= '0';
                            master_sel_out <= MASTER_NONE;
                        end if;
                    when M1_s   =>
                        if( req_i ) then
                            state <= M_NONE_s;
                            last_master <= '1';
                            master_sel_out <= MASTER_NONE;
                        end if;
                    when M_NONE_s   =>
                        if( ( not req_ack_cc ) and ( not last_master ) ) then
                            state <= M1_s;
                            master_sel_out <= MASTER_1;
                            master_sel_in  <= MASTER_1;
                        end if;
                        if( ( not req_ack_cc ) and (     last_master ) ) then
                            state <= M0_s;
                            master_sel_out <= MASTER_0;
                            master_sel_in  <= MASTER_0;
                        end if;
                    when others =>
                end case;
            end if;
        end if;    
    end process;

end rtl; -- nf_cpu_cc
