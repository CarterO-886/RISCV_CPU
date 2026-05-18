`timescale 1ns / 1ps

module Hazard_Unit(
    input  logic [2:0]  pc_sel,
    input  logic        ex_mem_rw,
    input  logic        mem_wb_rw,
    input  logic        de_ex_mr,  
    input  logic [4:0] if_id_rs1,  
    input  logic [4:0] de_ex_rs1,
    input  logic [4:0] if_id_rs2,
    input  logic [4:0] de_ex_rs2,
    input  logic [4:0] de_ex_rd,
    input  logic [4:0] ex_mem_rd,
    input  logic [4:0] mem_wb_rd,
    
    // OUTPUTS
    output logic        stall,
    output logic        [1:0]fwd_a,  
    output logic        [1:0]fwd_b,  
    output logic        flush
);


    always_comb begin
        // ==========================================
        //  DEFAULT OUTPUT VALUES (Prevents Latches)
        // ==========================================
        fwd_a  = 2'b00; 
        fwd_b  = 2'b00;

        stall = 1'b0;
        flush      = 1'b0;

        // ==========================================
        //  FORWARDING LOGIC (ALU Input A)
        // ==========================================
        if (ex_mem_rw && (ex_mem_rd != 0) && (ex_mem_rd == de_ex_rs1)) begin        //EX
            fwd_a  = 2'b01; 
        end 
        else if (mem_wb_rw && (mem_wb_rd != 0) && (mem_wb_rd == de_ex_rs1)) begin   //MEM
            fwd_a  = 2'b10; 
        end

        // ==========================================
        //  FORWARDING LOGIC (ALU Input B)
        // ==========================================
        if (ex_mem_rw && (ex_mem_rd != 0) && (ex_mem_rd == de_ex_rs2)) begin        //EX
            fwd_b  = 2'b01; 
        end 
        else if (mem_wb_rw && (mem_wb_rd != 0) && (mem_wb_rd == de_ex_rs2)) begin   //MEM
            fwd_b  = 2'b10; 
        end

        // ==========================================
        //  LOAD-USE HAZARD LOGIC (Comparing DE_EX to IF_ID)
        // ==========================================
        if (de_ex_mr && (de_ex_rd != 0) && ((if_id_rs1 == de_ex_rd) || (if_id_rs2 == de_ex_rd))) begin
            stall = 1'b1;
        end

        // ==========================================
        //  BRANCH / JUMP FLUSH LOGIC
        // ==========================================
        
        //EX_DCDR handles all the branch calulating and validifying
        if (pc_sel != 0) begin  
            flush = 1'b1;
        end
    end
       
endmodule
