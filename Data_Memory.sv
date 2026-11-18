`timescale 1ns / 1ps

module Data_Memory #(
    parameter addr_width = 32,
    parameter data_width = 32,
    parameter line_words = 8,
    parameter depth      = 16384
)(
    input  logic                  clk,
    input  logic                  rst,
    input  logic                  read_en,
    input  logic                  write_en,
    input  logic [addr_width-1:0] read_addr,
    input  logic [addr_width-1:0] write_addr,
    input  logic [data_width-1:0] write_w0,
    input  logic [data_width-1:0] write_w1,
    input  logic [data_width-1:0] write_w2,
    input  logic [data_width-1:0] write_w3,

    output logic [data_width-1:0] out1,
    output logic [data_width-1:0] out2,
    output logic [data_width-1:0] out3,
    output logic [data_width-1:0] out4
);

    localparam line_width = data_width * line_words;
    localparam line_depth = depth / line_words;

    (* ram_style = "block" *) logic [line_width-1:0] line_array [0:line_depth-1];
    logic [line_width-1:0] line_q;
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
        $readmemh("performance_l2_lines.mem", line_array, 0, line_depth-1);
    end

    always_ff @(posedge clk) begin
        if (rst) begin
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
