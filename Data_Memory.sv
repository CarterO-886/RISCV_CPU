'timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Author: Carter Oates
// Create Date: 5/20/26 
// Module Name: Instruction_Memory
// Description: Basic Instruction Memory for two stage memory architecture for OTTER
// Function: Lowest part of memory architecure. Stores bulk addresses and data. 
//           Simply will output blocks of data for a direct address cahce setup.
//           Don't normally want to do this because it is very space hungry on raw silicon. 
// Summary:  Bulk storage unit 
//////////////////////////////////////////////////////////////////////////////////


module Data_Memory(

    localparam block_size = 16,
    localparam ADDR_WIDTH = 32,
    localparam DATA_WIDTH = 32,

    logic [31:0] data_array [0:16383]  //i-bit address with max 2^i words of storage

)(
    input logic CLK,

    input logic RST,

    input logic [ADDR_WIDTH-1:0] rs2_in,

    output logic [DATA_WIDTH-1:0] out1,
    output logic [DATA_WIDTH-1:0] out2,
    output logic [DATA_WIDTH-1:0] out3,
    output logic [DATA_WIDTH-1:0] out4,

);


initial $readmeh("memory.mem", storage_array,0,16383);


always_ff @(posedge CLK) begin

    assign out1 = data_array[rs2_in[31:2]]
    assign out2 = data_array[rs2_in[31:2] + 1]
    assign out3 = data_array[rs2_in[31:2] + 2]
    assign out4 = data_array[rs2_in[31:2] + 3]

end

endmodule
