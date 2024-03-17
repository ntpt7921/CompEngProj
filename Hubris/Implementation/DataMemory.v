`define DATAMEMORY_WRITE_WIDTH_BYTE 1
`define DATAMEMORY_WRITE_WIDTH_HALF 2
`define DATAMEMORY_WRITE_WIDTH_WORD 4

/*
* NOTE:
* this module perform combinational read for 4 consecutive bytes starting from addr
* with synchronous write with specified width (1, 2 or 4 bytes)
*/

module DataMemory #(
    parameter MEMORY_WIDTH_IN_BYTE = 4,
    parameter MEMORY_WIDTH_IN_BIT = MEMORY_WIDTH_IN_BYTE * 8,
    parameter MEMORY_DEPTH_IN_WORD = 4096,
    parameter MEMORY_DEPTH_IN_BYTE = MEMORY_DEPTH_IN_WORD * 4
)(
    input clk,
    // address to bytes, misalignement allowed
    // always return 4 bytes of continuous memory from addr
    input [31:0] addr, 
    input write_enable,
    input [3:0] write_width,
    input [MEMORY_WIDTH_IN_BIT-1:0] write_data,
    output [MEMORY_WIDTH_IN_BIT-1:0] read_data
);

    reg [7:0] mem [0:MEMORY_DEPTH_IN_BYTE-1];

    always @(posedge clk) begin

        if (write_enable) begin

            case (write_width)

                `DATAMEMORY_WRITE_WIDTH_BYTE:
                    mem[addr] <= write_data[7:0];

                `DATAMEMORY_WRITE_WIDTH_HALF:
                    begin 
                    mem[addr] <= write_data[7:0];
                    mem[addr+1] <= write_data[15:8];
                    end

                `DATAMEMORY_WRITE_WIDTH_WORD:
                    begin 
                    mem[addr] <= write_data[7:0];
                    mem[addr+1] <= write_data[15:8];
                    mem[addr+2] <= write_data[23:16];
                    mem[addr+3] <= write_data[31:24];
                    end

                default:
                    // in case the write width is unrecognized
                    // do not write anything
                    mem[addr] <= mem[addr];

            endcase

        end

    end

    assign read_data = { mem[addr+3], mem[addr+2], mem[addr+1], mem[addr] };

endmodule
