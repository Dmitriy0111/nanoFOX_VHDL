
vlib work

#vcom -2008 ../inc/nf_cpu_def.vhd
#vcom -2008 ../inc/nf_settings.vhd
#vcom -2008 ../rtl/nf_alu.vhd          
#vcom -2008 ../rtl/nf_clock_div.vhd     
#vcom -2008 ../rtl/nf_cpu.vhd   
#vcom -2008 ../rtl/nf_instr_mem.vhd  
#vcom -2008 ../rtl/nf_ram.vhd       
#vcom -2008 ../rtl/nf_registers.vhd  
#vcom -2008 ../rtl/nf_router_dec.vhd  
#vcom -2008 ../rtl/nf_sign_ex.vhd
#vcom -2008 ../rtl/nf_branch_unit.vhd  
#vcom -2008 ../rtl/nf_control_unit.vhd  
#vcom -2008 ../rtl/nf_gpio.vhd  
#vcom -2008 ../rtl/nf_pwm.vhd        
#vcom -2008 ../rtl/nf_reg_file.vhd  
#vcom -2008 ../rtl/nf_router.vhd     
#vcom -2008 ../rtl/nf_router_mux.vhd  
#vcom -2008 ../rtl/nf_top.vhd
#
#vlog ../tb/nf_pars.sv
#vlog ../tb/nf_tb.sv

vcom -2008 ../inc/nf_mem_pkg.vhd
vcom -2008 ../inc/nf_program.vhd
vcom -2008 ../rtl/periphery/nf_ram.vhd
vcom -2008 ../tb/nf_ram_test.vhd


vsim -novopt work.nf_ram_test

add wave -position insertpoint sim:/nf_ram_test/*

run -all

wave zoom full

#quit
