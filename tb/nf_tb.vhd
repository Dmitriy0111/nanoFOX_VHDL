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
    constant T                  : integer   := 20;
    constant repeat_cycles      : integer   := 200;
    constant resetn_delay       : integer   := 7;
    constant work_freq          : integer   := 50000000;
    constant uart_speed         : integer   := 115200;
    constant uart_rec_example   : boolean   := true;
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

    signal pc_value     : std_logic_vector(31 downto 0);
    signal instr_if     : std_logic_vector(31 downto 0);  
    signal instr_id     : std_logic_vector(31 downto 0);  
    signal instr_iexe   : std_logic_vector(31 downto 0);
    signal instr_imem   : std_logic_vector(31 downto 0);
    signal instr_iwb    : std_logic_vector(31 downto 0); 

    signal reg_file     : mem_t(31 downto 0)(31 downto 0);
    signal reg_file_l   : mem_t(31 downto 0)(31 downto 0) := (others => 32X"00000000" );
    signal reg_file_c   : mem_t(31 downto 0)(1  downto 0) := (others => 2X"0" );

    -- instructions
    signal instruction_if_stage   : string(50 downto 1);
    signal instruction_id_stage   : string(50 downto 1);
    signal instruction_iexe_stage : string(50 downto 1);
    signal instruction_imem_stage : string(50 downto 1);
    signal instruction_iwb_stage  : string(50 downto 1);

    -- string for debug_lev0
    signal instr_sep_s_if_stage   : string(50 downto 1);
    signal instr_sep_s_id_stage   : string(50 downto 1);
    signal instr_sep_s_iexe_stage : string(50 downto 1);
    signal instr_sep_s_imem_stage : string(50 downto 1);
    signal instr_sep_s_iwb_stage  : string(50 downto 1);
    -- nf_top
    component nf_top
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
    pc_value   <= << signal .nf_tb.nf_top_0.nf_cpu_0.addr_i : std_logic_vector(31 downto 0) >>;

    instr_if   <= << signal .nf_tb.nf_top_0.nf_cpu_0.instr_if   : std_logic_vector(31 downto 0) >>;
    instr_id   <= << signal .nf_tb.nf_top_0.nf_cpu_0.instr_id   : std_logic_vector(31 downto 0) >>;
    instr_iexe <= << signal .nf_tb.nf_top_0.nf_cpu_0.instr_iexe : std_logic_vector(31 downto 0) >>;
    instr_imem <= << signal .nf_tb.nf_top_0.nf_cpu_0.instr_imem : std_logic_vector(31 downto 0) >>;
    instr_iwb  <= << signal .nf_tb.nf_top_0.nf_cpu_0.instr_iwb  : std_logic_vector(31 downto 0) >>;

    reg_file   <= << signal .nf_tb.nf_top_0.nf_cpu_0.nf_reg_file_0.reg_file  : mem_t(31 downto 0)(31 downto 0) >>;

    nf_top_0 : nf_top 
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
        file     log_html   : text;
        variable file_s     : file_open_status;
        variable i          : integer;
        variable td_i       : integer;
    begin
        file_open(file_s , log_file , "../log/log.log" , write_mode);
        file_open(file_s , log_html , "../log/log.html" , write_mode);
        wait until rising_edge(clk);
        if( resetn ) then
            wait for 1 ns;
            -- form debug strings
            instruction_if_stage   <= update_pipe_str( pars_pipe_stage( instr_if   ) );
            instruction_id_stage   <= update_pipe_str( pars_pipe_stage( instr_id   ) );
            instruction_iexe_stage <= update_pipe_str( pars_pipe_stage( instr_iexe ) );
            instruction_imem_stage <= update_pipe_str( pars_pipe_stage( instr_imem ) );
            instruction_iwb_stage  <= update_pipe_str( pars_pipe_stage( instr_iwb  ) );

            write(term_line, string'("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>") & LF );
            write(term_line, "cycle = " & to_string(cycle_counter) & ", pc = 0x" & to_hstring(pc_value) & " " & time'image(now) & LF );
            write(term_line, "Instruction fetch stage         : " & pars_pipe_stage( instr_if  ) & LF );
            write(term_line, "Instruction decode stage        : " & pars_pipe_stage( instr_id  ) & LF );
            write(term_line, "Instruction execute stage       : " & pars_pipe_stage( instr_iexe) & LF );
            write(term_line, "Instruction memory stage        : " & pars_pipe_stage( instr_imem) & LF );
            write(term_line, "Instruction write back stage    : " & pars_pipe_stage( instr_iwb ) & LF );
            write(term_line, string'("register list :") & LF );
            -- copy terminal message in html message
            write(log_h_line, string'("<font size = ""4"">") );
            write(log_h_line, string'("<pre>") );
            writeline(log_html, log_h_line);
            log_h_line := new string'(term_line.all);
            writeline(log_html, log_h_line);
            -- form register file table for terminal and log file
            write(term_line, write_txt_table(reg_file) & LF );
            -- copy terminal message in log message
            log_line := new string'(term_line.all);
            -- write data in log file and terminal
            writeline(output, term_line);
            writeline(log_file, log_line);
            -- starting write data in html file
            write(log_h_line, string'("</pre>") );
            write(log_h_line, string'("</font>") );
            writeline(log_html, log_h_line);
            i := 0;
            reg_list_loop : loop
                reg_file_c(i) <= "00" when (reg_file_l(i) = reg_file(i)) else "01";
                if(reg_file(i) = 32X"XXXXXXXX") then
                    reg_file_c(i) <= "10";
                end if;
                reg_file_l(i) <= reg_file_l(i) when reg_file_c(i) = "00" else reg_file(i);
                i := i + 1;
                exit reg_list_loop when (i = 32);
            end loop;
            i := 0;
            td_i := 0;
            write(log_h_line, string'("<table border=""1"">") );
            writeline(log_html, log_h_line);
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
            writeline(log_html, log_h_line);
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
        if( cycle_counter = repeat_cycles) then
            stop;
            cycle_counter <= cycle_counter + 1; 
            clk <= '0';
            wait for (T / 2 * timescale);
            clk <= '1';
            wait for (T / 2 * timescale);
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
    begin
        uart_rx <= '1';
        if( uart_rec_example ) then
            report "This is code for uart rx example";
            wait;
        else 
            wait;
        end if;
    end process uart_rx_gen;

end testbench; -- nf_tb  
