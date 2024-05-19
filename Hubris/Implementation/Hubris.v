`define NOP_INST 32'h00000013

`define REGFILE_DATA_FROM_ALU       2'b00
`define REGFILE_DATA_FROM_DATAMEM   2'b01
`define REGFILE_DATA_FROM_IMM       2'b10
`define REGFILE_DATA_FROM_EXTADDER  2'b11

`define ALU_SRC_IMM 1'b0
`define ALU_SRC_RS2 1'b1

`define OPCODE_SYSTEM   7'b1110011
`define FUNCT3_SYS_CSRRS    3'b010

`define OUTPUT_BYTES_AVAI_ADDR  32'h8000_0000
`define OUTPUT_BYTES_ADDR       32'h8000_0004

/*
* NOTE: Functionality
* Full Hubris design, use other module and connecting them with glue logic and pipeline register
*/

/*
* NOTE:
* this module also allows for memory-mapped IO, placed at addr 32'h8000_0000
* onward. it work in tandem with NewUnifiedMemory
*   - output takes 8 bytes (2 words), in order:
*       - output_bytes_avai (4 bytes) - 32'h8000_0000: can be read, contains
*       current number of available output buffer bytes. writing to this have no
*       effect
*       - output_bytes (4 bytes) - 32'h8000_0004: each write to this (at any width)
*       store a byte of output data situated at the least significant byte of
*       the write data. read to this return undefined value
*/

module Hubris #(
    parameter REG_NUMBER = 32,
    parameter WORD_WIDTH_IN_BYTE = 4,
    parameter WORD_WIDTH_IN_BIT = WORD_WIDTH_IN_BYTE * 8,
    parameter INST_START_ADDR = 32'b0,
    // IO spec
    parameter OUTPUT_BUFFER_BYTE_SIZE = 32 
)(
    input clk,
    input reset,
    output halt,
    // memory port A
    output en_a,
    output [3:0] we_a,
    output [31:0] addr_a,
    output [WORD_WIDTH_IN_BIT-1:0] din_a,
    input [WORD_WIDTH_IN_BIT-1:0] dout_a,
    // memory port B
    output en_b,
    output [3:0] we_b,
    output [31:0] addr_b,
    output [WORD_WIDTH_IN_BIT-1:0] din_b,
    input [WORD_WIDTH_IN_BIT-1:0] dout_b,
    // external output io
    input io_output_en,
    output [7:0] io_output_data,
    output [31:0] io_buffer_size_avai
);

    // IF1+2 section
    // --------------------------------------------------------------------------------------------
    wire [WORD_WIDTH_IN_BIT-1:0] new_addr;
    wire chg_addr;
    wire stall_id_if_pl;
    wire pc_stall_write;
    wire final_pc_stall_write = (chg_addr) ? 0 : pc_stall_write; // don't stall pc write if addr need change
    reg [WORD_WIDTH_IN_BIT-1:0] pc;

    always @(posedge clk) begin 
        if (reset) begin
            pc <= INST_START_ADDR;
        end
        else if (final_pc_stall_write)
            pc <= pc;
        else begin
            if (chg_addr)
                pc <= new_addr + 4;
            else
                pc <= pc + 4;
        end
    end

    wire [WORD_WIDTH_IN_BIT-1:0] if1_pc =
        (chg_addr) ? new_addr : pc; // addr of if1 instruction

    reg [WORD_WIDTH_IN_BIT-1:0] if2_pc; // addr of if2 instruction
    wire [WORD_WIDTH_IN_BIT-1:0] if2_inst; // if2 instruction read from memory

    always @(posedge clk) begin 
        if (reset)
            if2_pc <= 32'b0;
        else if (!stall_id_if_pl || chg_addr)
            if2_pc <= if1_pc;
    end

    wire [WORD_WIDTH_IN_BIT-1:0] final_if_inst = if2_inst;
    wire [WORD_WIDTH_IN_BIT-1:0] final_pc = if2_pc;

    // IF-ID pipeline
    // --------------------------------------------------------------------------------------------
    reg [WORD_WIDTH_IN_BIT-1:0] if_id_pl_pc;
    reg [WORD_WIDTH_IN_BIT-1:0] if_id_pl_inst;
    reg reset_1clk_delay;

    always @(posedge clk)
        reset_1clk_delay <= reset;

    always @(posedge clk) begin

        if (stall_id_if_pl || reset || reset_1clk_delay) begin
            if_id_pl_inst <= `NOP_INST;
            if_id_pl_pc <= 32'b0;
        end
        else begin
            if_id_pl_inst <= final_if_inst;
            if_id_pl_pc <= final_pc;
        end
    end

    // ID section
    // --------------------------------------------------------------------------------------------
    wire [WORD_WIDTH_IN_BIT-1:0] id_imm; // extracted immediate value
    wire [WORD_WIDTH_IN_BIT-1:0] id_final_imm = 
        (id_parse_opcode == `OPCODE_SYSTEM && id_parse_funct3 == `FUNCT3_SYS_CSRRS) 
        ? id_csr_content
        : id_imm;       // when Zicntr instructions is met, act as if addi <rd>, x0, <csr_content>
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
    wire [6:0] id_parse_opcode = if_id_pl_inst[6:0]; // used for Zicntr
    wire [6:0] id_parse_funct3 = if_id_pl_inst[14:12]; // used for Zicntr
    wire [11:0] id_parse_csr = if_id_pl_inst[31:20]; // used for Zicntr
    // register file data read
    wire [WORD_WIDTH_IN_BIT-1:0] id_rs1_data;
    wire [WORD_WIDTH_IN_BIT-1:0] id_rs2_data;
    // csr register value (Zicntr)
    wire [31:0] id_csr_content;

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
        id_ex_pl_imm <= id_final_imm;
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
    wire [WORD_WIDTH_IN_BIT-1:0] mem_read_data; // data read from mem, latched
    // memory mapped io, read avai buffer space
    reg [WORD_WIDTH_IN_BIT-1:0] mem_io_buffer_size_avai_port_a;
    always @(posedge clk) begin
        if (addr_a == `OUTPUT_BYTES_AVAI_ADDR)
            mem_io_buffer_size_avai_port_a <= io_buffer_size_avai;
    end
    
    // MEM-WB pipeline
    // --------------------------------------------------------------------------------------------
    reg [2:0] mem_wb_pl_funct3;
    reg [WORD_WIDTH_IN_BIT-1:0] mem_wb_pl_imm;
    // data read from mem
    wire [WORD_WIDTH_IN_BIT-1:0] mem_wb_pl_read_data;// = mem_read_data;
    // control signal generation
    reg mem_wb_pl_regfile_write_en;
    reg [3:0] mem_wb_pl_regfile_write_width;
    reg [1:0] mem_wb_pl_regfile_write_data;
    // command parsing
    reg [4:0] mem_wb_pl_parse_rd;
    // result from EX section
    reg [WORD_WIDTH_IN_BIT-1:0] mem_wb_pl_alu_result;
    reg [WORD_WIDTH_IN_BIT-1:0] mem_wb_pl_ex_calculated_pc;

    assign mem_wb_pl_read_data = 
        (mem_wb_pl_alu_result == `OUTPUT_BYTES_AVAI_ADDR) 
        ? mem_io_buffer_size_avai_port_a 
        : mem_read_data;

    always @(posedge clk) begin 
        mem_wb_pl_funct3 <= ex_mem_pl_funct3;
        mem_wb_pl_imm <= ex_mem_pl_imm;
        // control signal generation
        mem_wb_pl_regfile_write_width <= ex_mem_pl_regfile_write_width;
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
    wire [WORD_WIDTH_IN_BIT-1:0] wb_read_data_ext;
    always @(*) begin 
        case (mem_wb_pl_regfile_write_data)

            `REGFILE_DATA_FROM_ALU: 
                wb_write_data = mem_wb_pl_alu_result;
            `REGFILE_DATA_FROM_DATAMEM:
                wb_write_data = wb_read_data_ext;
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

    assign en_a = (addr_a == `OUTPUT_BYTES_ADDR) ? 1'b0 : 1'b1; // disable if accessing io
    assign we_a = ex_mem_pl_datamem_write_en 
        ? (ex_mem_pl_datamem_write_width << ex_mem_pl_alu_result[1:0]) 
        : 4'b0;
    assign addr_a = ex_mem_pl_alu_result;
    assign din_a = ex_mem_pl_rs2_data << (ex_mem_pl_alu_result[1:0] * 8);
    assign mem_read_data = dout_a;

    assign en_b = !stall_id_if_pl || chg_addr;
    assign we_b = 4'b0;
    assign addr_b = if1_pc;
    assign din_b = 32'b0;
    assign if2_inst = dout_b;

    /*
    // using the flat addressing NewUnifiedMemory
    NewUnifiedMemory #(
        .MEMORY_WIDTH_IN_BYTE(WORD_WIDTH_IN_BYTE),
        .MEMORY_DEPTH_IN_WORD(1048576) // 4MiB
    ) unified_memory_instance (
        // port A - general use
        .clk_a(clk),
        .reset_a(reset),
        .en_a(1'b1),
        .we_a(ex_mem_pl_datamem_write_en 
            ? (ex_mem_pl_datamem_write_width << ex_mem_pl_alu_result[1:0])
            : 4'b0),
        .addr_a(ex_mem_pl_alu_result),
        .din_a(ex_mem_pl_rs2_data << (ex_mem_pl_alu_result[1:0] * 8)),
        .dout_a(mem_read_data),
        // port B - instruction fetch
        .clk_b(clk),
        .reset_b(reset),
        .en_b(!stall_id_if_pl || chg_addr),
        .we_b(4'b0),
        .addr_b(if1_pc),
        .din_b(32'b0),
        .dout_b(if2_inst),
        // external output io
        .io_output_en(io_output_en),
        .io_output_data(io_output_data),
        .io_buffer_size_avai(io_buffer_size_avai)
    );
    */

    Orchestrator #(
        .INST_WIDTH_IN_BIT(WORD_WIDTH_IN_BIT)
    ) orchestrator_instance (
        .clk(clk),
        .reset(reset), // positive assertion, sychrnonous reset
        .next_inst(final_if_inst),
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
        .write_reg_addr(mem_wb_pl_parse_rd),
        .write_data(wb_write_data)
    );

    ImmediateGen immediate_gen_instance (
        .inst(if_id_pl_inst),
        .immediate(id_imm)
    );

    ZicntrReg zicntr_reg_instance (
        .clk(clk),
        .reset(reset),
        .disable_instret_increment(stall_id_if_pl),
        .csr_addr(id_parse_csr),
        .csr_content(id_csr_content)
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
        .read_data(mem_wb_pl_read_data),
        .funct3(mem_wb_pl_funct3),
        .byte_offset(mem_wb_pl_alu_result[1:0]),
        .read_data_ext(wb_read_data_ext)
    );

    DirectionalBuffer #(
        .BUFFER_BYTE_SIZE(OUTPUT_BUFFER_BYTE_SIZE)
    ) io_output_buffer (

        .clk(clk), // port A considered general use
        .reset(reset),
        // read/write interface
        .input_en(!reset && en_a && (we_a != 0) && (addr_a == `OUTPUT_BYTES_ADDR)),
        .input_data(din_a[7:0]),
        .buffer_size_avai(io_buffer_size_avai),
        .output_en(io_output_en),
        .output_data(io_output_data)
    );

endmodule
