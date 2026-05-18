`timescale 1ns / 1ps
module REG_FILE(
    input  logic        CLK,
    input  logic        EN,
    input  logic [4:0]  ADR1,
    input  logic [4:0]  ADR2,
    input  logic [4:0]  WA,
    input  logic [31:0] WD,
    output logic [31:0] RS1,
    output logic [31:0] RS2
);
    
    logic [31:0] ram[0:31];
    
    initial begin
        static int i = 0;
        for (i = 0; i < 32; i++) begin
            ram[i] = 0;
        end
    end

    // CHANGED: write-first async reads
    always_comb begin
        if (EN && WA == ADR1 && WA != 5'd0)
            RS1 = WD;
        else
            RS1 = ram[ADR1];
    end

    always_comb begin
        if (EN && WA == ADR2 && WA != 5'd0)
            RS2 = WD;
        else
            RS2 = ram[ADR2];
    end
   
    always_ff @(posedge CLK) begin
        if (EN == 1'b1 && WA != 5'd0) begin
            ram[WA] <= WD;
        end
    end 
    
endmodule
