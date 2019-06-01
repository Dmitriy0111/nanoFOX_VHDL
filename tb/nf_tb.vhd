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
    -- help signals
    signal cycle_counter    : integer := 0;                 -- variable for cpu cycle
    signal rst_c            : integer := 0;

    signal pc_value     : std_logic_vector(31 downto 0);
    signal instr_simple : std_logic_vector(31 downto 0);  

    signal reg_file     : mem_t(31 downto 0)(31 downto 0);
    constant str_len    : integer := 70;
    -- instructions
    signal instruction  : string(str_len downto 1) := (others => ' ');

    -- string for debug_lev0
    signal instr_sep    : string(str_len downto 1) := (others => ' ');

    component nf_top
        port 
        (
            -- clock and reset
            clk         : in    std_logic;                      -- clock
            resetn      : in    std_logic;                      -- reset
            div         : in    std_logic_vector(25 downto 0);  -- clock divide input
            -- for debug
            reg_addr    : in    std_logic_vector(4  downto 0);  -- scan register address
            reg_data    : out   std_logic_vector(31 downto 0)   -- scan register data
        );
    end component;
begin

    -- associate signals
    pc_value   <= << signal .nf_tb.nf_top_0.nf_cpu_0.instr_addr_i : std_logic_vector(31 downto 0) >>;

    instr_simple   <= << signal .nf_tb.nf_top_0.nf_cpu_0.instr   : std_logic_vector(31 downto 0) >>;

    reg_file   <= << signal .nf_tb.nf_top_0.nf_cpu_0.nf_reg_file_0.reg_file  : mem_t(31 downto 0)(31 downto 0) >>;

    nf_top_0 : nf_top
    port  map
    (
        -- clock and reset
        clk         => clk,                 -- clock
        resetn      => resetn,              -- reset
        div         => 26X"00000000",       -- clock divide input
        -- for debug
        reg_addr    => 5B"00000",           -- scan register address
        reg_data    => open                 -- scan register data
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
            if( log_en ) then
                -- form debug strings
                instruction   <= update_pipe_str( pars_pipe_stage( instr_simple   ) , str_len );
                if(debug_lev0) then
                    instr_sep   <= update_pipe_str( pars_pipe_stage( instr_simple   , "lv_0" ) , str_len );
                end if;
                write(term_line, string'("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>") & LF );
                write(term_line, "cycle = " & to_string(cycle_counter) & ", pc = 0x" & to_hstring(pc_value) & " " & time'image(now) & LF );
                write(term_line, "Current instruction         : " & pars_pipe_stage( instr_simple   ) & LF );
                if(debug_lev0) then
                    write(term_line, "                                  " & pars_pipe_stage( instr_simple   , "lv_0" ) & LF );
                end if;
                write(term_line, string'("register list :") & LF );
                -- copy terminal message in html message
                write(log_h_line, string'("<font size = ""4"">") );
                write(log_h_line, string'("<pre>") );
                writeline(html_log, log_h_line);
                log_h_line := new string'(term_line.all);
                writeline(html_log, log_h_line);
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

end testbench; -- nf_tb  
