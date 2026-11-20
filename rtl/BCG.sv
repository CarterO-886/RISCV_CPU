`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Cal Poly San Luis Obispo
// Engineer: Carter Oates
// Create Date: 02/09/2023 11:30:51 AM
// Module Name: BCG
//////////////////////////////////////////////////////////////////////////////////

module BCG(
    input logic [31:0] rs1,
    input logic [31:0] rs2,
    output logic br_eq,
    output logic br_lt,
    output logic br_ltu
    );
    
    //Assign outputs using conditional logic operators.
    assign br_lt = $signed(rs1) < $signed(rs2);
    assign br_ltu = rs1 < rs2;
    assign br_eq = rs1 == rs2;
    
endmodule
