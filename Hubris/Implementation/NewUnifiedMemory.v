/*
* NOTE:
* this module implements the unified memory with flat address space with no
* mis-aligned write allowed. it assume that memory read and write takes one 
* clock edge to complete.
*   - 1 read/write port (B) for instruction fetch, normally never write
*   - 1 read/write port (A) for general use
*/

module NewUnifiedMemory #(
    // Memory spec
    parameter MEMORY_WIDTH_IN_BYTE = 4,
    parameter MEMORY_WIDTH_IN_BIT = MEMORY_WIDTH_IN_BYTE * 8,
    parameter MEMORY_ADDR_TRUNCATE_BIT_NUMBER = $clog2(MEMORY_WIDTH_IN_BYTE),
    parameter MEMORY_DEPTH_IN_WORD = 4096,
    parameter MEMORY_DEPTH_IN_BYTE = MEMORY_DEPTH_IN_WORD * 4
)(
    // port A
    input clk_a,
    input reset_a,
    input en_a,
    input [3:0] we_a,
    input [31:0] addr_a,
    input [MEMORY_WIDTH_IN_BIT-1:0] din_a,
    output reg [MEMORY_WIDTH_IN_BIT-1:0] dout_a,
    // port B
    input clk_b,
    input reset_b,
    input en_b,
    input [3:0] we_b,
    input [31:0] addr_b,
    input [MEMORY_WIDTH_IN_BIT-1:0] din_b,
    output reg [MEMORY_WIDTH_IN_BIT-1:0] dout_b
);

    reg [MEMORY_WIDTH_IN_BIT-1:0] mem [0:MEMORY_DEPTH_IN_WORD-1];
    wire [29:0] addr_a_trunc = addr_a >> MEMORY_ADDR_TRUNCATE_BIT_NUMBER;
    wire [29:0] addr_b_trunc = addr_b >> MEMORY_ADDR_TRUNCATE_BIT_NUMBER;
    integer i;

    // reset part
    always @(posedge clk_a) begin
        if (reset_a && en_a) begin
            for (i = 0; i < MEMORY_DEPTH_IN_WORD; i = i + 1) begin
                mem[i] <= 0;
            end
        end
    end

    always @(posedge clk_b) begin
        if (reset_b && en_b) begin
            for (i = 0; i < MEMORY_DEPTH_IN_WORD; i = i + 1) begin
                mem[i] <= 0;
            end
        end
    end

    // read part
    wire [MEMORY_WIDTH_IN_BIT-1:0] port_a_next_dout = mem[addr_a_trunc];
    wire [MEMORY_WIDTH_IN_BIT-1:0] port_b_next_dout = mem[addr_b_trunc];

    always @(posedge clk_a) begin
        if (!reset_a && en_a)
            dout_a <= port_a_next_dout; 
    end

    always @(posedge clk_b) begin
        if (!reset_b && en_b)
            dout_b <= port_b_next_dout; 
    end

    // write part
    wire [7:0] byte_a_0 = we_a[0] ? din_a[7:0] : mem[addr_a_trunc][7:0];
    wire [7:0] byte_a_1 = we_a[1] ? din_a[15:8] : mem[addr_a_trunc][15:8];
    wire [7:0] byte_a_2 = we_a[2] ? din_a[23:16] : mem[addr_a_trunc][23:16];
    wire [7:0] byte_a_3 = we_a[3] ? din_a[31:24] : mem[addr_a_trunc][31:24];
    wire [31:0] word_a = { byte_a_3, byte_a_2, byte_a_1, byte_a_0 };

    always @(posedge clk_a) begin

        if (!reset_a && en_a && (we_a != 0)) begin
            mem[addr_a_trunc] <= word_a;
        end

    end

    wire [7:0] byte_b_0 = we_b[0] ? din_b[7:0] : mem[addr_b_trunc][7:0];
    wire [7:0] byte_b_1 = we_b[1] ? din_b[15:8] : mem[addr_b_trunc][15:8];
    wire [7:0] byte_b_2 = we_b[2] ? din_b[23:16] : mem[addr_b_trunc][23:16];
    wire [7:0] byte_b_3 = we_b[3] ? din_b[31:24] : mem[addr_b_trunc][31:24];
    wire [31:0] word_b = { byte_b_3, byte_b_2, byte_b_1, byte_b_0 };

    always @(posedge clk_b) begin

        if (!reset_b && en_b && (we_b != 0)) begin
            mem[addr_b_trunc] <= word_b;
        end

    end

endmodule
