#
# File          :   script_modelsim.tcl
# Autor         :   Vlasov D.V.
# Data          :   2019.04.19
# Language      :   tcl
# Description   :   This is script for running simulation process
# Copyright(c)  :   2019 Vlasov D.V.
#

vlib work
vlib nf

#set test "nf_uart_transmitter test"
#set test "nf_uart_receiver test"
#set test "nf_uart_top test"
set test "nf_top test"

if {$test == "nf_uart_transmitter test"} {
    
    vcom -2008 ../inc/nf_help_pkg.vhd -work nf
    vcom -2008 ../rtl/periphery/uart/nf_uart_transmitter.vhd
    vlog ../tb/nf_uart_transmitter_tb.sv

    vsim -novopt work.nf_uart_transmitter_tb

    add wave -position insertpoint sim:/nf_uart_transmitter_tb/*
    add wave -position insertpoint sim:/nf_uart_transmitter_tb/nf_uart_transmitter_0/*

} elseif {$test == "nf_uart_receiver test"} {
    
    vcom -2008 ../inc/nf_help_pkg.vhd -work nf
    vcom -2008 ../rtl/periphery/uart/nf_uart_receiver.vhd
    vlog ../tb/nf_uart_receiver_tb.sv

    vsim -novopt work.nf_uart_receiver_tb

    add wave -position insertpoint sim:/nf_uart_receiver_tb/*
    add wave -position insertpoint sim:/nf_uart_receiver_tb/nf_uart_receiver_0/*

} elseif {$test == "nf_uart_top test"} {

    #set sub_test "rx_test"
    set sub_test "tx_test"

    vcom -2008 ../inc/*.vhd -work nf
    vcom -2008 ../rtl/periphery/uart/*.vhd
    vcom -2008 ../rtl/common/*.vhd
    vcom -2008 ../rtl/periphery/*.vhd
    vlog ../tb/nf_uart_top_tb.sv

    vsim -novopt work.nf_uart_top_tb -g nf_uart_top_tb/tx_rx_test=$sub_test

    add wave -position insertpoint sim:/nf_uart_top_tb/*
    add wave -position insertpoint sim:/nf_uart_top_tb/nf_uart_top_0/*

} elseif {$test == "nf_top test"} {

    vcom -2008 ../inc/nf_settings.vhd           -work nf
    vcom -2008 ../inc/nf_ahb_pkg.vhd            -work nf
    vcom -2008 ../inc/nf_cpu_def.vhd            -work nf
    vcom -2008 ../inc/nf_csr_pkg.vhd            -work nf
    vcom -2008 ../inc/nf_help_pkg.vhd           -work nf
    vcom -2008 ../inc/nf_mem_pkg.vhd            -work nf
    vcom -2008 ../inc/nf_uart_pkg.vhd           -work nf
    vcom -2008 ../inc/nf_components.vhd         -work nf

    vcom -2008 ../program_file/*.vhd            -work nf

    vcom -2008  ../rtl/core/*.vhd
    vcom -2008  ../rtl/common/*.vhd
    vcom -2008  ../rtl/periphery/*.vhd
    vcom -2008  ../rtl/periphery/pwm/*.vhd
    vcom -2008  ../rtl/periphery/gpio/*.vhd
    vcom -2008  ../rtl/periphery/uart/*.vhd
    vcom -2008  ../rtl/bus/ahb/*.vhd
    vcom -2008  ../rtl/bus/apb/*.vhd
    vcom -2008  ../rtl/top/*.vhd

    vcom -2008  ../tb/nf_tb_def.vhd             -work nf
    vcom -2008  ../tb/nf_tb.vhd

    vsim -novopt work.nf_tb

    add wave -divider  "pipeline stages"
    add wave -position insertpoint sim:/nf_tb/instruction_if_stage
    add wave -position insertpoint sim:/nf_tb/instruction_id_stage
    add wave -position insertpoint sim:/nf_tb/instruction_iexe_stage
    add wave -position insertpoint sim:/nf_tb/instruction_imem_stage
    add wave -position insertpoint sim:/nf_tb/instruction_iwb_stage
    add wave -divider  "core singals"
    add wave -radix hexadecimal -position insertpoint sim:/nf_tb/nf_top_ahb_0/nf_cpu_0/*
    add wave -divider  "cache controller singals"
    add wave -position insertpoint sim:/nf_tb/nf_top_ahb_0/nf_cpu_0/nf_i_lsu_0/nf_cache_D_controller/*
    add wave -divider  "load store unit singals"
    add wave -position insertpoint sim:/nf_tb/nf_top_ahb_0/nf_cpu_0/nf_i_lsu_0/*
    add wave -divider  "ahb to apb bridge singals"
    add wave -position insertpoint sim:/nf_tb/nf_top_ahb_0/nf_ahb2apb_bridge_0/*
    add wave -divider  "testbench signals"
    add wave -position insertpoint sim:/nf_tb/clk sim:/nf_tb/resetn sim:/nf_tb/gpio_i_0 sim:/nf_tb/gpio_o_0 sim:/nf_tb/gpio_d_0 sim:/nf_tb/pwm sim:/nf_tb/gpio_i_1 sim:/nf_tb/gpio_o_1 sim:/nf_tb/gpio_d_1 sim:/nf_tb/pwm_1 sim:/nf_tb/uart_tx sim:/nf_tb/uart_rx sim:/nf_tb/cycle_counter sim:/nf_tb/rst_c sim:/nf_tb/pc_value

}

set StdArithNoWarnings 1
set NumericStdNoWarnings 1

run -all

wave zoom full

#quit
