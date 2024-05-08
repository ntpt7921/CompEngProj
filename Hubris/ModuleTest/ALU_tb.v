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

module tb;

    reg [31:0] rs1;
    reg [31:0] rs2;
    reg [3:0] alu_cmd;
    wire [31:0] out;

    ALU dut (
        .rs1(rs1),
        .rs2(rs2),
        .alu_cmd(alu_cmd),
        .out(out)
    );

    initial begin
        rs1 = 32'h8000_0000;
        rs2 = 32'd8;
        alu_cmd = `ALU_CMD_SRA;
        #1;
        $finish;
    end

    initial begin
        $monitor("%h\t%h\t%h\t%h", 
            rs1, rs2, alu_cmd, out);
    end

endmodule
