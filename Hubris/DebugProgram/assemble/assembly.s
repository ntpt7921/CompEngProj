.section .text
	.globl start
        .globl io_output_bytes_avai
        .globl io_output_bytes

start:
	/* print "START\n" */
        la a0, io_output_bytes
        la s0, io_output_bytes_avai
	addi a1,zero,'S'
	addi a2,zero,'T'
	addi a3,zero,'A'
	addi a4,zero,'R'
	addi a5,zero,'\n'
	sw a1,0(a0)
        lw s1,0(s0)

	sw a2,0(a0)
        lw s2,0(s0)

	sw a3,0(a0)
        lw s3,0(s0)

	sw a4,0(a0)
        lw s4,0(s0)

	sw a2,0(a0)
	sw a5,0(a0)
        lw s5,0(s0)

	/* set stack pointer */
	lui sp,(32*1024)>>12

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
