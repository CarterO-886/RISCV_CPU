`timescale 1ns / 1ps

module L1_I_Cache (
    input  logic [31:0] PC,
    input  logic        clk,
    input  logic        rst,
    input  logic        update,
    input  logic [31:0] w0,
    input  logic [31:0] w1,
    input  logic [31:0] w2,
    input  logic [31:0] w3,
    input  logic [31:0] w4,
    input  logic [31:0] w5,
    input  logic [31:0] w6,
    input  logic [31:0] w7,

    output logic [31:0] rd,
    output logic        hit,
    output logic        miss
);

    localparam num_blocks       = 16;
    localparam block_size       = 8;
    localparam index_size       = 4;
    localparam word_offset_size = 3;
    localparam byte_offset_size = 2;
    localparam tag_size         = 32 - index_size - word_offset_size - byte_offset_size;

    logic [31:0]          data [num_blocks-1:0][block_size-1:0];
    logic [tag_size-1:0]  tags [num_blocks-1:0];
    logic                 valid_bits [num_blocks-1:0];
    logic [index_size-1:0] index;
    logic [word_offset_size-1:0] pc_offset;
    logic [tag_size-1:0]  pc_tag;

    assign index     = PC[8:5];
    assign pc_offset = PC[4:2];
    assign pc_tag    = PC[31:9];
    assign hit       = valid_bits[index] && (tags[index] == pc_tag);
    assign miss      = ~hit;

    always_comb begin
        rd = 32'h00000013; // nop
        if (hit)
            rd = data[index][pc_offset];
    end

    initial begin
        for (int i = 0; i < num_blocks; i++) begin
            tags[i]       = '0;
            valid_bits[i] = 1'b0;
            for (int j = 0; j < block_size; j++)
                data[i][j] = 32'b0;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < num_blocks; i++)
                valid_bits[i] <= 1'b0;
        end else if (update) begin
            data[index][0]    <= w0;
            data[index][1]    <= w1;
            data[index][2]    <= w2;
            data[index][3]    <= w3;
            data[index][4]    <= w4;
            data[index][5]    <= w5;
            data[index][6]    <= w6;
            data[index][7]    <= w7;
            tags[index]       <= pc_tag;
            valid_bits[index] <= 1'b1;
        end
    end

endmodule
