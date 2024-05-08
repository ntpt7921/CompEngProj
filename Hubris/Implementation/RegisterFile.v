`define REGISTER_FILE_WRITE_WIDTH_BYTE 4'd1
`define REGISTER_FILE_WRITE_WIDTH_HALF 4'd2
`define REGISTER_FILE_WRITE_WIDTH_WORD 4'd4

/*
* NOTE: Functionality
* 2 combinational read port, output value of reg specified with write value bypass
* 1 synchronous/asynchronous write with specified width (1, 2 or 4 bytes)
*   - when write smaller than register's size, 0-fill all upper bits
*   - written value is bypassed to the read output in case read_addr = write_addr
* Register x0 is special, its value when read is always 0
*/

module RegisterFile #(
    parameter REG_NUMBER = 32,
    parameter REG_ADDR_WIDTH = $clog2(REG_NUMBER),
    parameter REG_WIDTH_IN_BYTE = 4,
    parameter REG_WIDTH_IN_BIT = REG_WIDTH_IN_BYTE * 8
)(
    input clk,
    input reset,
    input [REG_ADDR_WIDTH-1:0] read_reg1_addr,
    input [REG_ADDR_WIDTH-1:0] read_reg2_addr,
    output reg [REG_WIDTH_IN_BIT-1:0] read_reg1_data,
    output reg [REG_WIDTH_IN_BIT-1:0] read_reg2_data,
    input write_enable,
    // take input equal to constant defined at the top to choose write width
    input [3:0] write_width,
    input [REG_ADDR_WIDTH-1:0] write_reg_addr,
    input [REG_WIDTH_IN_BIT-1:0] write_data
);

    reg [REG_WIDTH_IN_BIT-1:0] regfile [0:REG_NUMBER-1];

    // reset and write part
    integer i;
    always @(posedge clk) begin 

        if (reset) begin
            for (i = 0; i < REG_NUMBER; i = i + 1) begin
                regfile[i] <= {REG_WIDTH_IN_BIT {1'b0}};
            end
        end
        else if (write_enable)
            if (write_reg_addr != 0) // not x0
                regfile[write_reg_addr] <= write_data;

        regfile[0] <= 0;    // make sure x0 is always 0

    end

    // reading part
    always @(*) begin

        if (read_reg1_addr == write_reg_addr && write_enable)
            if (read_reg1_addr != 0)
                read_reg1_data = write_data;
            else
                read_reg1_data = 0;
        else
            read_reg1_data = regfile[read_reg1_addr];

        if (read_reg2_addr == write_reg_addr && write_enable)
            if (read_reg2_addr != 0)
                read_reg2_data = write_data;
            else
                read_reg2_data = 0;
        else
            read_reg2_data = regfile[read_reg2_addr];

    end

endmodule
