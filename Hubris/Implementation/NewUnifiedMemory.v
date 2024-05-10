`define DATAMEMORY_WRITE_WIDTH_BYTE 4'd1
`define DATAMEMORY_WRITE_WIDTH_HALF 4'd2
`define DATAMEMORY_WRITE_WIDTH_WORD 4'd4

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

/*
* NOTE:
* this module also allows for memory-mapped IO, placed at addr 32'h8000_0000
* onward
*   - output takes 8 bytes (2 words), in order:
*       - output_bytes_avai (4 bytes) - 32'h8000_0000: can be read, contains
*       current number of available output buffer bytes. writing to this have no
*       effect
*       - output_bytes (4 bytes) - 32'h8000_0004: each write to this (at any width)
*       store a byte of output data situated at the least significant byte of
*       the write data. read to this return undefined value
*/

module NewUnifiedMemory #(
    // Memory spec
    parameter MEMORY_WIDTH_IN_BYTE = 4,
    parameter MEMORY_WIDTH_IN_BIT = MEMORY_WIDTH_IN_BYTE * 8,
    parameter MEMORY_DEPTH_IN_WORD = 4096,
    parameter MEMORY_DEPTH_IN_BYTE = MEMORY_DEPTH_IN_WORD * 4,
    // IO spec
    parameter OUTPUT_BUFFER_BYTE_SIZE = 32 
)(
    input clk,
    input reset,
    // read
    input [31:0] addr_read_0,
    input [31:0] addr_read_1,
    output reg [MEMORY_WIDTH_IN_BIT-1:0] read_data_0,
    output reg [MEMORY_WIDTH_IN_BIT-1:0] read_data_1,
    // write
    input write_en, // active high
    input [3:0] write_width,
    input [31:0] addr_write,
    input [MEMORY_WIDTH_IN_BIT-1:0] write_data,
    // external output io
    input io_output_en,
    output [7:0] io_output_data,
    output [31:0] io_buffer_size_avai
);

    reg [7:0] mem [0:MEMORY_DEPTH_IN_BYTE-1];

    // read part
    wire [31:0] read_data_0_mem = 
        { mem[addr_read_0+3], mem[addr_read_0+2], mem[addr_read_0+1], mem[addr_read_0] };
    wire [31:0] read_data_1_mem = 
        { mem[addr_read_1+3], mem[addr_read_1+2], mem[addr_read_1+1], mem[addr_read_1] };

    always @(*) begin

        if (addr_read_0 == 32'h8000_0000)
            read_data_0 = io_buffer_size_avai;
        else
            read_data_0 = read_data_0_mem;

        if (addr_read_1 == 32'h8000_0000)
            read_data_1 = io_buffer_size_avai;
        else
            read_data_1 = read_data_1_mem;
    end

    // write part
    always @(posedge clk) begin

        if (write_en && addr_write != 32'h8000_0000) begin

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

    DirectionalBuffer #(
        .BUFFER_BYTE_SIZE(OUTPUT_BUFFER_BYTE_SIZE)
    ) io_output_buffer (

        .clk(clk),
        .reset(reset),
        // read/write interface
        .input_en(write_en && (addr_write == 32'h8000_0004)),
        .input_data(write_data[7:0]),
        .buffer_size_avai(io_buffer_size_avai),
        .output_en(io_output_en),
        .output_data(io_output_data)
    );


endmodule
