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

use std.env.stop;

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
    -- help variables
    signal cycle_counter    : integer := 0;                 -- variable for cpu cycle
    signal rep_c            : integer := 0;
    signal rst_c            : integer := 0;

    signal instr_if     : std_logic_vector(31 downto 0);  
    signal instr_id     : std_logic_vector(31 downto 0);  
    signal instr_iexe   : std_logic_vector(31 downto 0);
    signal instr_imem   : std_logic_vector(31 downto 0);
    signal instr_iwb    : std_logic_vector(31 downto 0); 

    -- instructions
    signal instruction_if_stage   : string(20 downto 1);
    signal instruction_id_stage   : string(20 downto 1);
    signal instruction_iexe_stage : string(20 downto 1);
    signal instruction_imem_stage : string(20 downto 1);
    signal instruction_iwb_stage  : string(20 downto 1);
    -- string for debug_lev0
    --signal instr_sep_s_if_stage   : string;
    --signal instr_sep_s_id_stage   : string;
    --signal instr_sep_s_iexe_stage : string;
    --signal instr_sep_s_imem_stage : string;
    --signal instr_sep_s_iwb_stage  : string;
    -- string for txt, html and terminal logging
    --signal log_str                : string   = "";
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

    function pars_pipe_stage(pipe_slv : std_logic_vector) return string is
        variable pipe_str : string(20 downto 1) := "                    ";
    begin
        if( pipe_slv(1 downto 0) = "11" ) then
            pipe_str := "RVI                 ";
        end if;
        return pipe_str;
    end function;
begin

    gpio_i_0 <= 8X"01";

    instr_if   <= << signal .nf_tb.nf_top_0.nf_cpu_0.instr_if   : std_logic_vector(31 downto 0) >>;
    instr_id   <= << signal .nf_tb.nf_top_0.nf_cpu_0.instr_id   : std_logic_vector(31 downto 0) >>;
    instr_iexe <= << signal .nf_tb.nf_top_0.nf_cpu_0.instr_iexe : std_logic_vector(31 downto 0) >>;
    instr_imem <= << signal .nf_tb.nf_top_0.nf_cpu_0.instr_imem : std_logic_vector(31 downto 0) >>;
    instr_iwb  <= << signal .nf_tb.nf_top_0.nf_cpu_0.instr_iwb  : std_logic_vector(31 downto 0) >>;

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
    begin
        wait until rising_edge(clk);
        if( resetn ) then
            instruction_if_stage    <= pars_pipe_stage(instr_if  );
            instruction_id_stage    <= pars_pipe_stage(instr_id  );
            instruction_iexe_stage  <= pars_pipe_stage(instr_iexe);
            instruction_imem_stage  <= pars_pipe_stage(instr_imem);
            instruction_iwb_stage   <= pars_pipe_stage(instr_iwb );
        end if;
    end process pars_proc;

    -- generating clock
    clk_gen : process
    begin
        if( resetn ) then
            rep_c <= rep_c + 1;
        end if;
        clk <= '0';
        wait for (T / 2 * timescale);
        clk <= '1';
        wait for (T / 2 * timescale);
        if( rep_c = repeat_cycles) then
            stop;
            rep_c <= rep_c + 1; 
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

    -- creating pars_instruction class
    --nf_pars_instr nf_pars_instr_0 = new();
    --nf_log_writer nf_log_writer_0 = new();
    -- parsing instruction
    --initial
    --begin
    --    nf_log_writer_0.build("../log/log");
    --    
    --    forever
    --    begin
    --        @( posedge nf_top_0.clk );
    --        if( resetn )
    --        begin
    --            if( `log_en )
    --            begin
    --                #1ns;   -- for current instructions
    --                nf_pars_instr_0.pars( nf_top_0.nf_cpu_0.instr_if   , instruction_if_stage   , instr_sep_s_if_stage   );
    --                nf_pars_instr_0.pars( nf_top_0.nf_cpu_0.instr_id   , instruction_id_stage   , instr_sep_s_id_stage   );
    --                nf_pars_instr_0.pars( nf_top_0.nf_cpu_0.instr_iexe , instruction_iexe_stage , instr_sep_s_iexe_stage );
    --                nf_pars_instr_0.pars( nf_top_0.nf_cpu_0.instr_imem , instruction_imem_stage , instr_sep_s_imem_stage );
    --                nf_pars_instr_0.pars( nf_top_0.nf_cpu_0.instr_iwb  , instruction_iwb_stage  , instr_sep_s_iwb_stage  );
    --                -- form title
    --                log_str = "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n";
    --                log_str = { log_str , $psprintf("cycle = %d, pc = 0x%h ", cycle_counter, nf_top_0.nf_cpu_0.addr_i     ) };
    --                log_str = { log_str , $psprintf("%t\n", $time                                                         ) };
    --                -- form instruction fetch stage output
    --                log_str = { log_str , "Instruction decode stage        : "                                              };
    --                log_str = { log_str , $psprintf("%s\n", instruction_if_stage                                          ) };
    --                if( `debug_lev0 ) 
    --                    log_str = { log_str , $psprintf("                                  %s \n", instr_sep_s_if_stage   ) };
    --                -- form instruction decode stage output
    --                log_str = { log_str , "Instruction decode stage        : "                                              };
    --                log_str = { log_str , $psprintf("%s\n", instruction_id_stage                                          ) };
    --                if( `debug_lev0 ) 
    --                    log_str = { log_str , $psprintf("                                  %s \n", instr_sep_s_id_stage   ) };
    --                -- form instruction execution stage output
    --                log_str = { log_str , "Instruction execute stage       : "                                              };
    --                log_str = { log_str , $psprintf("%s\n", instruction_iexe_stage                                        ) };
    --                if( `debug_lev0 ) 
    --                    log_str = { log_str , $psprintf("                                  %s \n", instr_sep_s_iexe_stage ) };
    --                -- form instruction memory stage output
    --                log_str = { log_str , "Instruction memory stage        : "                                              };
    --                log_str = { log_str , $psprintf("%s\n", instruction_imem_stage                                        ) };
    --                if( `debug_lev0 ) 
    --                    log_str = { log_str , $psprintf("                                  %s \n", instr_sep_s_imem_stage ) };
    --                -- form instruction write back stage output
    --                log_str = { log_str , "Instruction write back stage    : "                                              };
    --                log_str = { log_str , $psprintf("%s\n", instruction_iwb_stage                                         ) };
    --                if( `debug_lev0 ) 
    --                    log_str = { log_str , $psprintf("                                  %s \n", instr_sep_s_iwb_stage  ) };
    --                -- write debug info in log file
    --                nf_log_writer_0.write_log(nf_top_0.nf_cpu_0.nf_reg_file_0.reg_file, log_str);
    --            end
    --            -- increment cycle counter
    --            cycle_counter++;
    --            if( cycle_counter == repeat_cycles )
    --                $stop;
    --        end
    --    end
    --end

