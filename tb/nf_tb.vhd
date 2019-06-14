--
-- File            :   nf_tb.sv
-- Autor           :   Vlasov D.V.
-- Data            :   2019.04.1309
-- Language        :   VHDL
-- Description     :   This is testbench for cpu unit
-- Copyright(c)    :   2019 Vlasov D.V.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use std.env.stop;
use std.textio.all;

library nf;
use nf.nf_tb_def.all;
use nf.nf_cpu_def.all;
use nf.nf_mem_pkg.all;

entity nf_tb is
end nf_tb;

architecture testbench of nf_tb is
    constant timescale          : time      := 1 ns;
    constant T                  : integer   := 20;          -- 50 MHz (clock period)
    constant repeat_cycles      : integer   := 200;         -- number of repeat cycles before stop
    constant resetn_delay       : integer   := 7;           -- delay for reset signal (posedge clk)
    constant work_freq          : integer   := 50000000;    -- core work frequency
    constant uart_speed         : integer   := 115200;      -- setting uart speed
    constant uart_rec_example   : boolean   := true;        -- for working with uart receive example
    constant stop_loop          : boolean   := true;        -- stop with loop 0000_006f
    constant stop_cycle         : boolean   := false;       -- stop with cycle variable
    -- clock and reset
    signal clk              : std_logic;                    -- clock
    signal resetn           : std_logic;                    -- reset
    -- peryphery inputs/outputs
    signal gpio_i_0         : std_logic_vector(7 downto 0); -- GPIO_0 input
    signal gpio_o_0         : std_logic_vector(7 downto 0); -- GPIO_0 output
    signal gpio_d_0         : std_logic_vector(7 downto 0); -- GPIO_0 direction
    signal pwm              : std_logic;                    -- PWM output signal
    signal uart_tx          : std_logic;                    -- UART tx wire
    signal uart_rx          : std_logic;                    -- UART rx wire
    -- help signals
    signal cycle_counter    : integer := 0;                 -- variable for cpu cycle
    signal rst_c            : integer := 0;
    signal loop_c           : integer := 0;

    signal pc_value     : std_logic_vector(31 downto 0);
    signal instr_if     : std_logic_vector(31 downto 0);  
    signal instr_id     : std_logic_vector(31 downto 0);  
    signal instr_iexe   : std_logic_vector(31 downto 0);
    signal instr_imem   : std_logic_vector(31 downto 0);
    signal instr_iwb    : std_logic_vector(31 downto 0); 

    signal reg_file     : mem_t(31 downto 0)(31 downto 0);
    constant str_len    : integer := 70;
    -- instructions
    signal instruction_if_stage   : string(str_len downto 1) := (others => ' ');
    signal instruction_id_stage   : string(str_len downto 1) := (others => ' ');
    signal instruction_iexe_stage : string(str_len downto 1) := (others => ' ');
    signal instruction_imem_stage : string(str_len downto 1) := (others => ' ');
    signal instruction_iwb_stage  : string(str_len downto 1) := (others => ' ');

    -- string for debug_lev0
    signal instr_sep_s_if_stage   : string(str_len downto 1) := (others => ' ');
    signal instr_sep_s_id_stage   : string(str_len downto 1) := (others => ' ');
    signal instr_sep_s_iexe_stage : string(str_len downto 1) := (others => ' ');
    signal instr_sep_s_imem_stage : string(str_len downto 1) := (others => ' ');
    signal instr_sep_s_iwb_stage  : string(str_len downto 1) := (others => ' ');
    -- nf_top
    component nf_top_ahb
        port 
        (
            -- clock and reset
            clk         : in    std_logic;                      -- clock
            resetn      : in    std_logic;                      -- reset
            -- PWM side
            pwm         : out   std_logic;                      -- PWM output
            -- GPIO side
            gpio_i_0    : in    std_logic_vector(7 downto 0);   -- GPIO input
            gpio_o_0    : out   std_logic_vector(7 downto 0);   -- GPIO output
            gpio_d_0    : out   std_logic_vector(7 downto 0);   -- GPIO direction
            -- UART side
            uart_tx     : out   std_logic;                      -- UART tx wire
            uart_rx     : in    std_logic                       -- UART rx wire
        );
    end component;
begin

    gpio_i_0 <= 8X"01";
    -- associate signals
    pc_value   <= << signal .nf_tb.nf_top_ahb_0.nf_cpu_0.addr_i : std_logic_vector(31 downto 0) >>;

    instr_if   <= << signal .nf_tb.nf_top_ahb_0.nf_cpu_0.instr_if   : std_logic_vector(31 downto 0) >>;
    instr_id   <= << signal .nf_tb.nf_top_ahb_0.nf_cpu_0.instr_id   : std_logic_vector(31 downto 0) >>;
    instr_iexe <= << signal .nf_tb.nf_top_ahb_0.nf_cpu_0.instr_iexe : std_logic_vector(31 downto 0) >>;
    instr_imem <= << signal .nf_tb.nf_top_ahb_0.nf_cpu_0.instr_imem : std_logic_vector(31 downto 0) >>;
    instr_iwb  <= << signal .nf_tb.nf_top_ahb_0.nf_cpu_0.instr_iwb  : std_logic_vector(31 downto 0) >>;

    reg_file   <= << signal .nf_tb.nf_top_ahb_0.nf_cpu_0.nf_reg_file_0.reg_file  : mem_t(31 downto 0)(31 downto 0) >>;

    nf_top_ahb_0 : nf_top_ahb 
    port map
    (   
        -- clock and reset
        clk         => clk,         -- clock input
        resetn      => resetn,      -- reset input
        -- GPIO side
        gpio_i_0    => gpio_i_0,    -- GPIO_0 input
        gpio_o_0    => gpio_o_0,    -- GPIO_0 output
        gpio_d_0    => gpio_d_0,    -- GPIO_0 direction
        -- PWM side
        pwm         => pwm,         -- PWM output signal
        -- UART side
        uart_tx     => uart_tx,     -- UART tx wire
        uart_rx     => uart_rx      -- UART rx wire
    );

    -- pars_instr
    pars_proc : process
        variable term_line  : line;
        variable log_line   : line;
        variable log_h_line : line;
        file     log_file   : text;
        file     html_log   : text;
        variable file_s     : file_open_status;
        variable i          : integer;
        variable td_i       : integer;
        variable reg_file_l : mem_t(31 downto 0)(31 downto 0) := (others => 32X"00000000" );
        variable reg_file_c : mem_t(31 downto 0)(1  downto 0) := (others => 2X"0" );
    begin
        if( log_txt ) then
            file_open(file_s , log_file , "../log/log.log" , write_mode);
        end if;
        if( log_html ) then
            file_open(file_s , html_log , "../log/log.html" , write_mode);
        end if;
        wait until rising_edge(clk);
        wait for 1 ns;
        if( resetn ) then
            -- form debug strings
            instruction_if_stage   <= update_pipe_str( pars_pipe_stage( instr_if   ) , str_len );
            instruction_id_stage   <= update_pipe_str( pars_pipe_stage( instr_id   ) , str_len );
            instruction_iexe_stage <= update_pipe_str( pars_pipe_stage( instr_iexe ) , str_len );
            instruction_imem_stage <= update_pipe_str( pars_pipe_stage( instr_imem ) , str_len );
            instruction_iwb_stage  <= update_pipe_str( pars_pipe_stage( instr_iwb  ) , str_len );
            if(debug_lev0) then
                instr_sep_s_if_stage   <= update_pipe_str( pars_pipe_stage( instr_if   , "lv_0" ) , str_len );
                instr_sep_s_id_stage   <= update_pipe_str( pars_pipe_stage( instr_id   , "lv_0" ) , str_len );
                instr_sep_s_iexe_stage <= update_pipe_str( pars_pipe_stage( instr_iexe , "lv_0" ) , str_len );
                instr_sep_s_imem_stage <= update_pipe_str( pars_pipe_stage( instr_imem , "lv_0" ) , str_len );
                instr_sep_s_iwb_stage  <= update_pipe_str( pars_pipe_stage( instr_iwb  , "lv_0" ) , str_len );
                end if;
            if( log_en ) then
                write(term_line, string'("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>") & LF );
                write(term_line, "cycle = " & to_string(cycle_counter) & ", pc = 0x" & to_hstring(pc_value) & " " & time'image(now) & LF );
                write(term_line, "Instruction fetch stage         : " & pars_pipe_stage( instr_if   ) & LF );
                if(debug_lev0) then
                    write(term_line, "                                  " & pars_pipe_stage( instr_if   , "lv_0" ) & LF );
                end if;
                write(term_line, "Instruction decode stage        : " & pars_pipe_stage( instr_id   ) & LF );
                if(debug_lev0) then
                    write(term_line, "                                  " & pars_pipe_stage( instr_id   , "lv_0" ) & LF );
                end if;
                write(term_line, "Instruction execute stage       : " & pars_pipe_stage( instr_iexe ) & LF );
                if(debug_lev0) then
                    write(term_line, "                                  " & pars_pipe_stage( instr_iexe , "lv_0" ) & LF );
                end if;
                write(term_line, "Instruction memory stage        : " & pars_pipe_stage( instr_imem ) & LF );
                if(debug_lev0) then
                    write(term_line, "                                  " & pars_pipe_stage( instr_imem , "lv_0" ) & LF );
                end if;
                write(term_line, "Instruction write back stage    : " & pars_pipe_stage( instr_iwb  ) & LF );
                if(debug_lev0) then
                    write(term_line, "                                  " & pars_pipe_stage( instr_iwb  , "lv_0" ) & LF );
                end if;
                write(term_line, string'("register list :") & LF );
                -- copy terminal message in html message
                write(log_h_line, string'("<font size = ""4"">") );
                write(log_h_line, string'("<pre>") );
                if( log_html ) then
                    writeline(html_log, log_h_line);
                end if;
                log_h_line := new string'(term_line.all);
                if( log_html ) then
                    writeline(html_log, log_h_line);
                end if;
                -- form register file table for terminal and log file
                write(term_line, write_txt_table(reg_file) & LF );
                -- copy terminal message in log message
                log_line := new string'(term_line.all);
                -- write data in log file and terminal
                if( log_term ) then
                    writeline(output, term_line);
                end if;
                if( log_txt ) then
                    writeline(log_file, log_line);
                end if;
                -- starting write data in html file
                write(log_h_line, string'("</pre>") );
                write(log_h_line, string'("</font>") );
                if( log_html ) then
                    writeline(html_log, log_h_line);
                end if;
                i := 0;
                reg_list_loop : loop
                    reg_file_c(i) := "00" when (reg_file_l(i) = reg_file(i)) else "01";
                    if(reg_file(i) = 32X"XXXXXXXX") then
                        reg_file_c(i) := "10";
                    end if;
                    reg_file_l(i) := reg_file_l(i) when ( reg_file_c(i) = "00" ) else reg_file(i);
                    i := i + 1;
                    exit reg_list_loop when (i = 32);
                end loop;
                i := 0;
                td_i := 0;
                write(log_h_line, string'("<table border=""1"">") );
                if( log_html ) then
                    writeline(html_log, log_h_line);
                end if;
                html_table_loop : loop
                    if( td_i = 0 ) then
                        write(log_h_line, string'("    <tr>") & LF );
                    end if;
                    write(log_h_line, string'("        <td "));
                    if(reg_file_c(i)="00") then
                        write(log_h_line, string'("bgcolor = ""white"""));
                    elsif(reg_file_c(i)="01") then
                        write(log_h_line, string'("bgcolor = ""green"""));
                    else
                        write(log_h_line, string'("bgcolor = ""red"""));
                    end if;

                    write(log_h_line, string'(">"));
                    write(log_h_line, string'("<pre>") );
                    write(log_h_line, reg_list(i) & " = 0x" & to_hstring(reg_file_l(i)));
                    write(log_h_line, string'("</pre>") );
                    write(log_h_line, string'("</td>") & LF );
                    td_i := td_i + 1;
                    if( td_i = 4 ) then
                        td_i := 0;
                        write(log_h_line, string'("    </tr>") & LF );
                    end if;
                    i := i + 1;
                    exit html_table_loop when (i = 32);
                end loop;
                write(log_h_line, string'("</table>") );
                if( log_html ) then
                    writeline(html_log, log_h_line);
                end if;
            end if;
        end if;
    end process pars_proc;

    -- generating clock
    clk_gen : process
    begin
        if( resetn ) then
            cycle_counter <= cycle_counter + 1;
        end if;
        clk <= '0';
        wait for (T / 2 * timescale);
        clk <= '1';
        wait for (T / 2 * timescale);
        if( ( cycle_counter = repeat_cycles ) and stop_cycle ) then
            stop;
        end if;
        if( ( instr_id = 32X"0000006f" ) and stop_loop ) then
            loop_c <= loop_c + 1;
        end if;
        if( loop_c = 3 ) then
            stop;
        end if;
    end process clk_gen;
    -- reset generation
    rst_gen : process
    begin
        if( rst_c /= resetn_delay ) then
            resetn <= '0';
            rst_c  <= rst_c + 1;
            wait until rising_edge(clk);
        else
            resetn <= '1';
            wait;
        end if;
    end process rst_gen;
    -- uart rx generation
    uart_rx_gen : process

        procedure wait_for_clock( rep : integer ) is
        begin
            for i in 0 to rep loop
                wait until rising_edge(clk);
            end loop;
        end;

        -- task for sending symbol over uart to receive module
        procedure send_uart_symbol( symbol : std_logic_vector ) is
            begin
                -- generate 'start'
                uart_rx <= '0';
                wait_for_clock(work_freq / uart_speed);
                -- generate transaction
                for i in symbol'range loop
                    uart_rx <= symbol(7-i);
                    wait_for_clock(work_freq / uart_speed);
                end loop;
                -- generate 'stop'
                uart_rx <= '1';
                wait_for_clock(work_freq / uart_speed);
        end; -- send_uart_symbol

        -- task for sending message over uart to receive module
        procedure send_uart_message( message : string ; delay_v : integer ) is
        begin
            for i in message'range loop
                send_uart_symbol( std_logic_vector( to_unsigned( character'pos(message(i)) , 8 ) ) );
                wait for delay_v * timescale;
            end loop;
        end; -- send_uart_message

    begin
        uart_rx <= '1';
        if( uart_rec_example ) then
            wait_for_clock(200);
            send_uart_message("Hello World!" , 100);
            wait;
        else 
            wait;
        end if;
    end process uart_rx_gen;

end testbench; -- nf_tb  
