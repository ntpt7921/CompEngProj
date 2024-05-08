.section .text
    .globl entry_point; 
    entry_point:

la a0, data_section_start
lb t1, 0(a0)
sw t1, 8(a0)
lh t2, 0(a0)
sw t2, 12(a0)

unimp

#----------------------------------
.section .data
    data_section_start:

.fill 8, 1, 0xFEFEFEFE
