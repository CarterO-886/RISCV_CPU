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


module Instruction_Memory(
    localparam ADDR_WIDTH = ,
    localparam DATA_WIDTH = ,

    logic [31:0] storage_array [255:0]  //i-bit address with max 2^i words of storage

)(
    input logic CLK,

    input logic RST,

    input logic [ADDR_WIDTH-1:0] pc_in,

    output logic [DATA_WIDTH-1:0] data_out1,
    output logic [DATA_WIDTH-1:0] data_out2,
    output logic [DATA_WIDTH-1:0] data_out3,
    output logic [DATA_WIDTH-1:0] data_out4,
    output logic [DATA_WIDTH-1:0] data_out5,
    output logic [DATA_WIDTH-1:0] data_out6,
    output logic [DATA_WIDTH-1:0] data_out7,
    output logic [DATA_WIDTH-1:0] data_out8,

);


initial begin
    $readmeh("memory.mem", storage_array);
end

always_ff @(posedge CLK) begin

    assign data_out1 = storage_array[pc_in]
    assign data_out2 = storage_array[pc_in + 1]
    assign data_out3 = storage_array[pc_in + 2]
    assign data_out4 = storage_array[pc_in + 3]
    assign data_out5 = storage_array[pc_in + 4]
    assign data_out6 = storage_array[pc_in + 5]
    assign data_out7 = storage_array[pc_in + 6]
    assign data_out8 = storage_array[pc_in + 7]

end

endmodule
