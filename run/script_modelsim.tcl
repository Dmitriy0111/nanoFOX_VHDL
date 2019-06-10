
vlib work

vcom -2008 ../inc/*.vhd                     -work nf
vcom -2008 ../program_file/nf_program.vhd   -work nf

vcom -2008 ../inc/*.vhd
vcom -2008 ../rtl/*.vhd

vcom -2008  ../tb/nf_tb_def.vhd             -work nf
vcom -2008  ../tb/nf_tb.vhd

vsim -novopt work.nf_tb

add wave -position insertpoint sim:/nf_tb/nf_top_0/*

run -all

wave zoom full

#quit
