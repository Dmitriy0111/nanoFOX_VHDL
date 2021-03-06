#
#  File            :   boot.S
#  Autor           :   Vlasov D.V.
#  Data            :   2019.03.03
#  Language        :   Assembler
#  Description     :   This is Assembler file for first initialization nanoFOX
#  Copyright(c)    :   2018 - 2019 Vlasov D.V.
#

.equ    _stack_start,   0x00001000  # 400 << 2

nanoFOX_vectors:
        j _main         # reset vector (0x00 vector)
        j vector_1      # 0x01  vector
        j vector_2      # 0x02  vector
        j vector_3      # 0x03  vector
        j vector_4      # 0x04  vector
        j vector_5      # 0x05  vector
        j vector_6      # 0x06  vector
        j vector_7      # 0x07  vector
        j vector_8      # 0x08  vector
        j vector_9      # 0x09  vector
        j vector_10     # 0x0a  vector
        j vector_11     # 0x0b  vector
        j vector_12     # 0x0c  vector
        j vector_13     # 0x0d  vector
        j vector_14     # 0x0e  vector
        j vector_15     # 0x0f  vector

_main:
_clean_registers:
        lui  ra,   0x00
        lui  sp,   0x00
        lui  gp,   0x00
        lui  tp,   0x00
        lui  t0,   0x00
        lui  t1,   0x00
        lui  t2,   0x00
        lui  s0,   0x00
        lui  s1,   0x00
        lui  a0,   0x00
        lui  a1,   0x00
        lui  a2,   0x00
        lui  a3,   0x00
        lui  a4,   0x00
        lui  a5,   0x00
        lui  a6,   0x00
        lui  a7,   0x00
        lui  s2,   0x00
        lui  s3,   0x00
        lui  s4,   0x00
        lui  s5,   0x00
        lui  s6,   0x00
        lui  s7,   0x00
        lui  s8,   0x00
        lui  s9,   0x00
        lui  s10,  0x00
        lui  s11,  0x00
        lui  t3,   0x00
        lui  t4,   0x00
        lui  t5,   0x00
        lui  t6,   0x00
load_sp:
        lui  sp,     %hi(_stack_start)  # load stack pointer value
        addi sp, sp, %lo(_stack_start)  # load stack pointer value
        j    main
