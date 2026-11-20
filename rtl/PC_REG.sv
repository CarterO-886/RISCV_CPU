`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: California Polytechnic University, San Luis Obispo
// Engineer: Carter Oates
// Create Date: 01/24/2023 09:30:07 AM
// Module Name: PC_REG
//////////////////////////////////////////////////////////////////////////////////

module PC_REG(
    input logic clk,
    input logic rst,
    input logic d,
    input logic [31:0] in,
    output logic [31:0] out
    );
    
    //Create PC Register!
    always_ff@(posedge clk) begin
        if (rst == 1'b1) begin //If reset is high, set PC output to 0
            out <= 32'h00000000;
        end
        else if (d == 1'b1) begin //if Reset is low and D is high,
            out <= in;              //set PC output to the input!
        end
    end
    
endmodule
