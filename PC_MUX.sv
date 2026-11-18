`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: California Polytechnic University, San Luis Obispo
// Engineer: Carter Oates
// Create Date: 01/24/2023 09:30:07 AM
// Module Name: PC_MUX
//////////////////////////////////////////////////////////////////////////////////

module PC_MUX(
    input logic [31:0] pc_out_plus_four,
    input logic [31:0] jalr,
    input logic [31:0] branch,
    input logic [31:0] jal,
    input logic [31:0] mtvec,
    input logic [31:0] mepc,
    input logic [2:0] pc_source,
    output logic [31:0] pc_mux_out
    );
    
    //Case statement depending on PC_SOURCE
    always_comb begin
        case(pc_source)
            3'b000: begin pc_mux_out = pc_out_plus_four;
            end
            3'b001: begin pc_mux_out = jalr;
            end
            3'b010: begin pc_mux_out = branch;
            end
            3'b011: begin pc_mux_out = jal;
            end
            3'b100: begin pc_mux_out = mtvec;
            end
            3'b101: begin pc_mux_out = mepc;
            end
            3'b110: begin pc_mux_out = 32'h00000006; //Set to 6 to know what the select is, shouldn't happen
            end                                     //shouldn't happen
            3'b111: begin pc_mux_out = 32'h00000007; //Set to 7 to know what the select is, shouldn't happen
            end                                      //shouldn't happen
            default: begin pc_mux_out = 32'h00000000; //Set to 8 to know what the select is, shouldn't happen
            end                                       //shouldn't happen
        endcase
    end
endmodule
