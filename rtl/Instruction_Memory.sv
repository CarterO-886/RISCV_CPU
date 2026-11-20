`timescale 1ns / 1ps

module Instruction_Memory #(
    parameter addr_width = 32,
    parameter data_width = 32,
    parameter line_words = 8,
    parameter depth      = 16384
)(
    input  logic                  clk,
    input  logic                  rst,
    input  logic                  read_en,
    input  logic [addr_width-1:0] pc_in,

    output logic [data_width-1:0] data_out1,
    output logic [data_width-1:0] data_out2,
    output logic [data_width-1:0] data_out3,
    output logic [data_width-1:0] data_out4,
    output logic [data_width-1:0] data_out5,
    output logic [data_width-1:0] data_out6,
    output logic [data_width-1:0] data_out7,
    output logic [data_width-1:0] data_out8
);

    localparam line_width = data_width * line_words;
    localparam line_depth = depth / line_words;

    (* ram_style = "block" *) logic [line_width-1:0] line_array [0:line_depth-1];
    logic [line_width-1:0] line_q;
    logic [10:0]           line_index;

    assign line_index = pc_in[15:5];

    assign data_out1 = line_q[31:0];
    assign data_out2 = line_q[63:32];
    assign data_out3 = line_q[95:64];
    assign data_out4 = line_q[127:96];
    assign data_out5 = line_q[159:128];
    assign data_out6 = line_q[191:160];
    assign data_out7 = line_q[223:192];
    assign data_out8 = line_q[255:224];

    initial begin
        $readmemh("performance_l2_lines.mem", line_array, 0, line_depth-1);
    end

    always_ff @(posedge clk) begin
        if (rst)
            line_q <= {line_words{32'h00000013}};
        else if (read_en)
            line_q <= line_array[line_index];
    end

endmodule
