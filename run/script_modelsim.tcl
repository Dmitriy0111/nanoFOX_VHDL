
vlib work

vcom -2008 ../inc/nf_cpu_def.vhd
vcom -2008 ../rtl/nf_alu.vhd
vcom -2008 ../rtl/nf_control_unit.vhd
vcom -2008 ../rtl/nf_instr_mem.vhd
vcom -2008 ../rtl/nf_reg_file.vhd
vcom -2008 ../rtl/nf_sign_ex.vhd
vcom -2008 ../rtl/nf_branch_unit.vhd
vcom -2008 ../rtl/nf_clock_div.vhd
vcom -2008 ../rtl/nf_cpu.vhd
vcom -2008 ../rtl/nf_registers.vhd
vcom -2008 ../rtl/nf_top.vhd

vlog ../tb/nf_pars.sv
vlog ../tb/nf_tb.sv

vsim -novopt work.nf_tb

add wave -position insertpoint sim:/nf_tb/nf_top_0/*

run -all

wave zoom full

#quit
