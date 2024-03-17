`define REGISTER_FILE_WRITE_WIDTH_BYTE 1
`define REGISTER_FILE_WRITE_WIDTH_HALF 2
`define REGISTER_FILE_WRITE_WIDTH_WORD 4

/*
* NOTE: Functionality
* 2 combinational read port, output value of reg specified with write value bypass
* 1 synchronous/asynchronous write with specified width (1, 2 or 4 bytes)
*   - when write smaller than register's size, 0-fill all upper bits
*   - written value is bypassed to the read output in case read_addr = write_addr
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
    reg [REG_WIDTH_IN_BIT-1:0] masked_write_data;

    // writing part
    always @(*) begin
        
        masked_write_data = 0;

        case (write_width)

            `REGISTER_FILE_WRITE_WIDTH_BYTE:
                masked_write_data[7:0] = write_data[7:0];

            `REGISTER_FILE_WRITE_WIDTH_HALF:
                begin 
                masked_write_data[7:0] = write_data[7:0];
                masked_write_data[15:8] = write_data[15:8];
                end

            `REGISTER_FILE_WRITE_WIDTH_WORD:
                begin 
                masked_write_data[7:0] = write_data[7:0];
                masked_write_data[15:8] = write_data[15:8];
                masked_write_data[23:16] = write_data[23:16];
                masked_write_data[31:24] = write_data[31:24];
                end

            default:
                masked_write_data = {REG_WIDTH_IN_BIT {1'bx}};

        endcase

    end

    integer i;
    always @(posedge clk) begin 

        if (reset) begin
            for (i = 0; i < REG_NUMBER; i = i + 1) begin
                regfile[i] <= {REG_WIDTH_IN_BIT {1'b0}};
            end
        end
        else if (write_enable)
            regfile[write_reg_addr] = masked_write_data;

    end

    // reading part
    always @(*) begin

        if (read_reg1_addr == write_reg_addr && write_enable)
            read_reg1_data = masked_write_data;
        else
            read_reg1_data = regfile[read_reg1_addr];

        if (read_reg2_addr == write_reg_addr && write_enable)
            read_reg2_data = masked_write_data;
        else
            read_reg2_data = regfile[read_reg2_addr];

    end

endmodule
