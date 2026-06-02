`timescale 1ns / 1ps

module Instruction_Memory #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter LINE_WORDS = 8,
    parameter DEPTH      = 16384
)(
    input  logic                  CLK,
    input  logic                  RST,
    input  logic                  read_en,
    input  logic [ADDR_WIDTH-1:0] pc_in,

    output logic [DATA_WIDTH-1:0] data_out1,
    output logic [DATA_WIDTH-1:0] data_out2,
    output logic [DATA_WIDTH-1:0] data_out3,
    output logic [DATA_WIDTH-1:0] data_out4,
    output logic [DATA_WIDTH-1:0] data_out5,
    output logic [DATA_WIDTH-1:0] data_out6,
    output logic [DATA_WIDTH-1:0] data_out7,
    output logic [DATA_WIDTH-1:0] data_out8
);

    localparam LINE_WIDTH = DATA_WIDTH * LINE_WORDS;
    localparam LINE_DEPTH = DEPTH / LINE_WORDS;

    (* ram_style = "block" *) logic [LINE_WIDTH-1:0] line_array [0:LINE_DEPTH-1];
    logic [LINE_WIDTH-1:0] line_q;
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
        $readmemh("performance_l2_lines.mem", line_array, 0, LINE_DEPTH-1);
    end

    always_ff @(posedge CLK) begin
        if (RST)
            line_q <= {LINE_WORDS{32'h00000013}};
        else if (read_en)
            line_q <= line_array[line_index];
    end

endmodule
