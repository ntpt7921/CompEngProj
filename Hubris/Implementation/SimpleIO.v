/*
* NOTE:
* this module also allows for memory-mapped IO, placed at addr 32'h8000_0000
* onward. it uses DirectionalBuffer internally
*   - UART output takes 8 bytes (2 words), in order:
*       - output_bytes_avai (4 bytes) - 32'h8000_0000: can be read, contains
*       current number of available output buffer bytes. writing to this have no
*       effect
*       - output_bytes (4 bytes) - 32'h8000_0004: each write to this (at any width)
*       store a byte of output data situated at the least significant byte of
*       the write data. read to this return undefined value
*   - UART input takes 8 bytes (2 words), in order:
*       - input_bytes_avai (4 bytes) - 32'h8000_0008: can be read, contains
*       current number of available output buffer bytes. writing to this have no
*       effect
*       - input_bytes (4 bytes) - 32'h8000_000C: can be read, contains current 
*       available output buffer bytes. writing to this have no effect
*/

`define OUTPUT_BYTES_AVAI_ADDR  32'h8000_0000
`define OUTPUT_BYTES_ADDR       32'h8000_0004
`define INPUT_BYTES_AVAI_ADDR   32'h8000_0008
`define INPUT_BYTES_ADDR        32'h8000_000C

module SimpleIO #(
    parameter OUTPUT_BUFFER_BYTE_SIZE = 32,
    parameter INPUT_BUFFER_BYTE_SIZE = 32,
    parameter WORD_WIDTH_IN_BYTE = 4,
    parameter WORD_WIDTH_IN_BIT = WORD_WIDTH_IN_BYTE * 8,
    parameter UART_INTERNAL_CLK_PER_BAUD = 434 // value for 115200 baud, 50MHz internal clk
)(
    input clk,
    input reset,
    // memory port interface
    input en_a,
    input [3:0] we_a,
    input [31:0] addr_a,
    input [WORD_WIDTH_IN_BIT-1:0] din_a,
    output reg [WORD_WIDTH_IN_BIT-1:0] dout_a,
    // signal for busy tx
    output busy_tx,
    // external io
    input io_input_rx,
    output io_output_tx
);

    // reading part
    wire [WORD_WIDTH_IN_BIT-1:0] output_buffer_avai;
    wire [WORD_WIDTH_IN_BIT-1:0] input_buffer_avai;
    wire [7:0] input_byte_value;

    always @(posedge clk) begin
        if (!reset && en_a) begin
            case (addr_a)

                `OUTPUT_BYTES_AVAI_ADDR:
                    dout_a <= output_buffer_avai;
                `OUTPUT_BYTES_ADDR:
                    dout_a <= {WORD_WIDTH_IN_BIT {1'bx}};
                `INPUT_BYTES_AVAI_ADDR:
                    dout_a <= input_buffer_avai;
                `INPUT_BYTES_ADDR:
                    dout_a <= input_byte_value;

                default:
                    dout_a <= {WORD_WIDTH_IN_BIT {1'bx}};
            endcase
        end
    end

    wire have_byte_rx;
    wire [7:0] byte_rx;

    DirectionalBuffer #(
        .BUFFER_BYTE_SIZE(INPUT_BUFFER_BYTE_SIZE)
    ) input_buffer (

        .clk(clk),
        .reset(reset),
        // read/write interface
        .input_en(have_byte_rx),
        .input_data(byte_rx),
        .buffer_size_avai(input_buffer_avai),
        .output_en(!reset && en_a && (addr_a == `INPUT_BYTES_ADDR)),
        .output_data(input_byte_value)
    );

    wire tx_done;
    wire new_transmit_tx = (output_buffer_avai < OUTPUT_BUFFER_BYTE_SIZE) && !busy_tx && !tx_done;
    wire [7:0] byte_tx;

    DirectionalBuffer #(
        .BUFFER_BYTE_SIZE(OUTPUT_BUFFER_BYTE_SIZE)
    ) output_buffer (

        .clk(clk),
        .reset(reset),
        // read/write interface
        .input_en(!reset && en_a && (we_a != 0) && (addr_a == `OUTPUT_BYTES_ADDR)),
        .input_data(din_a[7:0]),
        .buffer_size_avai(output_buffer_avai),
        .output_en(new_transmit_tx),
        .output_data(byte_tx)
    );

    uart_rx #(
        .CLKS_PER_BIT(UART_INTERNAL_CLK_PER_BAUD)
    ) input_uart (
        .i_Clock(clk),
        .i_Rx_Serial(io_input_rx),
        .o_Rx_Done(have_byte_rx),
        .o_Rx_Byte(byte_rx)
    );

    uart_tx #(
        .CLKS_PER_BIT(UART_INTERNAL_CLK_PER_BAUD)
    ) output_uart (
        .i_Clock(clk),
        .i_Tx_DV(new_transmit_tx),
        .i_Tx_Byte(byte_tx), 
        .o_Tx_Active(busy_tx),
        .o_Tx_Serial(io_output_tx),
        .o_Tx_Done(tx_done)
    );

endmodule
