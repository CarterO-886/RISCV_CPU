`timescale 1ns / 1ps

module Two_Bit_BP(
    input logic clk,
    output logic [1:0]data,
    input logic rst

);

always_ff @(posedge clk) begin
    
    if (rst) begin

        data <= 2'b0;

    end

end



endmodule