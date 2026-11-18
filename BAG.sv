`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Cal Poly San Luis Obispo 
// Engineer: Carter Oates
// Module Name: BAG (Branch Address Generator)
//Description: This module generates the branch addresses for the JAL, JALR, and Branch instructions.
//////////////////////////////////////////////////////////////////////////////////

module BAG(
    input logic [31:0] rs1,
    input logic [31:0] i_type,
    input logic [31:0] j_type,
    input logic [31:0] b_type,
    input logic [31:0] from_pc,
    output logic [31:0] jal,
    output logic [31:0] jalr,
    output logic [31:0] branch
    );
    
    //Assign each branch address.
    assign jal = from_pc + j_type;
    assign jalr = i_type + rs1;
    assign branch = from_pc + b_type;
    
endmodule
