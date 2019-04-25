#
# File          :   script_modelsim.tcl
# Autor         :   Vlasov D.V.
# Data          :   2019.04.19
# Language      :   tcl
# Description   :   This is script for running simulation process
# Copyright(c)  :   2019 Vlasov D.V.
#

vlib work

#set test "nf_uart_transmitter test"
#set test "nf_uart_receiver test"
set test "nf_uart_top test"

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

    vcom -2008 ../inc/nf_help_pkg.vhd -work nf
    vcom -2008 ../inc/nf_uart_pkg.vhd -work nf
    vcom -2008 ../inc/nf_settings.vhd -work nf
    vcom -2008 ../rtl/periphery/uart/nf_uart_transmitter.vhd
    vcom -2008 ../rtl/periphery/uart/nf_uart_receiver.vhd
    vcom -2008 ../rtl/common/nf_registers.vhd
    vcom -2008 ../rtl/periphery/nf_cdc.vhd
    vcom -2008 ../rtl/periphery/uart/nf_uart_top.vhd
    vlog ../tb/nf_uart_top_tb.sv

    vsim -novopt work.nf_uart_top_tb -g nf_uart_top_tb/tx_rx_test=$sub_test

    add wave -position insertpoint sim:/nf_uart_top_tb/*
    add wave -position insertpoint sim:/nf_uart_top_tb/nf_uart_top_0/*

}

run -all

wave zoom full

#quit
