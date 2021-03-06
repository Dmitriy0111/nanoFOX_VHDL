#
#  File            :   ihex2hex.py
#  Autor           :   Vlasov D.V.
#  Data            :   2019.03.04
#  Language        :   Python
#  Description     :   This is script for converting ihex format to hex
#  Copyright(c)    :   2018 - 2019 Vlasov D.V.
#

import sys

pars_file  = open("program_file/program.ihex" , "r")

out_file_f = open("program_file/nf_program.vhd"  , "w")    # full mem [31:0]

hi_addr = 0
out_file_f.write(str("\
library ieee;\n\
use ieee.std_logic_1164.all;\n\
use ieee.numeric_std.all;\n\
library work;\n\
use work.nf_mem_pkg.all;\n\
\n\
package nf_program is\n\
\n\
    constant program : mem_t({:s}*4-1 downto 0)(7 downto 0) := \
    ( ".format(sys.argv[1]) ) )

for lines in pars_file:
    # find checksum
    checksum = lines[-3:-1]
    lines = lines[0:-3]
    # break if end of record
    if( lines[7:9] == "01"):
        out_file_f.write("        others => X\"XX\"")
        break
    # update high address of linear record
    elif( lines[7:9] == "04"):
        hi_addr = int('0x'+lines[9:13],16)
    # record data
    elif( lines[7:9] == "00" ):
        # delete ':'
        lines = lines[1:]
        # find lenght
        lenght = int('0x'+lines[0:2],16)
        lines = lines[2:]
        # find addr
        lo_addr = int('0x'+lines[0:4],16)
        lines = lines[4:]
        # find type
        type_ = lines[0:2]
        lines = lines[2:]
        i = 0
        # write addr
        while(1):
            st_addr = str("        {:d}".format( ( ( hi_addr << 16 ) + lo_addr + i + 0 ) ) )
            out_file_f.write(st_addr + " => ")
            # write data
            out_file_f.write("X\"" + lines[0:2] + "\"" + ",\n")
            st_addr = str("        {:d}".format( ( ( hi_addr << 16 ) + lo_addr + i + 1 ) ) )
            out_file_f.write(st_addr + " => ")
            # write data
            out_file_f.write("X\"" + lines[2:4] + "\"" + ",\n")
            st_addr = str("        {:d}".format( ( ( hi_addr << 16 ) + lo_addr + i + 2 ) ) )
            out_file_f.write(st_addr + " => ")
            # write data
            out_file_f.write("X\"" + lines[4:6] + "\"" + ",\n")
            st_addr = str("        {:d}".format( ( ( hi_addr << 16 ) + lo_addr + i + 3 ) ) )
            out_file_f.write(st_addr + " => ")
            # write data
            out_file_f.write("X\"" + lines[6:8] + "\"" + ",\n")
            lines = lines[8:]
            i += 4
            if( i >= lenght ):
                break

out_file_f.write('''
    );

end package nf_program;
''')

print("Conversion comlete!")
