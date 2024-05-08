`define OPCODE_OP       7'b0110011
`define OPCODE_OP_IMM   7'b0010011
`define OPCODE_LUI      7'b0110111
`define OPCODE_AUIPC    7'b0010111
`define OPCODE_JAL      7'b1101111
`define OPCODE_JALR     7'b1100111
`define OPCODE_BRANCH   7'b1100011
`define OPCODE_LOAD     7'b0000011
`define OPCODE_STORE    7'b0100011

`define FUNCT3_OP_ADD       3'b000
`define FUNCT3_OP_SUB       3'b000
`define FUNCT3_OP_SLL       3'b001
`define FUNCT3_OP_SLT       3'b010
`define FUNCT3_OP_SLTU      3'b011
`define FUNCT3_OP_XOR       3'b100
`define FUNCT3_OP_SRL       3'b101
`define FUNCT3_OP_SRA       3'b101
`define FUNCT3_OP_OR        3'b110
`define FUNCT3_OP_AND       3'b111

`define FUNCT3_BR_BEQ       3'b000
`define FUNCT3_BR_BNE       3'b001
`define FUNCT3_BR_BLT       3'b100
`define FUNCT3_BR_BGE       3'b101
`define FUNCT3_BR_BLTU      3'b110
`define FUNCT3_BR_BEQU      3'b111

`define FUNCT3_MEM_LB       3'b000
`define FUNCT3_MEM_LH       3'b001
`define FUNCT3_MEM_LW       3'b010
`define FUNCT3_MEM_LBU      3'b100
`define FUNCT3_MEM_LHU      3'b101
`define FUNCT3_MEM_SB       3'b000
`define FUNCT3_MEM_SH       3'b001
`define FUNCT3_MEM_SW       3'b010

`define ALU_CMD_ADD     4'b0000
`define ALU_CMD_SUB     4'b0001
`define ALU_CMD_SLT     4'b0010
`define ALU_CMD_SLTU    4'b0011
`define ALU_CMD_AND     4'b0100
`define ALU_CMD_OR      4'b0101
`define ALU_CMD_XOR     4'b0110
`define ALU_CMD_SLL     4'b0111
`define ALU_CMD_SRL     4'b1000
`define ALU_CMD_SRA     4'b1001

`define REGFILE_DATA_FROM_ALU       2'b00
`define REGFILE_DATA_FROM_DATAMEM   2'b01
`define REGFILE_DATA_FROM_IMM       2'b10
`define REGFILE_DATA_FROM_EXTADDER  2'b11

`define REGISTER_FILE_WRITE_WIDTH_BYTE 4'd1
`define REGISTER_FILE_WRITE_WIDTH_HALF 4'd2
`define REGISTER_FILE_WRITE_WIDTH_WORD 4'd4

`define ALU_SRC_IMM 1'b0
`define ALU_SRC_RS2 1'b1

module CtrlSignalGen (
    input [31:0] inst,
    // ALU control
    output reg [3:0] alu_cmd,
    output reg alu_src,
    // RegisterFile control
    output reg regfile_write_en,
    output reg [3:0] regfile_write_width,
    output reg [1:0] regfile_write_data,
    // DataMemory control
    output reg datamem_write_en,
    output reg [3:0] datamem_write_width,
    // other control
    output reg add_4_pc
);

    wire [6:0] opcode = inst[6:0];
    wire [2:0] funct3 = inst[14:12];
    wire funct7_important = inst[30];

    function [3:0] alu_cmd_from_funct3_funct7;
        input [2:0] funct3;
        input funct7;
        input is_imm_inst; // boolean
        begin 
            alu_cmd_from_funct3_funct7 = 4'bx;
            case (funct3)

                `FUNCT3_OP_ADD, `FUNCT3_OP_SUB:
                    if (!is_imm_inst && funct7 == 1'b1)
                        alu_cmd_from_funct3_funct7 = `ALU_CMD_SUB; 
                    else
                        alu_cmd_from_funct3_funct7 = `ALU_CMD_ADD;
                `FUNCT3_OP_SLT:  alu_cmd_from_funct3_funct7 = `ALU_CMD_SLT;
                `FUNCT3_OP_SLTU: alu_cmd_from_funct3_funct7 = `ALU_CMD_SLTU;
                `FUNCT3_OP_AND:  alu_cmd_from_funct3_funct7 = `ALU_CMD_AND;
                `FUNCT3_OP_OR:   alu_cmd_from_funct3_funct7 = `ALU_CMD_OR;
                `FUNCT3_OP_XOR:  alu_cmd_from_funct3_funct7 = `ALU_CMD_XOR;
                `FUNCT3_OP_SLL:  alu_cmd_from_funct3_funct7 = `ALU_CMD_SLL;
                `FUNCT3_OP_SRL, `FUNCT3_OP_SRA:
                    if (funct7 == 1'b1)
                        alu_cmd_from_funct3_funct7 = `ALU_CMD_SRA;
                    else
                        alu_cmd_from_funct3_funct7 = `ALU_CMD_SRL;

                default: 
                    alu_cmd_from_funct3_funct7 = 4'bx;
            endcase        
        end
    endfunction

    function [3:0] load_store_width_or_type_from_funct3;
        input [2:0] funct3;
        begin 
            load_store_width_or_type_from_funct3 = 4'bx;
            case (funct3)
                `FUNCT3_MEM_LB: load_store_width_or_type_from_funct3 = `REGISTER_FILE_WRITE_WIDTH_BYTE;
                `FUNCT3_MEM_LH: load_store_width_or_type_from_funct3 = `REGISTER_FILE_WRITE_WIDTH_HALF;
                `FUNCT3_MEM_LW: load_store_width_or_type_from_funct3 = `REGISTER_FILE_WRITE_WIDTH_WORD;
                `FUNCT3_MEM_LBU: load_store_width_or_type_from_funct3 = `REGISTER_FILE_WRITE_WIDTH_BYTE;
                `FUNCT3_MEM_LHU: load_store_width_or_type_from_funct3 = `REGISTER_FILE_WRITE_WIDTH_HALF;
                `FUNCT3_MEM_SB: load_store_width_or_type_from_funct3 = `REGISTER_FILE_WRITE_WIDTH_BYTE;
                `FUNCT3_MEM_SH: load_store_width_or_type_from_funct3 = `REGISTER_FILE_WRITE_WIDTH_HALF;
                `FUNCT3_MEM_SW: load_store_width_or_type_from_funct3 = `REGISTER_FILE_WRITE_WIDTH_WORD;
                default: load_store_width_or_type_from_funct3 = 4'bx;
            endcase
        end
    endfunction

    always @(*) begin 

        case (opcode)

            `OPCODE_OP: begin 
                // ALU control
                alu_cmd = alu_cmd_from_funct3_funct7(funct3, funct7_important, 0);
                alu_src = `ALU_SRC_RS2;
                // RegisterFile control
                regfile_write_en = 1;
                regfile_write_width = `REGISTER_FILE_WRITE_WIDTH_WORD;
                regfile_write_data = `REGFILE_DATA_FROM_ALU;
                // DataMemory control
                datamem_write_en = 0;
                datamem_write_width = 4'bx;
                // other control
                add_4_pc = 1'bx;
            end

            `OPCODE_OP_IMM: begin
                // ALU control
                alu_cmd = alu_cmd_from_funct3_funct7(funct3, funct7_important, 1);
                alu_src = `ALU_SRC_IMM;
                // RegisterFile control
                regfile_write_en = 1;
                regfile_write_width = `REGISTER_FILE_WRITE_WIDTH_WORD;
                regfile_write_data = `REGFILE_DATA_FROM_ALU;
                // DataMemory control
                datamem_write_en = 0;
                datamem_write_width = 4'bx;
                // other control
                add_4_pc = 1'bx;
            end

            `OPCODE_LUI: begin 
                // ALU control
                alu_cmd = 4'bx;
                alu_src = 1'bx;
                // RegisterFile control
                regfile_write_en = 1;
                regfile_write_width = `REGISTER_FILE_WRITE_WIDTH_WORD;
                regfile_write_data = `REGFILE_DATA_FROM_IMM;
                // DataMemory control
                datamem_write_en = 0;
                datamem_write_width = 4'bx;
                // other control
                add_4_pc = 1'bx;
            end

            `OPCODE_AUIPC: begin 
                // ALU control
                alu_cmd = 4'bx;
                alu_src = 1'bx;
                // RegisterFile control
                regfile_write_en = 1;
                regfile_write_width = `REGISTER_FILE_WRITE_WIDTH_WORD;
                regfile_write_data = `REGFILE_DATA_FROM_EXTADDER;
                // DataMemory control
                datamem_write_en = 0;
                datamem_write_width = 4'bx;
                // other control
                add_4_pc = 1'b0;
            end

            `OPCODE_JAL: begin 
                // ALU control
                alu_cmd = 4'bx;
                alu_src = 1'bx;
                // RegisterFile control
                regfile_write_en = 1;
                regfile_write_width = `REGISTER_FILE_WRITE_WIDTH_WORD;
                regfile_write_data = `REGFILE_DATA_FROM_EXTADDER;
                // DataMemory control
                datamem_write_en = 0;
                datamem_write_width = 4'bx;
                // other control
                add_4_pc = 1'b1;
            end

            `OPCODE_JALR: begin 
                // ALU control
                alu_cmd = 4'bx;
                alu_src = 1'bx;
                // RegisterFile control
                regfile_write_en = 1;
                regfile_write_width = `REGISTER_FILE_WRITE_WIDTH_WORD;
                regfile_write_data = `REGFILE_DATA_FROM_EXTADDER;
                // DataMemory control
                datamem_write_en = 0;
                datamem_write_width = 4'bx;
                // other control
                add_4_pc = 1'b1;
            end

            `OPCODE_BRANCH: begin 
                // ALU control
                alu_cmd = 4'bx;
                alu_src = 1'bx;
                // RegisterFile control
                regfile_write_en = 0;
                regfile_write_width = 4'bx;
                regfile_write_data = 2'bx;
                // DataMemory control
                datamem_write_en = 0;
                datamem_write_width = 4'bx;
                // other control
                add_4_pc = 1'bx;
            end

            `OPCODE_LOAD: begin 
                // ALU control
                alu_cmd = `ALU_CMD_ADD;
                alu_src = `ALU_SRC_IMM;
                // RegisterFile control
                regfile_write_en = 1;
                regfile_write_width = load_store_width_or_type_from_funct3(funct3);
                regfile_write_data = `REGFILE_DATA_FROM_DATAMEM;
                // DataMemory control
                datamem_write_en = 0;
                datamem_write_width = 4'bx;
                // other control
                add_4_pc = 1'bx;
            end

            `OPCODE_STORE: begin
                // ALU control
                alu_cmd = `ALU_CMD_ADD;
                alu_src = `ALU_SRC_IMM;
                // RegisterFile control
                regfile_write_en = 0;
                regfile_write_width = 4'bx;
                regfile_write_data = 2'bx;
                // DataMemory control
                datamem_write_en = 1;
                datamem_write_width = load_store_width_or_type_from_funct3(funct3);
                // other control
                add_4_pc = 1'bx;
            end

            default: begin
                // ALU control
                alu_cmd = 4'bx;
                alu_src = 1'bx;
                // RegisterFile control
                regfile_write_en = 0;
                regfile_write_width = 4'bx;
                regfile_write_data = 2'bx;
                // DataMemory control
                datamem_write_en = 0;
                datamem_write_width = 4'bx;
                // other control
                add_4_pc = 1'bx;
            end

        endcase

    end

endmodule
