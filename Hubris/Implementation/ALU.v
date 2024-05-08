`define ALU_CMD_ADD   4'b0000
`define ALU_CMD_SUB   4'b0001
`define ALU_CMD_SLT   4'b0010
`define ALU_CMD_SLTU  4'b0011
`define ALU_CMD_AND   4'b0100
`define ALU_CMD_OR    4'b0101
`define ALU_CMD_XOR   4'b0110
`define ALU_CMD_SLL   4'b0111
`define ALU_CMD_SRL   4'b1000
`define ALU_CMD_SRA   4'b1001

module ALU #(
    parameter REG_WIDTH = 32
)(
    input [REG_WIDTH-1:0] rs1,
    input [REG_WIDTH-1:0] rs2,
    input [3:0] alu_cmd,
    output reg [REG_WIDTH-1:0] out
);

    always @(*) begin

        case (alu_cmd)

            `ALU_CMD_ADD:
                out = rs1 + rs2;

            `ALU_CMD_SUB:
                out = rs1 - rs2;

            `ALU_CMD_SLT:
                out = ($signed(rs1) < $signed(rs2)) ? 32'b1 : 32'b0;

            `ALU_CMD_SLTU:
                out = (rs1 < rs2) ? 32'b1 : 32'b0;

            `ALU_CMD_AND:
                out = rs1 & rs2;

            `ALU_CMD_OR:
                out = rs1 | rs2;

            `ALU_CMD_XOR:
                out = rs1 ^ rs2;

            `ALU_CMD_SLL:
                out = rs1 << rs2[4:0]; // add 0 to new bit, use 5 last bits of rs2

            `ALU_CMD_SRL:
                out = rs1 >> rs2[4:0]; // add 0 to new bit, use 5 last bits of rs2

            `ALU_CMD_SRA:
                out = $signed(rs1) >>> rs2[4:0]; // do sign extension, use 5 last bits of rs2
            
            default: out = 32'bx;

        endcase

    end

endmodule
