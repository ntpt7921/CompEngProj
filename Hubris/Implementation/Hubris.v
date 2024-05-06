`define NOP_INST 32'h00000013

`define REGFILE_DATA_FROM_ALU       2'b00
`define REGFILE_DATA_FROM_DATAMEM   2'b01
`define REGFILE_DATA_FROM_IMM       2'b10
`define REGFILE_DATA_FROM_EXTADDER  2'b11

`define REGISTER_FILE_WRITE_WIDTH_BYTE 4'd1
`define REGISTER_FILE_WRITE_WIDTH_HALF 4'd2
`define REGISTER_FILE_WRITE_WIDTH_WORD 4'd4

`define ALU_SRC_IMM 1'b0
`define ALU_SRC_RS2 1'b1

/*
* NOTE: Functionality
* Full Hubris design, use other module and connecting them with glue logic and pipeline register
*/

module Hubris #(
    parameter REG_NUMBER = 32,
    parameter WORD_WIDTH_IN_BYTE = 4,
    parameter WORD_WIDTH_IN_BIT = WORD_WIDTH_IN_BYTE * 8,
    parameter INST_START_ADDR = 32'b0
)(
    input clk,
    input reset,
    output halt
);

    // IF section
    // --------------------------------------------------------------------------------------------
    wire [WORD_WIDTH_IN_BIT-1:0] new_addr;
    wire chg_addr;
    wire pc_stall_write;
    reg [WORD_WIDTH_IN_BIT-1:0] pc;

    always @(posedge clk) begin 
        if (reset)
            pc <= INST_START_ADDR;
        else if (pc_stall_write)
            pc <= pc;
        else begin
            if (chg_addr)
                pc <= new_addr + 4;
            else
                pc <= pc + 4;
        end
    end

    wire [WORD_WIDTH_IN_BIT-1:0] inst_addr = (chg_addr) ? new_addr : pc; // address of next instruction
    wire [WORD_WIDTH_IN_BIT-1:0] if_inst; // instruction read from InstMemory

    // IF-ID pipeline
    // --------------------------------------------------------------------------------------------
    wire stall_id_if_pl;
    reg [WORD_WIDTH_IN_BIT-1:0] if_id_pl_pc;
    reg [WORD_WIDTH_IN_BIT-1:0] if_id_pl_inst;
    always @(posedge clk) begin
        if_id_pl_pc <= inst_addr;
        if (reset || stall_id_if_pl) // insert NOP if needed
            if_id_pl_inst <= `NOP_INST;
        else
            if_id_pl_inst <= if_inst;
    end

    // ID section
    // --------------------------------------------------------------------------------------------
    wire [WORD_WIDTH_IN_BIT-1:0] id_imm; // extracted immediate value
    // control signal generation
    wire [3:0] id_alu_cmd;
    wire id_alu_src;
    wire id_regfile_write_en;
    wire [3:0] id_regfile_write_width;
    wire [1:0] id_regfile_write_data;
    wire id_datamem_write_en;
    wire [3:0] id_datamem_write_width;
    wire id_add_4_pc;
    // command parsing
    wire [4:0] id_parse_rs1 = if_id_pl_inst[19:15];
    wire [4:0] id_parse_rs2 = if_id_pl_inst[24:20];
    wire [4:0] id_parse_rd = if_id_pl_inst[11:7];
    // register file data read
    wire [WORD_WIDTH_IN_BIT-1:0] id_rs1_data;
    wire [WORD_WIDTH_IN_BIT-1:0] id_rs2_data;

    // ID-EX pipeline
    // --------------------------------------------------------------------------------------------
    reg [WORD_WIDTH_IN_BIT-1:0] id_ex_pl_pc;
    reg [WORD_WIDTH_IN_BIT-1:0] id_ex_pl_inst;
    reg [WORD_WIDTH_IN_BIT-1:0] id_ex_pl_imm;
    // control signal generation
    reg [3:0] id_ex_pl_alu_cmd;
    reg id_ex_pl_alu_src;
    reg id_ex_pl_regfile_write_en;
    reg [3:0] id_ex_pl_regfile_write_width;
    reg [1:0] id_ex_pl_regfile_write_data;
    reg id_ex_pl_datamem_write_en;
    reg [3:0] id_ex_pl_datamem_write_width;
    reg id_ex_pl_add_4_pc;
    // command parsing
    reg [4:0] id_ex_pl_parse_rs1;
    reg [4:0] id_ex_pl_parse_rs2;
    reg [4:0] id_ex_pl_parse_rd;
    // register file data read
    reg [WORD_WIDTH_IN_BIT-1:0] id_ex_pl_rs1_data;
    reg [WORD_WIDTH_IN_BIT-1:0] id_ex_pl_rs2_data;

    always @(posedge clk) begin 
        id_ex_pl_pc <= if_id_pl_pc;
        id_ex_pl_inst <= if_id_pl_inst;
        id_ex_pl_imm <= id_imm;
        // control signal generation
        id_ex_pl_alu_cmd <= id_alu_cmd;
        id_ex_pl_alu_src <= id_alu_src;
        id_ex_pl_regfile_write_en <= id_regfile_write_en;
        id_ex_pl_regfile_write_width <= id_regfile_write_width;
        id_ex_pl_regfile_write_data <= id_regfile_write_data;
        id_ex_pl_datamem_write_en <= id_datamem_write_en;
        id_ex_pl_datamem_write_width <= id_datamem_write_width;
        id_ex_pl_add_4_pc <= id_add_4_pc;
        // command parsing
        id_ex_pl_parse_rs1 <= id_parse_rs1;
        id_ex_pl_parse_rs2 <= id_parse_rs2;
        id_ex_pl_parse_rd <= id_parse_rd;
        // register file data read
        id_ex_pl_rs1_data <= id_rs1_data;
        id_ex_pl_rs2_data <= id_rs2_data;
    end

    // EX section
    // --------------------------------------------------------------------------------------------
    wire [6:0] ex_opcode = id_ex_pl_inst[6:0];
    wire [2:0] ex_funct3 = id_ex_pl_inst[14:12];
    wire [WORD_WIDTH_IN_BIT-1:0] ex_final_rs2 = 
        (id_ex_pl_alu_src == `ALU_SRC_IMM) ? id_ex_pl_imm : id_ex_pl_rs2_data;
    wire [WORD_WIDTH_IN_BIT-1:0] alu_result;

    reg [WORD_WIDTH_IN_BIT-1:0] ex_calculated_pc;
    always @(*) begin 
        if (id_ex_pl_add_4_pc)
            ex_calculated_pc = id_ex_pl_pc + 4;
        else
            ex_calculated_pc = id_ex_pl_pc + id_ex_pl_imm;
    end

    // EX-MEM pipeline
    // --------------------------------------------------------------------------------------------
    reg [2:0] ex_mem_pl_funct3;
    reg [WORD_WIDTH_IN_BIT-1:0] ex_mem_pl_imm;
    // control signal generation
    reg ex_mem_pl_regfile_write_en;
    reg [3:0] ex_mem_pl_regfile_write_width;
    reg [1:0] ex_mem_pl_regfile_write_data;
    reg ex_mem_pl_datamem_write_en;
    reg [3:0] ex_mem_pl_datamem_write_width;
    // command parsing
    reg [4:0] ex_mem_pl_parse_rd;
    // register file data read
    reg [WORD_WIDTH_IN_BIT-1:0] ex_mem_pl_rs2_data; // src for store instruction
    // result from EX section
    reg [WORD_WIDTH_IN_BIT-1:0] ex_mem_pl_alu_result;
    reg [WORD_WIDTH_IN_BIT-1:0] ex_mem_pl_ex_calculated_pc;

    always @(posedge clk) begin 
        ex_mem_pl_funct3 <= ex_funct3;
        ex_mem_pl_imm <= id_ex_pl_imm;
        // control signal generation
        ex_mem_pl_regfile_write_en <= id_ex_pl_regfile_write_en;
        ex_mem_pl_regfile_write_width <= id_ex_pl_regfile_write_width;
        ex_mem_pl_regfile_write_data <= id_ex_pl_regfile_write_data;
        ex_mem_pl_datamem_write_en <= id_ex_pl_datamem_write_en;
        ex_mem_pl_datamem_write_width <= id_ex_pl_datamem_write_width;
        // command parsing
        ex_mem_pl_parse_rd <= id_ex_pl_parse_rd;
        // register file data read
        ex_mem_pl_rs2_data <= id_ex_pl_rs2_data; // src for store instruction
        // result from EX section
        ex_mem_pl_alu_result <= alu_result;
        ex_mem_pl_ex_calculated_pc <= ex_calculated_pc;
    end

    // MEM section
    // --------------------------------------------------------------------------------------------
    wire [WORD_WIDTH_IN_BIT-1:0] mem_read_data;
    wire [WORD_WIDTH_IN_BIT-1:0] mem_read_data_ext;
    
    // MEM-WB pipeline
    // --------------------------------------------------------------------------------------------
    reg [WORD_WIDTH_IN_BIT-1:0] mem_wb_pl_imm;
    // data read from mem
    reg [WORD_WIDTH_IN_BIT-1:0] mem_wb_pl_read_data_ext;
    // control signal generation
    reg mem_wb_pl_regfile_write_en;
    reg [3:0] mem_wb_pl_regfile_write_width;
    reg [1:0] mem_wb_pl_regfile_write_data;
    // command parsing
    reg [4:0] mem_wb_pl_parse_rd;
    // result from EX section
    reg [WORD_WIDTH_IN_BIT-1:0] mem_wb_pl_alu_result;
    reg [WORD_WIDTH_IN_BIT-1:0] mem_wb_pl_ex_calculated_pc;

    always @(posedge clk) begin 
        mem_wb_pl_imm <= ex_mem_pl_imm;
        // data read from mem
        mem_wb_pl_read_data_ext <= mem_read_data_ext;
        // control signal generation
        mem_wb_pl_regfile_write_en <= ex_mem_pl_regfile_write_en;
        mem_wb_pl_regfile_write_width <= ex_mem_pl_regfile_write_width;
        mem_wb_pl_regfile_write_data <= ex_mem_pl_regfile_write_data;
        // command parsing
        mem_wb_pl_parse_rd <= ex_mem_pl_parse_rd;
        // result from EX section
        mem_wb_pl_alu_result <= ex_mem_pl_alu_result;
        mem_wb_pl_ex_calculated_pc <= ex_mem_pl_ex_calculated_pc;
    end

    // WB section
    // --------------------------------------------------------------------------------------------
    reg [WORD_WIDTH_IN_BIT-1:0] wb_write_data;
    always @(*) begin 
        case (mem_wb_pl_regfile_write_data)

            `REGFILE_DATA_FROM_ALU: 
                wb_write_data = mem_wb_pl_alu_result;
            `REGFILE_DATA_FROM_DATAMEM:
                wb_write_data = mem_wb_pl_read_data_ext;
            `REGFILE_DATA_FROM_IMM:
                wb_write_data = mem_wb_pl_imm;
            `REGFILE_DATA_FROM_EXTADDER:
                wb_write_data = mem_wb_pl_ex_calculated_pc;

            default:
                wb_write_data = {32 {1'bx}};

        endcase
    end

    // instatiate all the submodules
    // --------------------------------------------------------------------------------------------
    UnifiedMemory #(
        .MEMORY_WIDTH_IN_BYTE(WORD_WIDTH_IN_BYTE),
        .INST_SIZE_IN_WORD(524288), // 2MiB
        .DATA_SIZE_IN_WORD(524288)  // 2MiB
    ) unified_memory_instance (
        .clk(clk),
        // for inst
        // address to bytes, misalignement allowed
        // always return 4 bytes of continuous memory from addr
        .inst_addr(inst_addr), 
        .inst_write_enable(1'b0),
        .inst_write_width(`REGISTER_FILE_WRITE_WIDTH_WORD),
        .inst_write_data(0),
        .inst_read_data(if_inst),
        // for data
        // address to bytes, misalignement allowed
        // always return 4 bytes of continuous memory from addr
        .data_addr(ex_mem_pl_alu_result), 
        .data_write_enable(ex_mem_pl_datamem_write_en),
        .data_write_width(ex_mem_pl_datamem_write_width),
        .data_write_data(ex_mem_pl_rs2_data),
        .data_read_data(mem_read_data)
    );

    Orchestrator #(
        .INST_WIDTH_IN_BIT(WORD_WIDTH_IN_BIT)
    ) orchestrator_instance (
        .clk(clk),
        .reset(reset), // positive assertion, sychrnonous reset
        .next_inst(if_inst),
        .curr_inst(if_id_pl_inst),
        .prev_inst(id_ex_pl_inst),

        .stall_id_if_pl(stall_id_if_pl),
        .stall_pc_increment(pc_stall_write),
        .halt(halt)
    );

    RegisterFile #(
        .REG_NUMBER(REG_NUMBER),
        .REG_WIDTH_IN_BYTE(WORD_WIDTH_IN_BYTE)
    ) register_file_instance (
        .clk(clk),
        .reset(reset),
        .read_reg1_addr(id_parse_rs1),
        .read_reg2_addr(id_parse_rs2),
        .read_reg1_data(id_rs1_data),
        .read_reg2_data(id_rs2_data),
        .write_enable(mem_wb_pl_regfile_write_en),
        .write_width(mem_wb_pl_regfile_write_width),
        .write_reg_addr(mem_wb_pl_parse_rd),
        .write_data(wb_write_data)
    );

    ImmediateGen immediate_gen_instance (
        .inst(if_id_pl_inst),
        .immediate(id_imm)
    );

    CtrlSignalGen ctrl_sig_gen_instance (
        .inst(if_id_pl_inst),
        // ALU control
        .alu_cmd(id_alu_cmd),
        .alu_src(id_alu_src),
        // RegisterFile control
        .regfile_write_en(id_regfile_write_en),
        .regfile_write_width(id_regfile_write_width),
        .regfile_write_data(id_regfile_write_data),
        // DataMemory control
        .datamem_write_en(id_datamem_write_en),
        .datamem_write_width(id_datamem_write_width),
        // other control
        .add_4_pc(id_add_4_pc)
    );


    JumpBranchCalculate #(
        .ADDR_WIDTH_IN_BIT(WORD_WIDTH_IN_BIT)
    ) jump_branch_calculate_instance (
        .opcode(ex_opcode),
        .funct3(ex_funct3),
        .pc(id_ex_pl_pc),
        .imm(id_ex_pl_imm),
        .rs1(id_ex_pl_rs1_data),
        .rs2(id_ex_pl_rs2_data),
        .new_addr(new_addr),
        .change_addr_enable(chg_addr)
    );

    ALU #(
        .REG_WIDTH(WORD_WIDTH_IN_BIT)
    ) alu_instance (
        .rs1(id_ex_pl_rs1_data),
        .rs2(ex_final_rs2),
        .alu_cmd(id_ex_pl_alu_cmd),
        .out(alu_result)
    );

    LoadExtend #(
        .REG_WIDTH_IN_BYTE(WORD_WIDTH_IN_BYTE)
    ) load_extend_instance (
        .read_data(mem_read_data),
        .write_width(ex_mem_pl_datamem_write_width),
        .funct3(ex_mem_pl_funct3),
        .read_data_ext(mem_read_data_ext)
    );

endmodule
