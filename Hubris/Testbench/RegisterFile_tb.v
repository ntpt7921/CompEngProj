module tb;

    reg clk;
    reg [4:0] read_reg1_addr;
    reg [4:0] read_reg2_addr;
    wire [31:0] read_reg1_data;
    wire [31:0] read_reg2_data;
    reg write_enable;
    reg [4:0] write_reg_addr;
    reg [31:0] write_data;

    RegisterFile sut (
        .clk(clk),
        .read_reg1_addr(read_reg1_addr), .read_reg2_addr(read_reg2_addr),
        .read_reg1_data(read_reg1_data), .read_reg2_data(read_reg2_data),
        .write_enable(write_enable),
        .write_reg_addr(write_reg_addr),
        .write_data(write_data)
    );

    always begin
        #1 clk = ~clk;
    end

    integer i;

    initial begin
        clk = 0;

        write_enable = 1;
        for (i = 0; i < 32; i = i + 1) begin

            read_reg1_addr = i - 1;
            read_reg2_addr = i;

            write_reg_addr = i;
            write_data = i;
            // wait after posedge
            @(negedge clk);  

        end

        
        write_enable = 0;
        for (i = 0; i < 32; i = i + 1) begin

            read_reg1_addr = i;
            read_reg2_addr = i;
            assert(read_reg1_data == i);
            assert(read_reg2_data == i);
            #1;

        end

        
        $finish;
    end

    initial begin
        $display("%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s", 
            "clk", "wr_en", "wr_addr", "wr_d", 
            "rd_reg1", "rd_reg2", "rd_dt1", "rd_dt2");
        $monitor("%0h\t%0h\t%0h\t%0h\t%0h\t%0h\t%0h\t%0h", 
            clk, write_enable, write_reg_addr, write_data, 
            read_reg1_addr, read_reg2_addr, read_reg1_data, read_reg2_data);
    end

endmodule
