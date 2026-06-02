`timescale 1ns / 1ps

module Instruction_Memory #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
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

    logic [DATA_WIDTH-1:0] storage_array [0:DEPTH-1];
    logic [13:0] block_base;

    assign block_base = {pc_in[15:5], 3'b000};

    initial begin
        $readmemh("performance.mem", storage_array, 0, DEPTH-1);
    end

    always_ff @(posedge CLK) begin
        if (RST) begin
            data_out1 <= 32'h00000013;
            data_out2 <= 32'h00000013;
            data_out3 <= 32'h00000013;
            data_out4 <= 32'h00000013;
            data_out5 <= 32'h00000013;
            data_out6 <= 32'h00000013;
            data_out7 <= 32'h00000013;
            data_out8 <= 32'h00000013;
        end else if (read_en) begin
            data_out1 <= storage_array[block_base + 14'd0];
            data_out2 <= storage_array[block_base + 14'd1];
            data_out3 <= storage_array[block_base + 14'd2];
            data_out4 <= storage_array[block_base + 14'd3];
            data_out5 <= storage_array[block_base + 14'd4];
            data_out6 <= storage_array[block_base + 14'd5];
            data_out7 <= storage_array[block_base + 14'd6];
            data_out8 <= storage_array[block_base + 14'd7];
        end
    end

endmodule
