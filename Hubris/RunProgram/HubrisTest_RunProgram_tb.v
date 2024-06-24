`timescale 10ns/10ns

`define STRING reg [8*64:1]
`define EXECUTION_CLK_LIMIT 1000000
`define CLK_PERIOD_NS 20
`define UART_INTERNAL_CLK_PER_BAUD 4
`define BAUD_PERIOD_NS (`CLK_PERIOD_NS * `UART_INTERNAL_CLK_PER_BAUD)

module HubrisTest_RunProgram_tb();
    reg clk;
    reg reset;
    wire halt;
    // memory port A
    wire en_a;
    wire [3:0] we_a;
    wire [31:0] addr_a;
    wire [31:0] din_a;
    wire [31:0] dout_a;
    // memory port B
    wire en_b;
    wire [3:0] we_b;
    wire [31:0] addr_b;
    wire [31:0] din_b;
    wire [31:0] dout_b;
    // external output io
    reg io_input_rx;
    wire io_output_tx;
    // for reading output uart from hubris
    wire have_byte_rx;
    wire [7:0] byte_rx;

    Hubris #(
        .REG_NUMBER(32), 
        .INST_START_ADDR(32'b0),
        // IO spec
        .OUTPUT_BUFFER_BYTE_SIZE(64),
        .INPUT_BUFFER_BYTE_SIZE(16),
        .UART_INTERNAL_CLK_PER_BAUD(`UART_INTERNAL_CLK_PER_BAUD)
    ) dut (
        .clk(clk),
        .reset(reset),
        .halt(halt),
        // memory port A
        .en_a(en_a),
        .we_a(we_a),
        .addr_a(addr_a),
        .din_a(din_a),
        .dout_a(dout_a),
        // memory port B
        .en_b(en_b),
        .we_b(we_b),
        .addr_b(addr_b),
        .din_b(din_b),
        .dout_b(dout_b),
        // external output io
        .io_input_rx(io_input_rx),
        .io_output_tx(io_output_tx)
    );

    NewUnifiedMemory #(
        .MEMORY_WIDTH_IN_BYTE(4),
        .MEMORY_DEPTH_IN_WORD(1048576) // 4MiB
    ) unified_memory_instance (
        // port A - general use
        .clk_a(clk),
        .reset_a(reset),
        .en_a(en_a),
        .we_a(we_a),
        .addr_a(addr_a),
        .din_a(din_a),
        .dout_a(dout_a),
        // port B - instruction fetch
        .clk_b(clk),
        .reset_b(reset),
        .en_b(en_b),
        .we_b(we_b),
        .addr_b(addr_b),
        .din_b(din_b),
        .dout_b(dout_b)
    );

    uart_rx #(
        .CLKS_PER_BIT(`UART_INTERNAL_CLK_PER_BAUD)
    ) uart_reader (
        .i_Clock(clk),
        .i_Rx_Serial(io_output_tx),
        .o_Rx_Done(have_byte_rx),
        .o_Rx_Byte(byte_rx)
    );

    task get_binary_file_name;
        output `STRING file_name_out;
        output reg file_name_found;

        begin 
            if (!$value$plusargs("bin=%s", file_name_out)) begin
                $display("No program file name found");
                file_name_found = 0;
                $finish;
            end
            else begin
                $display("Program file name: %s", file_name_out);
                file_name_found = 1;
            end
        end
    endtask

    task load_binary_into_hubris_mem;
        input `STRING file_name;
        integer i;

        begin 
            // write to memory
            $readmemh(file_name, unified_memory_instance.mem);

            // debug - print back
            /*
            $display("Debug - print back content from memory");
            for (i = 0; i < 100; i = i + 1) begin 
                $display("%h", dut.unified_memory_instance.mem[i]);
            end
            */
        end
    endtask

    task load_memory;
        `STRING file_name;
        reg file_name_found;

        begin 
            get_binary_file_name(file_name, file_name_found);
            if (file_name_found) begin 
                load_binary_into_hubris_mem(file_name);
            end
        end
    endtask

    task invoke_reset;
        integer i;

        begin 
            reset = 1;
            for (i = 0; i < 5; i = i + 1)
                @(posedge clk);
            @(negedge clk);
            reset = 0;
        end
    endtask 

    task get_final_state_regstat_file_name;
        output `STRING file_name_out;
        output reg file_name_found;

        begin 
            if (!$value$plusargs("regstat=%s", file_name_out)) begin
                $display("No regstat log file name found");
                file_name_found = 0;
            end
            else begin
                $display("Regstat log file name: %s", file_name_out);
                file_name_found = 1;
            end
        end
    endtask

    task get_final_state_memdump_file_name;
        output `STRING file_name_out;
        output reg file_name_found;

        begin 
            if (!$value$plusargs("memdump=%s", file_name_out)) begin
                $display("No memory dump file name found");
                file_name_found = 0;
            end
            else begin
                $display("Memory dump file name: %s", file_name_out);
                file_name_found = 1;
            end
        end
    endtask

    task write_regstat_to_file;
        input `STRING file_name;
        integer i;
        integer fd;

        begin 
            fd = $fopen(file_name, "w");
            $fwrite(fd, "{");

                $fwrite(fd, "\"pc\": %0d,", dut.pc);

                $fwrite(fd, "\"regfile\":{");

                    for (i = 0; i < 31; i = i + 1)
                        $fwrite(fd, "\"x%0d\":%0d,", i, dut.register_file_instance.regfile[i]);
                    $fwrite(fd, "\"x%0d\":%0d", i, dut.register_file_instance.regfile[31]);

                $fwrite(fd, "},");

                $fwrite(fd, "\"csr\":{");

                    $fwrite(fd, "\"cycle\":%0d,", dut.zicntr_reg_instance.cycle_reg);
                    $fwrite(fd, "\"time\":%0d,", dut.zicntr_reg_instance.time_reg);
                    $fwrite(fd, "\"instret\":%0d", dut.zicntr_reg_instance.instret_reg);

                $fwrite(fd, "}");

            $fwrite(fd, "}");
            $fclose(fd);
        end
    endtask

    task dump_memory_to_file;
        input `STRING file_name;
        integer i;
        integer mem_word_count;
        integer fd;

        // NOTE: dump data memory to binary file
        // each fwrite with %u format write a 32 bit value, so read 4 memory cell
        // if the memory is not a multiple of 4 bytes in size, bad thing happens

        begin 
            mem_word_count = unified_memory_instance.MEMORY_DEPTH_IN_WORD;

            fd = $fopen(file_name, "wb");
            for (i = 0; i < mem_word_count; i = i + 1) begin
                $fwrite(fd, "%u", unified_memory_instance.mem[i]);
            end
        end
    endtask

    task report_hubris_internal_state;
        // output these info as JSON
        // - pc 
        // - register file
        // write memory dump to file
        `STRING file_name;
        reg file_name_found;

        begin 
            get_final_state_regstat_file_name(file_name, file_name_found);
            if (file_name_found) begin 
                write_regstat_to_file(file_name);
            end

            get_final_state_memdump_file_name(file_name, file_name_found);
            if (file_name_found) begin 
                dump_memory_to_file(file_name);
            end
        end
    endtask

    task print_statistics;
        begin
            $display("Halt at time=%0d", $time);
            $display("Total run clk cycle=%0d", clk_count);
        end
    endtask

    // Takes in input byte and serializes it 
    task write_uart_to_hubris;
        input [7:0] data_byte;
        integer     i;
        begin
            // Send Start Bit
            io_input_rx <= 1'b0;
            #(`BAUD_PERIOD_NS);

            // Send Data Byte
            for (i = 0; i < 8; i = i + 1)
            begin
                io_input_rx <= data_byte[i];
                #(`BAUD_PERIOD_NS);
            end

            // Send Stop Bit
            io_input_rx <= 1'b1;
            #(`BAUD_PERIOD_NS);
        end
    endtask

    // count clock cycle
    reg is_running;
    integer clk_count;

    always @(posedge clk) begin 
        if (reset)
            clk_count <= 0;
        else
            clk_count <= clk_count + 1;

        if (clk_count > `EXECUTION_CLK_LIMIT) begin
            $display("Execution clk limit reached: %0d", `EXECUTION_CLK_LIMIT);
            report_hubris_internal_state();
            $finish;
        end
    end

    // read output io buffer and print content
    always @(posedge clk) begin 
        if (have_byte_rx)
            $write("%c", byte_rx);
            $fflush();
    end

    initial begin 
        if ($test$plusargs("sigdebug")) begin
            $dumpfile("signal_debug.vcd");
            $dumpvars(0, HubrisTest_RunProgram_tb);
        end

        invoke_reset();
        load_memory();
 
        write_uart_to_hubris("h");
        write_uart_to_hubris("e");
        write_uart_to_hubris("l");
        write_uart_to_hubris("l");
        write_uart_to_hubris("o");
        write_uart_to_hubris("\n");
        wait(halt == 1); // wait for halt
        is_running = 0;

        // finish running, output state and stats
        report_hubris_internal_state();
        print_statistics();

        $finish;
    end

    initial begin
        clk = 0;
        forever #(`CLK_PERIOD_NS/2) clk = !clk;
    end

endmodule
