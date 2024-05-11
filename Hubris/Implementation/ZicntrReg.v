`define CYCLE_REG_ADDR        12'hC00
`define TIME_REG_ADDR         12'hC01
`define INSTRET_REG_ADDR      12'hC02
`define CYCLEH_REG_ADDR       12'hC80
`define TIMEH_REG_ADDR        12'hC81
`define INSTRETH_REG_ADDR     12'hC82

module ZicntrReg (
    input clk,
    input reset, // positive assertion, sychrnonous reset
    input disable_instret_increment,
    input [11:0] csr_addr,
    output reg [31:0] csr_content
);

    reg [63:0] cycle_reg;
    reg [63:0] time_reg;
    reg [63:0] instret_reg;

    // reset logic
    always @(posedge clk) begin
        if (reset) begin
            cycle_reg <= 0;
            time_reg <= 0;
            instret_reg <= 0;
        end
        else begin
            cycle_reg <= cycle_reg + 1;
            time_reg <= time_reg + 1;
            if (!disable_instret_increment)
                instret_reg <= instret_reg + 1;
        end
    end

    // read csr logic
    always @(*) begin
        case (csr_addr)

            `CYCLE_REG_ADDR:
                csr_content = cycle_reg[31:0];
            `TIME_REG_ADDR:
                csr_content = time_reg[31:0];
            `INSTRET_REG_ADDR:
                csr_content = instret_reg[31:0];
            `CYCLEH_REG_ADDR:
                csr_content = cycle_reg[63:32];
            `TIMEH_REG_ADDR:
                csr_content = time_reg[63:32];
            `INSTRETH_REG_ADDR:
                csr_content = instret_reg[63:32];

            default:
                csr_content = 32'bx;
        endcase
    end

endmodule
