`define REGISTER_FILE_WRITE_WIDTH_BYTE 1
`define REGISTER_FILE_WRITE_WIDTH_HALF 2
`define REGISTER_FILE_WRITE_WIDTH_WORD 4

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
    input [3:0] write_width,
    input [2:0] funct3,
    output reg [REG_WIDTH_IN_BIT-1:0] read_data_ext
);
      
    always @(*) begin

        case (funct3)

            `FUNCT3_MEM_LB: read_data_ext = { {24{read_data[7]}}, read_data[7:0] };
            `FUNCT3_MEM_LH: read_data_ext = { {16{read_data[7]}}, read_data[15:0] };
            `FUNCT3_MEM_LW: read_data_ext = read_data;
            `FUNCT3_MEM_LBU: read_data_ext = { {24{1'b0}}, read_data[7:0] };
            `FUNCT3_MEM_LHU: read_data_ext = { {16{1'b0}}, read_data[15:0] };
            `FUNCT3_MEM_SB: read_data_ext = { {24{1'b0}}, read_data[7:0] };
            `FUNCT3_MEM_SH: read_data_ext = { {16{1'b0}}, read_data[15:0] };
            `FUNCT3_MEM_SW: read_data_ext = read_data;
            
            default: read_data_ext = {32 {1'bx}};

        endcase

    end

endmodule
