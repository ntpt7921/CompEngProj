`define FUNCT3_MEM_LB       3'b000
`define FUNCT3_MEM_LH       3'b001
`define FUNCT3_MEM_LW       3'b010
`define FUNCT3_MEM_LBU      3'b100
`define FUNCT3_MEM_LHU      3'b101
`define FUNCT3_MEM_SB       3'b000
`define FUNCT3_MEM_SH       3'b001
`define FUNCT3_MEM_SW       3'b010

module LoadExtend #(
    parameter REG_WIDTH_IN_BYTE = 4,
    parameter REG_WIDTH_IN_BIT = REG_WIDTH_IN_BYTE * 8
)(
    input [REG_WIDTH_IN_BIT-1:0] read_data,
    input [2:0] funct3,
    input [1:0] byte_offset,  // 2 lsb bits of address from mem stage
    output reg [REG_WIDTH_IN_BIT-1:0] read_data_ext
);

    wire [REG_WIDTH_IN_BIT-1:0] sdata; // shifted read_data
    assign sdata = (read_data) >> (byte_offset * 8);
      
    always @(*) begin

        case (funct3)

            `FUNCT3_MEM_LB: read_data_ext = { {24{sdata[7]}}, sdata[7:0] };
            `FUNCT3_MEM_LH: read_data_ext = { {16{sdata[7]}}, sdata[15:0] };
            `FUNCT3_MEM_LW: read_data_ext = sdata;
            `FUNCT3_MEM_LBU: read_data_ext = { {24{1'b0}}, sdata[7:0] };
            `FUNCT3_MEM_LHU: read_data_ext = { {16{1'b0}}, sdata[15:0] };
            `FUNCT3_MEM_SB: read_data_ext = { {24{1'b0}}, sdata[7:0] };
            `FUNCT3_MEM_SH: read_data_ext = { {16{1'b0}}, sdata[15:0] };
            `FUNCT3_MEM_SW: read_data_ext = sdata;

            default: read_data_ext = {32 {1'bx}};

        endcase

    end

endmodule
