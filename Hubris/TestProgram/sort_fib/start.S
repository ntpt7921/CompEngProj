.section .text
	.globl start
	.globl main
        .globl io_output_bytes_avai
        .globl io_output_bytes

start:
	/* set stack pointer */
	lui sp,(32*1024)>>12

	/* jump to main C code */
	jal ra,main

        call wait_for_uart
	/* trap */
	unimp

wait_for_uart:
    la t0, io_output_bytes_avai
    li t1, 64
.L1:
    # wait for output buffer to be flushed/printed
    lw t2, 0(t0)
    bne t1, t2, .L1
    li t0, 1000
.L2:
    # wait some more time for last char
    addi t0, t0, -1
    bnez t0, .L2
    ret
