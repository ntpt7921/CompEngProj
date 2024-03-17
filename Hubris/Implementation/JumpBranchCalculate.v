`define OPCODE_JAL     7'b1101111
`define OPCODE_JALR    7'b1100111
`define OPCODE_BRANCH  7'b1100011

`define FUNCT3_BEQ   3'b000
`define FUNCT3_BNE   3'b001
`define FUNCT3_BLT   3'b100
`define FUNCT3_BGE   3'b101
`define FUNCT3_BLTU  3'b110
`define FUNCT3_BGEU  3'b111

module JumpBranchCalculate #(
    parameter ADDR_WIDTH_IN_BIT = 32
)(
    input [6:0] opcode,
    input [2:0] funct3,
    input [ADDR_WIDTH_IN_BIT-1:0] pc,
    input [ADDR_WIDTH_IN_BIT-1:0] imm,
    input [ADDR_WIDTH_IN_BIT-1:0] rs1,
    input [ADDR_WIDTH_IN_BIT-1:0] rs2,
    output reg [ADDR_WIDTH_IN_BIT-1:0] new_addr,
    output reg change_addr_enable
);

    // for address
    always @(*)  begin

        case (opcode)

            `OPCODE_JAL:
                new_addr = pc + imm;

            `OPCODE_JALR:
                new_addr = (rs1 + imm) & 32'hFFFF_FFFE; // set last LSB to 0

            `OPCODE_BRANCH:
                new_addr = pc + imm;

            default: 
                new_addr = {ADDR_WIDTH_IN_BIT {1'bx}};

        endcase

    end

    // for change address decision
    always @(*) begin

        case (opcode)

            `OPCODE_JAL:
                change_addr_enable = 1'b1;

            `OPCODE_JALR:
                change_addr_enable = 1'b1;

            `OPCODE_BRANCH:
                if ((funct3 == `FUNCT3_BEQ && rs1 == rs2)
                    || (funct3 == `FUNCT3_BNE && rs1 != rs2)
                    || (funct3 == `FUNCT3_BLT && $signed(rs1) < $signed(rs2))
                    || (funct3 == `FUNCT3_BGE && $signed(rs1) >= $signed(rs2))
                    || (funct3 == `FUNCT3_BLTU && rs1 < rs2)
                    || (funct3 == `FUNCT3_BGEU && rs1 >= rs2)
                    )
                    change_addr_enable = 1'b1;
                else
                    change_addr_enable = 1'b0;

            default: 
                change_addr_enable = 1'b0;

        endcase

    end


endmodule
