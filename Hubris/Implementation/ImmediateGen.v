`define OPCODE_OP_IMM  6'b0010011
`define OPCODE_LUI     6'b0110111
`define OPCODE_AUIPC   6'b0010111
`define OPCODE_JAL     6'b1101111
`define OPCODE_JALR    6'b1100111
`define OPCODE_BRANCH  6'b1100011
`define OPCODE_LOAD    6'b0000011
`define OPCODE_STORE   6'b0100011

module ImmediateGen (
    input [31:0] inst,
    output reg [31:0] immediate
);
    
    assign [6:0] opcode = inst[6:0];

    always @(*) begin

        case (opcode)

            OPCODE_OP_IMM: 
                immediate = { {20{inst[31]}}, inst[31:20] };

            OPCODE_LUI:
                immediate = {inst[31:12], 12'b0};

            OPCODE_AUIPC:
                immediate = {inst[31:12], 12'b0};

            OPCODE_JAL:
                immediate = { {19{inst[31]}}, inst[20], inst[19:12], inst[11], inst[30:21], 1'b0 };

            OPCODE_JALR:
                immediate = { {20{inst[31]}}, inst[31:20] };

            OPCODE_BRANCH:
                immediate = { {19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0 };

            OPCODE_LOAD:
                immediate = { {20{inst[31]}}, inst[31:20] };

            OPCODE_STORE:
                immediate = { {20{inst[31]}}, inst[31:25], inst[11:7] };
            
            default: immediate = 32'b0;

        endcase

    end

endmodule
