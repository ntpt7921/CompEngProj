.globl io_output_bytes_avai
.globl io_output_bytes
.globl entry_point 
.globl main

.section .text
    entry_point:

/* print "START\n" */
la a0, io_output_bytes
addi a1,zero,'S'
addi a2,zero,'T'
addi a3,zero,'A'
addi a4,zero,'R'
addi a5,zero,'\n'
sw a1,0(a0)
sw a2,0(a0)
sw a3,0(a0)
sw a4,0(a0)
sw a2,0(a0)
sw a5,0(a0)

/* print "DONE\n" */
addi a1,zero,'D'
addi a2,zero,'O'
addi a3,zero,'N'
addi a4,zero,'E'
addi a5,zero,'\n'
sw a1,0(a0)
sw a2,0(a0)
sw a3,0(a0)
sw a4,0(a0)
sw a5,0(a0)

unimp

#----------------------------------
.section .data
    data_section_start:

.fill 8, 1, 0xFEFEFEFE
