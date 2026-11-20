`timescale 1ns / 1ps
module EX_DCDR(
    input  logic    [6:0]de_ex_opcode,    
    input  logic       br_lt,
    input  logic       br_ltu,
    input  logic       br_eq,
    input  logic [2:0] de_ex_f3,
    output logic [2:0] pc_source
);

    always_comb begin
        pc_source = 3'b000;
        
        case (de_ex_opcode) 
            7'b1101111: begin // JAL
                pc_source = 3'b011;
            end
            7'b1100111: begin
                pc_source = 3'b001;
            end
            7'b1100011: begin // BRANCH
                case (de_ex_f3)
                    3'b000: pc_source = br_eq  ? 3'b010 : 3'b000;
                    3'b001: pc_source = !br_eq ? 3'b010 : 3'b000;
                    3'b100: pc_source = br_lt  ? 3'b010 : 3'b000;
                    3'b101: pc_source = !br_lt ? 3'b010 : 3'b000;
                    3'b110: pc_source = br_ltu ? 3'b010 : 3'b000;
                    3'b111: pc_source = !br_ltu ? 3'b010 : 3'b000;
                    default: pc_source = 3'b000;
                endcase
            end
            default: pc_source = 3'b000;
        endcase 
    end
    
endmodule