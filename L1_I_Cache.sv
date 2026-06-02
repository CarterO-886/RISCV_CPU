`timescale 1ns / 1ps

module L1_I_Cache (
    input  logic [31:0] PC,
    input  logic        CLK,
    input  logic        RST,
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

    localparam NUM_BLOCKS       = 16;
    localparam BLOCK_SIZE       = 8;
    localparam INDEX_SIZE       = 4;
    localparam WORD_OFFSET_SIZE = 3;
    localparam BYTE_OFFSET_SIZE = 2;
    localparam TAG_SIZE         = 32 - INDEX_SIZE - WORD_OFFSET_SIZE - BYTE_OFFSET_SIZE;

    logic [31:0]          data [NUM_BLOCKS-1:0][BLOCK_SIZE-1:0];
    logic [TAG_SIZE-1:0]  tags [NUM_BLOCKS-1:0];
    logic                 valid_bits [NUM_BLOCKS-1:0];
    logic [INDEX_SIZE-1:0] index;
    logic [WORD_OFFSET_SIZE-1:0] pc_offset;
    logic [TAG_SIZE-1:0]  pc_tag;

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
        for (int i = 0; i < NUM_BLOCKS; i++) begin
            tags[i]       = '0;
            valid_bits[i] = 1'b0;
            for (int j = 0; j < BLOCK_SIZE; j++)
                data[i][j] = 32'b0;
        end
    end

    always_ff @(posedge CLK) begin
        if (RST) begin
            for (int i = 0; i < NUM_BLOCKS; i++)
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
