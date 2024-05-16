.section .text
	.globl start
	.globl main
        .globl io_output_bytes_avai
        .globl io_output_bytes

start:
        la a0, user_data
        li t0, 0x11
        li t1, 0x2222
        sb t0, 3(a0)
        sh t1, 6(a0)

	/* trap */
	unimp

.section .data
user_data:
        .fill 8, 4, 0xFDFDFDFD

