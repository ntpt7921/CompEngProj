module RegisterFile #(
    parameter REG_NUMBER = 32,
    parameter REG_WIDTH = 32,
    parameter REG_ADDR_WIDTH = $clog2(REG_NUMBER)
)(
    input clk,
    input [REG_ADDR_WIDTH-1:0] read_reg1_addr,
    input [REG_ADDR_WIDTH-1:0] read_reg2_addr,
    output reg [REG_WIDTH-1:0] read_reg1_data,
    output reg [REG_WIDTH-1:0] read_reg2_data,
    input write_enable,
    input [REG_ADDR_WIDTH-1:0] write_reg_addr,
    input [REG_WIDTH-1:0] write_data
);

    reg [REG_WIDTH-1:0] regfile [0:REG_NUMBER-1];

    always @(posedge clk) begin

        if (write_enable)
            regfile[write_reg_addr] <= write_data;

    end

    always @(*) begin

        if (read_reg1_addr == write_reg_addr && write_enable)
            read_reg1_data = write_data;
        else
            read_reg1_data = regfile[read_reg1_addr];

        if (read_reg2_addr == write_reg_addr && write_enable)
            read_reg2_data = write_data;
        else
            read_reg2_data = regfile[read_reg2_addr];

    end

endmodule
