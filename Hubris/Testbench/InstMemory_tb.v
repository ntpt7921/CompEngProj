module tb;

    reg clk;
    reg [31:0] write_data;
    reg write_enable;
    reg [31:0] addr;
    wire [31:0] read_data;

    InstMemory sut (
        .addr(addr), .write_data(write_data), .write_enable(write_enable),
        .read_data(read_data), .clk(clk)
    );

    always begin
        #1 clk = ~clk;
    end

    initial begin
        clk = 0;
        write_data = 0;
        addr = 0;
        write_enable = 1;

        #2;

        write_data = 1;
        addr = 1;

        #2;

        write_enable = 0;
        addr = 0;

        #2;

        addr = 1;

        #1;

        $finish;
    end

    initial begin
        $display("%s\t%s\t%s\t\t%s\t\t%s", "clk", "wr_en", "addr", "wr_d", "rd_d");
        $monitor("%h\t%h\t%h\t%h\t%h", clk, write_enable, addr, write_data, read_data);
    end

endmodule
