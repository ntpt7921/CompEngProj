.section .text
	.globl start
	.globl main
        .globl io_output_bytes_avai
        .globl io_output_bytes

start:
	/* print "START\n" */
        la a0, io_output_bytes
	addi a1,zero,'S'
	addi a5,zero,'\n'
	sw a1,0(a0)
	sw a5,0(a0)

	/* set stack pointer */
	lui sp,(32*1024)>>12

	/* jump to main C code */
	jal ra,main

	/* print "DONE\n" */
        la a0, io_output_bytes
	addi a1,zero,'D'
	addi a5,zero,'\n'
	sw a1,0(a0)
	sw a5,0(a0)

	/* trap */
	unimp

