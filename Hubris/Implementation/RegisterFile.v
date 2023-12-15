module RegisterFile #(
    parameter REG_NUMBER = 32,
    parameter REG_WIDTH = 32,
    parameter REG_ADDR_WIDTH = $clog2(REG_NUMBER),
    parameter REG_BYTE_WRITE_MASK_WIDTH = $ceil(REG_WIDTH / 8)
)(
    input clk,
    input [REG_ADDR_WIDTH-1:0] read_reg1_addr,
    input [REG_ADDR_WIDTH-1:0] read_reg2_addr,
    output reg [REG_WIDTH-1:0] read_reg1_data,
    output reg [REG_WIDTH-1:0] read_reg2_data,
    input write_enable,
    input [REG_ADDR_WIDTH-1:0] write_reg_addr,
    input [REG_WIDTH-1:0] write_data,
    // if a bit is set, corresponding bit will be written
    input [REG_BYTE_WRITE_MASK_WIDTH-1:0] write_byte_mask 
);

    reg [REG_WIDTH-1:0] regfile [0:REG_NUMBER-1];
    wire [REG_WIDTH-1:0] masked_write_data;

    genvar i;
    generate

        for (i = 0; i < REG_BYTE_WRITE_MASK_WIDTH; i = i + 1)
        begin: mask 
            assign masked_write_data[8*i+7:8*i] =
                (write_byte_mask[i]) ? write_data[8*i+7:8*i] : regfile[write_reg_addr][8*i+7:8*i];
        end

    endgenerate

    always @(posedge clk) begin

        if (write_enable)
            regfile[write_reg_addr] <= masked_write_data;

    end

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
