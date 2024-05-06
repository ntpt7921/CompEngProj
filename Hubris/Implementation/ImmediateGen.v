`define OPCODE_OP      7'b0110011
`define OPCODE_OP_IMM  7'b0010011
`define OPCODE_LUI     7'b0110111
`define OPCODE_AUIPC   7'b0010111
`define OPCODE_JAL     7'b1101111
`define OPCODE_JALR    7'b1100111
`define OPCODE_BRANCH  7'b1100011
`define OPCODE_LOAD    7'b0000011
`define OPCODE_STORE   7'b0100011

module ImmediateGen (
    input [31:0] inst,
    output reg [31:0] immediate
);
    
    wire [6:0] opcode = inst[6:0];

    always @(*) begin

        case (opcode)

            // OPCODE_OP - no immediate needed, so not added

            `OPCODE_OP_IMM: 
                immediate = { {20{inst[31]}}, inst[31:20] };

            `OPCODE_LUI:
                immediate = { inst[31:12], 12'b0 };

            `OPCODE_AUIPC:
                immediate = { inst[31:12], 12'b0 };

            `OPCODE_JAL:
                immediate = { {12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0 };

            `OPCODE_JALR:
                immediate = { {20{inst[31]}}, inst[31:20] };

            `OPCODE_BRANCH:
                immediate = { {20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0 };

            `OPCODE_LOAD:
                immediate = { {20{inst[31]}}, inst[31:20] };

            `OPCODE_STORE:
                immediate = { {20{inst[31]}}, inst[31:25], inst[11:7] };
            
            default: 
                immediate = {32 {1'bx}};

        endcase

    end

endmodule
