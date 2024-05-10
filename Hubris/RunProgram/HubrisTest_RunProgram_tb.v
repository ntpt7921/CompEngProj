`define STRING reg [8*64:1]
`define EXECUTION_CLK_LIMIT 100000

module HubrisTest_RunProgram_tb();
    reg clk;
    reg reset;
    wire halt;
    // external output io
    reg io_output_en;
    wire [7:0] io_output_data;
    wire [31:0] io_buffer_size_avai;

    Hubris #(
        .REG_NUMBER(32),
        .INST_START_ADDR(32'b0)
    ) dut (
        .clk(clk),
        .reset(reset),
        .halt(halt),
        // io 
        .io_output_en(io_output_en),
        .io_output_data(io_output_data),
        .io_buffer_size_avai(io_buffer_size_avai)
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

    task zero_memory;
        integer memory_byte_count;
        integer i;

        begin 
            /*
            // - using old UnifiedMemory
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
            */

           // - using NewUnifiedMemory
           memory_byte_count = 
               dut.unified_memory_instance.MEMORY_WIDTH_IN_BYTE 
               * dut.unified_memory_instance.MEMORY_DEPTH_IN_WORD;

            for (i = 0; i < memory_byte_count; i = i + 1) 
                // - using old UnifiedMemory
                //dut.unified_memory_instance.inst_memory_instance.mem[i] = 0;
                // - using NewUnifiedMemory
                dut.unified_memory_instance.mem[i] = 0;
        end
    endtask

    task load_binary_into_hubris_mem;
        input `STRING file_name;
        integer i;

        begin 
            // write to memory
            // - using old UnifiedMemory
            //$readmemh(file_name, dut.unified_memory_instance.inst_memory_instance.mem);
            // - using NewUnifiedMemory
            $readmemh(file_name, dut.unified_memory_instance.mem);

            // debug - print back
            /*
            for (i = 0; i < 100; i = i + 1) begin 
                $display("%d", dut.inst_memory_instance.mem[i]);
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
            for (i = 0; i < 4; i = i + 1)
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
                $fwrite(fd, "}");
            $fwrite(fd, "}");
            $fclose(fd);
        end
    endtask

    task dump_memory_to_file;
        input `STRING file_name;
        integer i;
        integer memory_byte_count;
        integer fd;
        reg [31:0] temp;

        // NOTE: dump data memory to binary file
        // each fwrite with %u format write a 32 bit value, so read 4 memory cell
        // if the memory is not a multiple of 4 bytes in size, bad thing happens

        begin 
            // using old UnifiedMemory
            //memory_byte_count = dut.unified_memory_instance.DATA_SIZE_IN_BYTE;
            // using NewUnifiedMemory
           memory_byte_count = 
               dut.unified_memory_instance.MEMORY_WIDTH_IN_BYTE 
               * dut.unified_memory_instance.MEMORY_DEPTH_IN_WORD;

            fd = $fopen(file_name, "wb");
            for (i = 0; i < memory_byte_count; i = i + 4) begin
                temp =  {
                    // using old UnifiedMemory
                    //dut.unified_memory_instance.data_memory_instance.mem[i+3],
                    //dut.unified_memory_instance.data_memory_instance.mem[i+2],
                    //dut.unified_memory_instance.data_memory_instance.mem[i+1],
                    //dut.unified_memory_instance.data_memory_instance.mem[i]
                    // using NewUnifiedMemory
                    dut.unified_memory_instance.mem[i+3],
                    dut.unified_memory_instance.mem[i+2],
                    dut.unified_memory_instance.mem[i+1],
                    dut.unified_memory_instance.mem[i]
                    };
                $fwrite(fd, "%u", temp);
            end
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

    // count clock cycle
    reg is_running;
    integer clk_count;

    always @(posedge clk) begin 
        if (is_running)
            clk_count <= clk_count + 1;
        if (clk_count > `EXECUTION_CLK_LIMIT) begin
            $display("Execution clk limit reached: %0d", `EXECUTION_CLK_LIMIT);
            report_hubris_internal_state();
            $finish;
        end
    end

    // read output io buffer and print content
    always @(*)
        io_output_en = (io_buffer_size_avai > 0);

    always @(posedge clk) begin 
        if (io_buffer_size_avai > 0)
            $write("%c", io_output_data);
    end

    initial begin 
        if ($test$plusargs("sigdebug")) begin
            $dumpfile("signal_debug.vcd");
            $dumpvars(0, HubrisTest_RunProgram_tb);
        end

        // $monitor("t=%0t clk=%1b reset=%1b", $time, clk, reset);
        zero_memory();
        load_memory();
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
