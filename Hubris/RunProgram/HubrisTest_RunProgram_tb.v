`define STRING reg [8*64:1]
`define EXECUTION_CLK_LIMIT 1000000

module HubrisTest_RunProgram_tb();
    reg clk;
    reg reset;
    wire halt;

    Hubris #(
        .REG_NUMBER(32),
        .INST_START_ADDR(32'b0)
    ) dut (
        .clk(clk),
        .reset(reset),
        .halt(halt)
    );

    task get_binary_program_file_name;
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

    task zero_memory;
        integer memory_byte_count;
        integer i;

        begin 
            // clear memory to all 0
            memory_byte_count = 
                dut.unified_memory_instance.inst_memory_instance.MEMORY_WIDTH_IN_BYTE 
                * dut.unified_memory_instance.inst_memory_instance.MEMORY_DEPTH_IN_WORD;

            for (i = 0; i < memory_byte_count; i = i + 1)
                dut.unified_memory_instance.inst_memory_instance.mem[i] = 0;

            memory_byte_count = 
                dut.unified_memory_instance.data_memory_instance.MEMORY_WIDTH_IN_BYTE 
                * dut.unified_memory_instance.data_memory_instance.MEMORY_DEPTH_IN_WORD;

            for (i = 0; i < memory_byte_count; i = i + 1)
                dut.unified_memory_instance.data_memory_instance.mem[i] = 0;
        end
    endtask

    task load_binary_into_hubris_instruction_mem;
        input `STRING file_name;
        integer i;

        begin 
            // write to memory
            $readmemh(file_name, dut.unified_memory_instance.inst_memory_instance.mem);

            // debug - print back
            /*
            for (i = 0; i < 100; i = i + 1) begin 
                $display("%d", dut.inst_memory_instance.mem[i]);
            end
            */
        end
    endtask

    task load_program;
        `STRING file_name;
        reg file_name_found;

        begin 
            get_binary_program_file_name(file_name, file_name_found);
            if (file_name_found) begin 
                load_binary_into_hubris_instruction_mem(file_name);
            end
        end
    endtask

    task invoke_reset;
        integer i;

        begin 
            reset = 1;
            for (i = 0; i < 4; i = i + 1)
                @(posedge clk);
            @(negedge clk);
            reset = 0;
        end
    endtask 

    task get_final_state_log_file_name;
        output `STRING file_name_out;
        output reg file_name_found;

        begin 
            if (!$value$plusargs("log=%s", file_name_out)) begin
                $display("No log file name found");
                file_name_found = 0;
            end
            else begin
                $display("Log file name: %s", file_name_out);
                file_name_found = 1;
            end
        end
    endtask

    task write_final_state_into_log_file;
        input `STRING file_name;
        integer i;
        integer memory_byte_count;
        integer fd;

        begin 
            memory_byte_count = 
                dut.unified_memory_instance.data_memory_instance.MEMORY_WIDTH_IN_BYTE 
                * dut.unified_memory_instance.data_memory_instance.MEMORY_DEPTH_IN_WORD;

            fd = $fopen(file_name, "w");
            $fwrite(fd, "{");

                $fwrite(fd, "\"pc\": %0d,", dut.pc);

                $fwrite(fd, "\"regfile\":{");
                    for (i = 0; i < 31; i = i + 1)
                        $fwrite(fd, "\"x%0d\":%0d,", i, dut.register_file_instance.regfile[i]);
                    $fwrite(fd, "\"x%0d\":%0d", i, dut.register_file_instance.regfile[31]);
                $fwrite(fd, "},");

                // TODO: change this to dump data mem into a separate file

                $fwrite(fd, "\"datamem\":{");
                    for (i = 0; i < memory_byte_count - 1; i = i + 1)
                        $fwrite(fd, "\"%0d\":%0d,", i, dut.unified_memory_instance.data_memory_instance.mem[i]);
                    $fwrite(fd, "\"%0d\":%0d", i, dut.unified_memory_instance.data_memory_instance.mem[memory_byte_count - 1]);
                $fwrite(fd, "}");

            $fwrite(fd, "}");
            $fclose(fd);
        end
    endtask

    task report_hubris_internal_state;
        // output these info as JSON
        // - pc 
        // - register file
        // - data memory
        `STRING file_name;
        reg file_name_found;

        begin 
            get_final_state_log_file_name(file_name, file_name_found);
            if (file_name_found) begin 
                write_final_state_into_log_file(file_name);
            end
        end
    endtask

    task print_statistics;
        begin
            $display("Halt at time=%0d", $time);
            $display("Total run clk cycle=%0d", clk_count);
        end
    endtask

    reg is_running;
    integer clk_count;

    always @(posedge clk) begin 
        if (is_running)
            clk_count <= clk_count + 1;
    end

    initial begin 
        // $monitor("t=%0t clk=%1b reset=%1b", $time, clk, reset);
        zero_memory();
        load_program();
        invoke_reset();
 
        @(posedge clk);
        is_running = 1;
        clk_count = 1;
        wait(halt == 1); // wait for halt
        is_running = 0;

        // finish running, output state and stats
        report_hubris_internal_state();
        print_statistics();

        $finish;

    end

    initial begin
        clk = 0;
        forever #1 clk = !clk;
    end

endmodule
