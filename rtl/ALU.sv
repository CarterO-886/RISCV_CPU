`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Cal Poly San Luis Obispo
// Engineer: Carter Oates
//////////////////////////////////////////////////////////////////////////////////

module ALU(
    input logic [31:0] src_a,
    input logic [31:0] src_b,
    input logic [3:0] alu_fun,
    output logic [31:0] result
    );
    
    //Design the ALU as a MUX to improve processing speed
    //The MUX is dependent on the ALU_FUN
    //ALU_FUN determines which operation is carried out with the operands A and B
    always_comb begin
        case(alu_fun)
            4'b0000: begin result = src_a + src_b; end //add
            4'b1000: begin result = src_a - src_b; end //sub

            //logic
            4'b0110: begin result = src_a | src_b; end //or
            4'b0111: begin result = src_a & src_b; end //and
            4'b0100: begin result = src_a ^ src_b; end //xor

            //shifting
            4'b0101: begin result = src_a >> src_b[4:0]; end //srl
            4'b0001: begin result = src_a << src_b[4:0]; end //sll
            4'b1101: begin result = $signed(src_a) >>> src_b[4:0]; end //sra

            //setting
            4'b0010: begin result = $signed(src_a) < $signed(src_b); end //slt
            4'b0011: begin result = src_a < src_b; end //sltu
            
            //copy
            4'b1001: begin result = src_a; end //lui-copy
            default: begin result = 32'd0; end
        endcase
    end
    
endmodule
