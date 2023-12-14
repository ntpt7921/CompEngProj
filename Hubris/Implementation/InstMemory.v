module InstMemory #(
    parameter MEMORY_DEPTH = 1024,
    parameter MEMORY_WIDTH = 32
)(
    input clk,
    input [31:0] addr,
    input [MEMORY_WIDTH-1:0] write_data,
    input write_enable,
    output [MEMORY_WIDTH-1:0] read_data
);

    reg [MEMORY_WIDTH-1:0] mem [0:MEMORY_DEPTH-1];

    always @(posedge clk) begin

        if (write_enable)
            mem[addr] <= write_data;

    end

    assign read_data = mem[addr];

endmodule
