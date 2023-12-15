module tb;

    reg clk;
    reg [4:0] read_reg1_addr;
    reg [4:0] read_reg2_addr;
    wire [31:0] read_reg1_data;
    wire [31:0] read_reg2_data;
    reg write_enable;
    reg [4:0] write_reg_addr;
    reg [31:0] write_data;
    reg [3:0] write_byte_mask;

    RegisterFile sut (
        .clk(clk),
        .read_reg1_addr(read_reg1_addr), .read_reg2_addr(read_reg2_addr),
        .read_reg1_data(read_reg1_data), .read_reg2_data(read_reg2_data),
        .write_enable(write_enable),
        .write_reg_addr(write_reg_addr),
        .write_data(write_data), .write_byte_mask(write_byte_mask)
    );

    always begin
        #1 clk = ~clk;
    end

    integer i;

    task test_write_full_byte;
        begin
            $display("---%s---", "Start test write full byte");
            $display("%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s", 
                "clk", "wr_en", "wr_addr", "wr_d", 
                "rd_reg1", "rd_reg2", "rd_dt1", "rd_dt2");

            clk = 0;
            write_byte_mask = 4'b1111;

            write_enable = 1;
            for (i = 0; i < 32; i = i + 1) begin

                read_reg1_addr = i - 1;
                read_reg2_addr = i;

                write_reg_addr = i;
                write_data = i;
                // wait after posedge
                @(negedge clk);  

            end

            $display("---%s---", "Done test write full byte");
        end
    endtask

    task test_read;
        begin
            $display("---%s---", "Start test read");
            $display("%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s", 
                "clk", "wr_en", "wr_addr", "wr_d", 
                "rd_reg1", "rd_reg2", "rd_dt1", "rd_dt2");

            clk = 0;
            write_byte_mask = 4'b1111;
            write_enable = 0;
            for (i = 0; i < 32; i = i + 1) begin

                read_reg1_addr = i;
                read_reg2_addr = i;
                #1;

            end

            $display("---%s---", "Done test read");
        end
    endtask

    task test_write_second_byte;
        begin
            $display("---%s---", "Start test write second byte");
            $display("%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s", 
                "clk", "wr_en", "wr_addr", "wr_d", 
                "rd_reg1", "rd_reg2", "rd_dt1", "rd_dt2");

            clk = 0;
            write_data = {32{1'b1}};
            write_byte_mask = 4'b0010;
            write_enable = 1;
            for (i = 0; i < 32; i = i + 1) begin

                read_reg1_addr = i - 1;
                read_reg2_addr = i;

                write_reg_addr = i;
                // wait after posedge
                @(negedge clk);  

            end

            $display("---%s---", "Done test write second byte");
        end
    endtask



    initial begin
        test_write_full_byte();
        test_read();
        test_write_second_byte();
        $finish;
    end

    initial begin
        $monitor("%0h\t%0h\t%0h\t%0h\t%0h\t%0h\t%0h\t%0h", 
            clk, write_enable, write_reg_addr, write_data, 
            read_reg1_addr, read_reg2_addr, read_reg1_data, read_reg2_data);
    end

endmodule
