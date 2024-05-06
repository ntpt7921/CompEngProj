.section .text
.equ DATA_START, 0x200000

addi x0, x0, 1
addi x1, x0, 1 
addi x2, x1, 1 
addi x3, x2, 1 
addi x4, x3, 1 

li a0, DATA_START
sw  x1, 0(a0)
sw  x2, 4(a0)
sw  x3, 8(a0)
sw  x4, 12(a0)

unimp
