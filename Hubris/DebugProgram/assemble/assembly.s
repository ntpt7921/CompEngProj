.globl io_output_bytes_avai
.globl io_output_bytes
.globl entry_point 
.globl main

#----------------------------------
.section .text
    entry_point:

rdcycle t0
rdtime t1
rdinstret t2

unimp

#----------------------------------
.section .data
    data_section_start:

.fill 8, 1, 0xFEFEFEFE
