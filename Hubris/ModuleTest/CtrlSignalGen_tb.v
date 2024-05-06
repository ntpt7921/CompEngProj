`define FUNCT3_MEM_LB       3'b000
`define FUNCT3_MEM_LH       3'b001
`define FUNCT3_MEM_LW       3'b010
`define FUNCT3_MEM_LBU      3'b100
`define FUNCT3_MEM_LHU      3'b101
`define FUNCT3_MEM_SB       3'b000
`define FUNCT3_MEM_SH       3'b001
`define FUNCT3_MEM_SW       3'b010

module tb;

    reg [31:0] inst;
    // ALU control
    wire [3:0] alu_cmd;
    wire alu_src;
    // registerFile control
    wire regfile_write_en;
    wire [3:0] regfile_write_width;
    wire [1:0] regfile_write_data;
    // DataMemory control
    wire datamem_write_en;
    wire [3:0] datamem_write_width;
    // other control
    wire add_4_pc;

    // test function
    reg [2:0] funct3;
    wire [3:0] func_output;

    CtrlSignalGen dut (
        .inst(inst),
        // ALU control
        .alu_cmd(alu_cmd),
        .alu_src(alu_src),
        // RegisterFile control
        .regfile_write_en(regfile_write_en),
        .regfile_write_width(regfile_write_width),
        .regfile_write_data(regfile_write_data),
        // DataMemory control
        .datamem_write_en(datamem_write_en),
        .datamem_write_width(datamem_write_width),
        // other control
        .add_4_pc(add_4_pc)
    );

    function [3:0] load_store_width_or_type_from_funct3;
        input [2:0] funct3;
        begin 
            load_store_width_or_type_from_funct3 = 4'bx;
            case (funct3)
                `FUNCT3_MEM_LB: load_store_width_or_type_from_funct3 = 4'd1;
                `FUNCT3_MEM_LH: load_store_width_or_type_from_funct3 = 4'd2;
                `FUNCT3_MEM_LW: load_store_width_or_type_from_funct3 = 4'd4;
                `FUNCT3_MEM_LBU: load_store_width_or_type_from_funct3 = 4'd1;
                `FUNCT3_MEM_LHU: load_store_width_or_type_from_funct3 = 4'd2;
                `FUNCT3_MEM_SB: load_store_width_or_type_from_funct3 = 4'd1;
                `FUNCT3_MEM_SH: load_store_width_or_type_from_funct3 = 4'd2;
                `FUNCT3_MEM_SW: load_store_width_or_type_from_funct3 = 4'd4;
                default: load_store_width_or_type_from_funct3 = 4'bx;
            endcase
        end
    endfunction

    assign func_output = load_store_width_or_type_from_funct3(funct3);

    initial begin
        inst = 32'h00152023;
        #1 funct3 = `FUNCT3_MEM_LB;
        #1 funct3 = `FUNCT3_MEM_LH;
        #1 funct3 = `FUNCT3_MEM_LW;
        #1 funct3 = `FUNCT3_MEM_LBU;
        #1 funct3 = `FUNCT3_MEM_LHU;
        #1 funct3 = `FUNCT3_MEM_SB;
        #1 funct3 = `FUNCT3_MEM_SH;
        #1 funct3 = `FUNCT3_MEM_SW;

        #1;

        $finish;
    end

    initial begin
        $monitor("%h\t%h\t%h\t%h\t%h", 
            alu_cmd, alu_src, 
            datamem_write_en, datamem_write_width, 
            func_output);
    end

endmodule
