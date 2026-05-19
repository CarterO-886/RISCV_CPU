`timescale 1ns / 1ps
module EX_DCDR(
    input  logic    [6:0]de_ex_opcode,    
    input  logic       BR_LT,
    input  logic       BR_LTU,
    input  logic       BR_EQ,
    input  logic [2:0] de_ex_f3,
    output logic [2:0] PC_SOURCE
);

    always_comb begin
        PC_SOURCE = 3'b000;
        
        case (de_ex_opcode) 
            7'b1101111: begin // JAL
                PC_SOURCE = 3'b011;
            end
            7'b1100111: begin
                PC_SOURCE = 3'b001;
            end
            7'b1100011: begin // BRANCH
                case (de_ex_f3)
                    3'b000: PC_SOURCE = BR_EQ  ? 3'b010 : 3'b000;
                    3'b001: PC_SOURCE = !BR_EQ ? 3'b010 : 3'b000;
                    3'b100: PC_SOURCE = BR_LT  ? 3'b010 : 3'b000;
                    3'b101: PC_SOURCE = !BR_LT ? 3'b010 : 3'b000;
                    3'b110: PC_SOURCE = BR_LTU ? 3'b010 : 3'b000;
                    3'b111: PC_SOURCE = !BR_LTU ? 3'b010 : 3'b000;
                    default: PC_SOURCE = 3'b000;
                endcase
            end
            default: PC_SOURCE = 3'b000;
        endcase 
    end
    
endmodule