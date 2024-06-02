.section .text
	.globl start
        .globl io_output_bytes_avai
        .globl io_output_bytes
        .globl io_input_bytes_avai
        .globl io_input_bytes

start:
	/* set stack pointer */
	lui sp,(32*1024)>>12

        call wait_read_print_back_byte_from_uart
        call wait_read_print_back_byte_from_uart
        call wait_read_print_back_byte_from_uart
        call wait_read_print_back_byte_from_uart
        call wait_read_print_back_byte_from_uart
        call wait_read_print_back_byte_from_uart

        call wait_for_uart
	/* trap */
	unimp

wait_read_print_back_byte_from_uart:
    la a0, io_input_bytes
    la a1, io_input_bytes_avai
    la a2, io_output_bytes
    li t0, 16
.L3:
    lw t1, 0(a1) 
    beq t1, t0, .L3 # if input buffer still have not receive, loop
    lw t1, 0(a0) # t1 now have received byte
    sw t1, 0(a2) # print received byte
    ret

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
