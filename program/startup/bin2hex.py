#
#  File            :   bin2ihex.py
#  Autor           :   Vlasov D.V.
#  Data            :   2019.11.27
#  Language        :   Python
#  Description     :   This is script for converting binary to intel hex
#  Copyright(c)    :   2019 Vlasov D.V.
#

import sys

def calc_check_sum(address,data):
    sum = ( 0x04 +
          ( ( address >>  8 ) & 0xFF ) +
          ( ( address >>  0 ) & 0xFF ) +
          ( ( data    >> 24 ) & 0xFF ) +
          ( ( data    >> 16 ) & 0xFF ) +
          ( ( data    >>  8 ) & 0xFF ) +
          ( ( data    >>  0 ) & 0xFF )
          ) & 0xFF
    check_sum = ( (~sum) + 1 ) & 0xFF
    return check_sum

def bin2hex(bin_file_p,ihex_file_p):
    bin_data=bytearray(bin_file_p.read())

    while( len(bin_data) & 0x3 ):
        bin_data.append(0)

    num_rows=len(bin_data) >> 2
    row_format=":04{address:04X}00{data:08X}{check_sum:02X}\n"
    address=0
    for c in range(num_rows):
        data_row = int(bin_data[0]) + (int(bin_data[1]) << 8) + (int(bin_data[2]) << 16) + (int(bin_data[3]) << 24)
        row = row_format.format(address=address, data=data_row, check_sum=calc_check_sum(address, data_row))
        ihex_file_p.write(row)
        bin_data = bin_data[4:]
        address+=1
    ihex_file_p.write(":00000001FF")

print("bin2ihex start conversion!")

bin_file = open(sys.argv[1], "rb")
ihex_file = open(sys.argv[2], "w")

bin2hex(bin_file,ihex_file)

bin_file.close()
ihex_file.close()

print("bin2ihex conversion comlete!")
