`timescale 1ns / 1ps

module Data_Memory #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter LINE_WORDS = 8,
    parameter DEPTH      = 16384
)(
    input  logic                  CLK,
    input  logic                  RST,
    input  logic                  read_en,
    input  logic                  write_en,
    input  logic [ADDR_WIDTH-1:0] read_addr,
    input  logic [ADDR_WIDTH-1:0] write_addr,
    input  logic [DATA_WIDTH-1:0] write_w0,
    input  logic [DATA_WIDTH-1:0] write_w1,
    input  logic [DATA_WIDTH-1:0] write_w2,
    input  logic [DATA_WIDTH-1:0] write_w3,

    output logic [DATA_WIDTH-1:0] out1,
    output logic [DATA_WIDTH-1:0] out2,
    output logic [DATA_WIDTH-1:0] out3,
    output logic [DATA_WIDTH-1:0] out4
);

    localparam LINE_WIDTH = DATA_WIDTH * LINE_WORDS;
    localparam LINE_DEPTH = DEPTH / LINE_WORDS;

    (* ram_style = "block" *) logic [LINE_WIDTH-1:0] line_array [0:LINE_DEPTH-1];
    logic [LINE_WIDTH-1:0] line_q;
    logic                  read_upper_half_q;
    logic [10:0]           read_index;
    logic [10:0]           write_index;

    assign read_index  = read_addr[15:5];
    assign write_index = write_addr[15:5];

    assign out1 = read_upper_half_q ? line_q[159:128] : line_q[31:0];
    assign out2 = read_upper_half_q ? line_q[191:160] : line_q[63:32];
    assign out3 = read_upper_half_q ? line_q[223:192] : line_q[95:64];
    assign out4 = read_upper_half_q ? line_q[255:224] : line_q[127:96];

    initial begin
        $readmemh("performance_l2_lines.mem", line_array, 0, LINE_DEPTH-1);
    end

    always_ff @(posedge CLK) begin
        if (RST) begin
            line_q <= '0;
            read_upper_half_q <= 1'b0;
        end else begin
            if (write_en) begin
                if (write_addr[4])
                    line_array[write_index][255:128] <= {write_w3, write_w2, write_w1, write_w0};
                else
                    line_array[write_index][127:0] <= {write_w3, write_w2, write_w1, write_w0};
            end

            if (read_en) begin
                line_q <= line_array[read_index];
                read_upper_half_q <= read_addr[4];
            end
        end
    end

endmodule
