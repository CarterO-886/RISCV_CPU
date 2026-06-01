'timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Author: Carter Oates
// Create Date: 5/20/26 
// Module Name: L1_D_Cache
// Description: L1 Data Cache Memory for two stage data memory architecture for OTTER
// Function: Highest part of data memory architecure. Stores bulk addresses and data. 
//           Simply will output blocks of data for a direct address cahce setup.
//           Don't normally want to do this because it is very space hungry on raw silicon. 
// Summary:  Bulk storage unit 
//////////////////////////////////////////////////////////////////////////////////

module L1_D_Cache (

    localparam num_block = 16,
    localparam block_size = 4;
    localparam ways = 4,
    localparam words_per_block = block_size/ways, // 4 words per block
    localparam sets = 4,

    localparam offset = 4,
    localparam index = 2
    localparam tag = 32 - offset - index, // 26 bits for tag
)(
    input CLK,

    input RST,

    //normal inputs
    input [31:0]alu_result,
    input [31:0]rs1_data,

    input data_read,
    input data_write,

    //FSM inputs
    input FSM_write,
    
    //outputs
    output miss,
    output hit,
    output [31:0]data
    output [31:0]L2_data,

   

);

logic [31:0] cache_data[sets-1:0][ways-1:0][words_per_block-1:0]; // 2 sets, 4 ways, 4 words per block
logic [tag-1:0] cache_tags[sets-1:0][ways-1:0]; // 2 sets, 4 ways, 26 bit tags
logic valid_bits[sets-1:0][ways-1:0]; // 2 sets, 4 ways, valid bits
logic dirty_bits[sets-1:0][ways-1:0];


assign miss = !hit;

//Cache is initially empty
initial begin 
        int i;
        int j;
        for (i = 0; i < num_blocks; i = i + 1) begin //initializing RAM to 0
            for (j = 0; j < block_size; j = j + 1)
                cache_data[i][j] = 32'b0;
            cache_tags[i]       = 32'b0;
            valid_bits[i] = 1'b0;
            dirty_bits[i] = 1'b0;
        end
    end

//Normal operation
always_ff @(posedge CLK) begin

    if(data_read)
        for (i = 0, i < alu_result[5:4], i = i + 1) begin
            if (valid_bits[alu_result[5:4]][i] && cache_tags[alu_result[5:4]][i] == alu_result[31:6]) begin
                hit <= 1;
                data <= cache_data[alu_result[5:4]][i][alu_result[3:2]];
            end
        end
    
    if(data_write)
        for (i = 0, i < alu_result[5:4], i = i + 1) begin
            for (j=0, j < ways, j = j + 1) begin
                if (valid_bits[alu_result[5:4]][i] && cache_tags[alu_result[5:4]][i] == alu_result[31:6]) begin
                    if (dirty_bits[alu_result[5:4]][i] == 1'b1) begin
                        L2_data <= cache_data[alu_result[5:4]][i][0]; // Write back the first word of the block to L2
                        cache_data[alu_result[5:4]][i][0] <= rs1_data; // Update the first word of the block with new data
                        dirty_bits[alu_result[5:4]][i] <= 1; // Mark block as dirty after write
                    end else begin
                        cache_data[alu_result[5:4]][i][alu_result[3:2]] <= rs1_data;
                        dirty_bits[alu_result[5:4]][i] <= 1; // Mark block as dirty on write
                    end
                end
        end
        end

endmodule