`define INVALID_INST    32'hC0001073

`define OPCODE_OP       7'b0110011
`define OPCODE_OP_IMM   7'b0010011
`define OPCODE_LUI      7'b0110111
`define OPCODE_AUIPC    7'b0010111
`define OPCODE_JAL      7'b1101111
`define OPCODE_JALR     7'b1100111
`define OPCODE_BRANCH   7'b1100011
`define OPCODE_LOAD     7'b0000011
`define OPCODE_STORE    7'b0100011

module Orchestrator #(
    parameter INST_WIDTH_IN_BIT = 32
)(
    input clk,
    input reset, // positive assertion, sychrnonous reset
    input [INST_WIDTH_IN_BIT-1:0] next_inst,
    input [INST_WIDTH_IN_BIT-1:0] curr_inst,
    input [INST_WIDTH_IN_BIT-1:0] prev_inst,

    output stall_id_if_pl,
    output stall_pc_increment,
    output halt
);

    // parsing instruction into field
    wire [6:0] opcode_next_inst = next_inst[6:0];
    wire [6:0] opcode_curr_inst = curr_inst[6:0];
    wire [6:0] opcode_prev_inst = prev_inst[6:0];

    wire [4:0] rd_curr_inst = curr_inst[11:7];
    wire [4:0] rd_prev_inst = prev_inst[11:7];
    
    wire [4:0] rs1_next_inst = next_inst[19:15];
    wire [4:0] rs2_next_inst = next_inst[24:20];


    // halt state and halt output
    reg halt_state;
    reg [1:0] clk_till_halt; // count down clk cycle so all pipeline is clean
    
    always @(posedge clk) begin
        if (reset)
            halt_state <= 0;
        else if (curr_inst == `INVALID_INST)
            halt_state <= 1;
        else
            halt_state <= halt_state;
    end

    always @(posedge clk) begin
        if (reset)
            clk_till_halt <= 2;
        else if (halt_state == 1 && clk_till_halt != 0)
            clk_till_halt <= clk_till_halt - 1;
        else
            clk_till_halt <= clk_till_halt;
    end

    assign halt = halt_state && (clk_till_halt == 0);

    /*
     * NOTE: stalling logic
     * * Load:
     *  - stall for 2 cycle when encountering load instructions
     *  - implement by checking curr_inst and prev_inst
     * * Branch:
     *  - stall for 1 cycle
     *  - implement by checking curr_inst
     * * Jump:
     *  - stall for 2 cycle when encountering jump instructions
     *  - implement by checking curr_inst and prev_inst
     * * ALU:
     *  - stall when rd_curr_inst == rs1_next_inst | rs2_next_inst 
     *            OR rd_prev_inst == rs1_next_inst | rs2_next_inst
    */

    // logic for stall_id_if_pl signal
    wire pl_load_stall = (opcode_curr_inst == `OPCODE_LOAD) || (opcode_prev_inst == `OPCODE_LOAD);
    wire pl_branch_stall = (opcode_curr_inst == `OPCODE_BRANCH);
    wire pl_jump_stall = (opcode_curr_inst == `OPCODE_JAL) || (opcode_curr_inst == `OPCODE_JALR);
    reg pl_alu_stall;
    
    function is_alu_opcode;
        input opcode;
        begin 
            is_alu_opcode = (opcode_curr_inst == `OPCODE_OP 
                            || opcode_curr_inst == `OPCODE_LUI 
                            || opcode_curr_inst == `OPCODE_AUIPC);
        end
    endfunction
    
    always @(*) begin 
        pl_alu_stall = 0;

        if (is_alu_opcode(opcode_curr_inst) 
            && is_alu_opcode(opcode_next_inst) 
            && (rd_curr_inst == rs1_next_inst || rd_curr_inst == rs2_next_inst))
                pl_alu_stall = 1;

        if (is_alu_opcode(opcode_prev_inst) 
            && is_alu_opcode(opcode_prev_inst) 
            && (rd_prev_inst == rs1_next_inst || rd_prev_inst == rs2_next_inst))
                pl_alu_stall = 1;
    end
    
    assign stall_id_if_pl = halt_state 
        || pl_jump_stall || pl_load_stall || pl_alu_stall || pl_branch_stall; 

    // logic for stall_pc_increment signal
    assign stall_pc_increment = stall_id_if_pl;

endmodule
