`define DATAMEMORY_WRITE_WIDTH_BYTE 1
`define DATAMEMORY_WRITE_WIDTH_HALF 2
`define DATAMEMORY_WRITE_WIDTH_WORD 4

/*
* NOTE:
* this module implements the unified memory with flat address space with no
* mis-aligned write allowed. it assume that memory read can be one within the
* same cycle, while write takes one cycle to complete 
* this module perform combinational read for 4 consecutive bytes starting from
* addr with synchronous write with specified width (1, 2 or 4 bytes)
*   - 2 read port (combinational)
*   - 1 write port (synchronous, 1 cycle, only aligned)
*/

module NewUnifiedMemory #(
    parameter MEMORY_WIDTH_IN_BYTE = 4,
    parameter MEMORY_WIDTH_IN_BIT = MEMORY_WIDTH_IN_BYTE * 8,
    parameter MEMORY_DEPTH_IN_WORD = 4096,
    parameter MEMORY_DEPTH_IN_BYTE = MEMORY_DEPTH_IN_WORD * 4
)(
    input clk,
    // read
    input [31:0] addr_read_0,
    input [31:0] addr_read_1,
    output [MEMORY_WIDTH_IN_BIT-1:0] read_data_0,
    output [MEMORY_WIDTH_IN_BIT-1:0] read_data_1,
    // write
    input write_en, // active high
    input [3:0] write_width,
    input [31:0] addr_write,
    input [MEMORY_WIDTH_IN_BIT-1:0] write_data
);

    reg [7:0] mem [0:MEMORY_DEPTH_IN_BYTE-1];

    // read part
    assign read_data_0 = { mem[addr_read_0+3], mem[addr_read_0+2], mem[addr_read_0+1], mem[addr_read_0] };
    assign read_data_1 = { mem[addr_read_1+3], mem[addr_read_1+2], mem[addr_read_1+1], mem[addr_read_1] };

    // write part
    always @(posedge clk) begin

        if (write_en) begin

            case (write_width)

                `DATAMEMORY_WRITE_WIDTH_BYTE:
                    mem[addr_write] <= write_data[7:0];

                `DATAMEMORY_WRITE_WIDTH_HALF:
                    begin 
                    mem[addr_write] <= write_data[7:0];
                    mem[addr_write+1] <= write_data[15:8];
                    end

                `DATAMEMORY_WRITE_WIDTH_WORD:
                    begin 
                    mem[addr_write] <= write_data[7:0];
                    mem[addr_write+1] <= write_data[15:8];
                    mem[addr_write+2] <= write_data[23:16];
                    mem[addr_write+3] <= write_data[31:24];
                    end

                default:
                    // in case the write width is unrecognized
                    // do not write anything
                    ;

            endcase

        end

    end

endmodule
