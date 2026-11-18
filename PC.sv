`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: California Polytechnic University, San Luis Obispo
// Engineer: Carter Oates
// Create Date: 01/24/2023 09:30:07 AM
// Module Name: PC
//////////////////////////////////////////////////////////////////////////////////

module PC(
    input logic clk,
    input logic rst,
    input logic pc_write,
    input logic [2:0] pc_source,
    input logic [31:0] jalr,
    input logic [31:0] branch,
    input logic [31:0] jal,
    input logic [31:0] mtvec,
    input logic [31:0] mepc,
    output logic [31:0] pc_out,
    output logic [31:0] pc_out_inc
    );
    
    //Create logic for intermediate signals to serve as wires between modules
    logic [31:0] pc_out_plus_four, pc_in;
    
    //Assign values to outputs
    assign pc_out_plus_four = pc_out + 4;
    assign pc_out_inc = pc_out_plus_four;
    
    //Instantiate PC Multiplexer
    PC_MUX pcmux(.pc_out_plus_four(pc_out_plus_four), .jalr(jalr), .branch(branch),
     .jal(jal), .mtvec(mtvec), .mepc(mepc), .pc_source(pc_source), .pc_mux_out(pc_in));
    
    //Instantiate PC Register
    PC_REG pcreg(.clk(clk), .rst(rst), .d(pc_write), .in(pc_in), .out(pc_out));
    
endmodule
