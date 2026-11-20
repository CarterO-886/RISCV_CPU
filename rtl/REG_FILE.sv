`timescale 1ns / 1ps


module REG_FILE(
    input  logic        clk,
    input  logic        en,
    input  logic [4:0]  adr1,
    input  logic [4:0]  adr2,
    input  logic [4:0]  wa,
    input  logic [31:0] wd,
    output logic [31:0] rs1,
    output logic [31:0] rs2
);
    
    logic [31:0] ram[0:31];
    
    initial begin
        static int i = 0;
        for (i = 0; i < 32; i++) begin
            ram[i] = 0;
        end
    end

    //write-first async reads
    always_comb begin
        if (en && wa == adr1 && wa != 5'd0)
            rs1 = wd;
        else
            rs1 = ram[adr1];
    end

    always_comb begin
        if (en && wa == adr2 && wa != 5'd0)
            rs2 = wd;
        else
            rs2 = ram[adr2];
    end
   
    always_ff @(posedge clk) begin
        if (en == 1'b1 && wa != 5'd0) begin
            ram[wa] <= wd;
        end
    end 
    
endmodule
