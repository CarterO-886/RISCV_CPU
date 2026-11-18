`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: California Polytechnic University, San Luis Obispo
// Engineer: Carter Oates
// Create Date: 02/25/2023 10:55:14 PM
// Module Name: FourMux
//////////////////////////////////////////////////////////////////////////////////

module FourMux(
    input logic [1:0] sel,
    input logic [31:0] zero,
    input logic [31:0] one,
    input logic [31:0] two,
    input logic [31:0] three,
    output logic [31:0] out
    );
    
    //Create a generic, four-to-one MUX. To be used for the Reg File
    //and the ALU.
    always_comb begin
        case(sel) //Case dependent on Select.
            2'b00: begin out = zero; end
            2'b01: begin out = one; end
            2'b10: begin out = two; end
            2'b11: begin out = three; end
            default: begin out = 32'b0; end
        endcase
    end
    
endmodule
