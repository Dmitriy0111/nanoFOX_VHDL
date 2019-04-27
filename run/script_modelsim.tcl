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

} elseif {$test == "nf_top test"} {

    #set sub_test "rx_test"
    set sub_test "tx_test"

    vcom -2008 ../inc/nf_help_pkg.vhd           -work nf
    vcom -2008 ../inc/nf_ahb_pkg.vhd            -work nf
    vcom -2008 ../inc/nf_mem_pkg.vhd            -work nf
    vcom -2008 ../inc/nf_uart_pkg.vhd           -work nf
    vcom -2008 ../inc/nf_settings.vhd           -work nf
    vcom -2008 ../inc/nf_cpu_def.vhd            -work nf
    vcom -2008 ../program_file/nf_program.vhd   -work nf

    vcom -2008  ../rtl/core/nf_alu.vhd
    vcom -2008  ../rtl/core/nf_branch_unit.vhd
    vcom -2008  ../rtl/core/nf_sign_ex.vhd
    vcom -2008  ../rtl/core/nf_reg_file.vhd
    vcom -2008  ../rtl/core/nf_i_exu.vhd
    vcom -2008  ../rtl/core/nf_hz_bypass_unit.vhd
    vcom -2008  ../rtl/core/nf_i_du.vhd
    vcom -2008  ../rtl/core/nf_hz_stall_unit.vhd
    vcom -2008  ../rtl/core/nf_i_lsu.vhd
    vcom -2008  ../rtl/core/nf_cpu_cc.vhd
    vcom -2008  ../rtl/common/nf_registers.vhd
    vcom -2008  ../rtl/periphery/nf_ram.vhd
    vcom -2008  ../rtl/periphery/nf_cdc.vhd
    vcom -2008  ../rtl/periphery/pwm/nf_pwm.vhd
    vcom -2008  ../rtl/periphery/gpio/nf_gpio.vhd
    vcom -2008  ../rtl/periphery/uart/nf_uart_transmitter.vhd
    vcom -2008  ../rtl/periphery/uart/nf_uart_receiver.vhd
    vcom -2008  ../rtl/periphery/uart/nf_uart_top.vhd
    vcom -2008  ../rtl/ahb/nf_ahb_mux.vhd
    vcom -2008   ../rtl/ahb/nf_ahb_dec.vhd 
    vcom -2008  ../rtl/ahb/nf_ahb_router.vhd
    vcom -2008  ../rtl/ahb/nf_ahb2core.vhd
    vcom -2008  ../rtl/ahb/nf_ahb_top.vhd
    vcom -2008  ../rtl/ahb/nf_ahb_pwm.vhd
    vcom -2008  ../rtl/ahb/nf_ahb_gpio.vhd
    vcom -2008  ../rtl/ahb/nf_ahb_uart.vhd
    vcom -2008  ../rtl/ahb/nf_ahb_ram.vhd
    vcom -2008   ../rtl/core/nf_control_unit.vhd
    vcom -2008  ../rtl/core/nf_cpu.vhd

    vlog ../rtl/core/nf_i_fu.sv ../rtl/nf_top.sv

    vlog ../tb/nf_bt_class.sv ../tb/nf_log_writer.sv ../tb/nf_pars_instr.sv ../tb/nf_tb.sv

    vsim -novopt work.nf_tb

    add wave -divider  "pipeline stages"
    add wave -position insertpoint sim:/nf_tb/instruction_if_stage
    add wave -position insertpoint sim:/nf_tb/instruction_id_stage
    add wave -position insertpoint sim:/nf_tb/instruction_iexe_stage
    add wave -position insertpoint sim:/nf_tb/instruction_imem_stage
    add wave -position insertpoint sim:/nf_tb/instruction_iwb_stage
    add wave -divider  "core singals"
    add wave -position insertpoint sim:/nf_tb/nf_top_0/nf_cpu_0/*
    add wave -divider  "testbench signals"
    add wave -position insertpoint sim:/nf_tb/*

}

run -all

wave zoom full

#quit
