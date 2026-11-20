`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Cal Poly San Luis Obispo
// Engineer: Carter Oates
// Module Name: ImmediateGenerator
//////////////////////////////////////////////////////////////////////////////////

module ImmediateGenerator(
    input logic [24:0] ir,
    output logic [31:0] u_type,
    output logic [31:0] i_type,
    output logic [31:0] s_type,
    output logic [31:0] b_type,
    output logic [31:0] j_type
    );
    
    //Assign each immediate value. 
    assign i_type = {{21{ir[24]}}, ir[23:18], ir[17:13]};
    assign s_type = {{21{ir[24]}}, ir[23:18], ir[4:0]};
    assign b_type = {{20{ir[24]}}, ir[0], ir[23:18], ir[4:1], 1'b0};
    assign u_type = {ir[24:5], 12'b0};
    assign j_type = {{12{ir[24]}}, ir[12:5], ir[13], ir[23:14], 1'b0};
    
endmodule
