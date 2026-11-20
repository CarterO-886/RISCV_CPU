`timescale 1ns/1ps

module ALU_tb;

    logic src_a;
    logic src_b;
    logic alu_fun;
    logic result;

    ALU alu(
    .src_a(src_a),
    .src_b(src_b),
    .alu_fun(alu_fun),
    .result(result)
    );


initial begin
    src_a = 0';
    src_b = 0';
    alu_fun = 0';
    result = 0';
end


#10

src_a = 32'h00000001
src_b = 32'h00000002



assert(result == )











endmodule