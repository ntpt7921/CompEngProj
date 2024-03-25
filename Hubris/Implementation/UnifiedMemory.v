/*
* NOTE:
* this module is a wrapper for InstMemory and DataMemory to bring them
* under one address space the address space will be segmented into 2, from
* low to high address
* - InstMemory part (0 -> InstMemorySize)
* - DataMemory part (InstMemorySize + 1 -> InstMemorySize + DataMemorySize)
* if we allocated 16KiB for inst and data each, then 
* - inst mem (code) maps into 0x0000 to 0x3fff
* - data mem maps into 0x4000 to 0x7fff
* currently there are separate port for inst and data memory, following the 
* Harvard model (separate data & inst mem) -> so addr applied to each port 
* will only have their upper bits cleared, without much routing logic
*/


module UnifiedMemory #(
    parameter MEMORY_WIDTH_IN_BYTE = 4,
    parameter MEMORY_WIDTH_IN_BIT = MEMORY_WIDTH_IN_BYTE * 8,
    parameter INST_SIZE_IN_WORD = 4096,
    parameter INST_SIZE_IN_BYTE = INST_SIZE_IN_WORD * 4,
    parameter INST_SIZE_ADDR_BIT_SIZE = $clog2(INST_SIZE_IN_BYTE),
    parameter DATA_SIZE_IN_WORD = 4096,
    parameter DATA_SIZE_IN_BYTE = INST_SIZE_IN_WORD * 4,
    parameter DATA_SIZE_ADDR_BIT_SIZE = $clog2(DATA_SIZE_IN_BYTE)
)(
    input clk,
    // for inst
    // address to bytes, misalignement allowed
    // always return 4 bytes of continuous memory from addr
    input [31:0] inst_addr, 
    input inst_write_enable,
    input [3:0] inst_write_width,
    input [MEMORY_WIDTH_IN_BIT-1:0] inst_write_data,
    output [MEMORY_WIDTH_IN_BIT-1:0] inst_read_data,
    // for data
    // address to bytes, misalignement allowed
    // always return 4 bytes of continuous memory from addr
    input [31:0] data_addr, 
    input data_write_enable,
    input [3:0] data_write_width,
    input [MEMORY_WIDTH_IN_BIT-1:0] data_write_data,
    output [MEMORY_WIDTH_IN_BIT-1:0] data_read_data
);

    // applied bit mask magic to clear higher unused bit in addr to inst and data
    wire [MEMORY_WIDTH_IN_BIT-1:0] inst_addr_clear_higher = 
        (inst_addr) & ~(-32'd1 << INST_SIZE_ADDR_BIT_SIZE);
    wire [MEMORY_WIDTH_IN_BIT-1:0] data_addr_clear_higher = 
        (data_addr) & ~(-32'd1 << DATA_SIZE_ADDR_BIT_SIZE);
     

    // instanciate both memory module
    InstMemory #(
        .MEMORY_DEPTH_IN_WORD(INST_SIZE_IN_WORD)
    ) inst_memory_instance (
        .clk(clk),
        // address to bytes, misalignement allowed
        // always return 4 bytes of continuous memory from addr
        .addr(inst_addr_clear_higher), 
        .write_enable(inst_write_enable),
        .write_width(inst_write_width),
        .write_data(inst_write_data),
        .read_data(inst_read_data)
    );

    DataMemory #(
        .MEMORY_DEPTH_IN_WORD(DATA_SIZE_IN_WORD)
    ) data_memory_instance (
        .clk(clk),
        // address to bytes, misalignement allowed
        // always return 4 bytes of continuous memory from addr
        .addr(data_addr_clear_higher), 
        .write_enable(data_write_enable),
        .write_width(data_write_width),
        .write_data(data_write_data),
        .read_data(data_read_data)
    );

endmodule
