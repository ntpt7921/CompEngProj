/*
* NOTE:
* this module implement circular buffering with 1 byte input/ouput. if the
* buffer is full, subsequent write to them will be discarded.
* the buffer size must be a power of 2's
*/

module DirectionalBuffer #(
    parameter BUFFER_BYTE_SIZE= 4,
    parameter BUFFER_ADDR_SIZE = $clog2(BUFFER_BYTE_SIZE)
)(

    input clk,
    input reset,
    // read/write interface
    input input_en,
    input [7:0] input_data,
    output [BUFFER_ADDR_SIZE-1:0] buffer_size_avai,
    input output_en,
    output [7:0] output_data
);

    reg [7:0] buffer [0:BUFFER_BYTE_SIZE-1];
    reg [BUFFER_ADDR_SIZE-1:0] write_addr;
    reg [BUFFER_ADDR_SIZE-1:0] read_addr;
    reg [BUFFER_ADDR_SIZE-1:0] avai_count;

    integer i;
    always @(posedge clk) begin 

        // reset logic
        if (reset) begin
            for (i = 0; i < BUFFER_BYTE_SIZE; i = i + 1) 
                buffer[i] <= 0;
            write_addr <= 0;
            read_addr <= 0;
            avai_count <= 0;
        end
        // buffer read/write logic
        else begin
            if (input_en && !output_en) begin
                if (avai_count < BUFFER_BYTE_SIZE) begin
                    buffer[write_addr] <= input_data;
                    avai_count <= avai_count + 1;
                    write_addr <= (write_addr + 1) % BUFFER_BYTE_SIZE;
                end
            end

            if (!input_en && output_en) begin
                if (avai_count > 0) begin
                    avai_count <= avai_count - 1;
                    read_addr <= (read_addr + 1) % BUFFER_BYTE_SIZE;
                end
            end

            if (input_en && output_en) begin
                buffer[write_addr] <= input_data;
                read_addr <= (read_addr + 1) % BUFFER_BYTE_SIZE;
                write_addr <= (write_addr + 1) % BUFFER_BYTE_SIZE;
            end
        end

    end

    assign output_data = buffer[read_addr];
    assign buffer_size_avai = avai_count;

endmodule
