#
#  File            :   run_rvc_gen.py
#  Autor           :   Vlasov D.V.
#  Data            :   2019.05.26
#  Language        :   Python
#  Description     :   This is script for generating run script for rvc test
#  Copyright(c)    :   2018 - 2019 Vlasov D.V.
#

import sys

print(sys.argv[1])

map_file = open("program_file/main.map" , "r")

out_file_f = open("run/rvc_run.tcl"  , "w")

out_file_f.write('''vcom -2008 ../inc/*.vhd                     -work nf
vcom -2008 ../program_file/*.vhd            -work nf

vcom -2008  ../rtl/core/*.vhd
vcom -2008  ../rtl/common/*.vhd
vcom -2008  ../rtl/periphery/*.vhd
vcom -2008  ../rtl/periphery/pwm/*.vhd
vcom -2008  ../rtl/periphery/gpio/*.vhd
vcom -2008  ../rtl/periphery/uart/*.vhd
vcom -2008  ../rtl/bus/ahb/*.vhd
vcom -2008  ../rtl/top/*.vhd

vcom -2008  ../tb/nf_tb_def.vhd             -work nf
vcom -2008  ../tb/nf_tb.vhd

''')

out_file_f.write( str( "vsim -novopt work.nf_tb\n" ) )

out_file_f.write('''add wave -divider  "pipeline stages"
add wave -position insertpoint sim:/nf_tb/instruction_if_stage
add wave -position insertpoint sim:/nf_tb/instruction_id_stage
add wave -position insertpoint sim:/nf_tb/instruction_iexe_stage
add wave -position insertpoint sim:/nf_tb/instruction_imem_stage
add wave -position insertpoint sim:/nf_tb/instruction_iwb_stage
add wave -divider  "load store unit"
add wave -position insertpoint sim:/nf_tb/nf_top_ahb_0/nf_cpu_0/nf_i_lsu_0/*
add wave -divider  "core singals"
add wave -position insertpoint sim:/nf_tb/nf_top_ahb_0/nf_cpu_0/*
add wave -divider  "hasard stall & flush singals"
add wave -position insertpoint sim:/nf_tb/nf_top_ahb_0/nf_cpu_0/nf_hz_stall_unit_0/*
add wave -divider  "cc unit singals"
add wave -position insertpoint sim:/nf_tb/nf_top_ahb_0/nf_cpu_cc_0/*
add wave -divider  "instruction fetch unit"
add wave -position insertpoint sim:/nf_tb/nf_top_ahb_0/nf_cpu_0/nf_i_fu_0/*
add wave -divider  "csr singals"
add wave -position insertpoint sim:/nf_tb/nf_top_ahb_0/nf_cpu_0/nf_csr_0/*
add wave -divider  "testbench signals"
add wave -position insertpoint sim:/nf_tb/*

run -all
''')

start_addr = "0x2030"
end_addr = "0x20e0"

for lines in map_file:
    if(lines.find("begin_signature")!=-1):
        start_addr = lines.replace(" ", "")[0:18]
    if(lines.find("end_signature")!=-1):
        end_addr = lines.replace(" ", "")[0:18]

out_file_f.write(str("mem save -o ../program_file/{:s}/mem.hex -f hex -noaddress -startaddress {:d} -endaddress {:d} /nf_tb/nf_top_ahb_0/nf_ram_i_d_0/ram\n".format(sys.argv[1], int(start_addr,16), int(end_addr,16) ) ) )

out_file_f.write('''quit''')
