`timescale 1ns / 1ps

module CU_DCDR(
    input  logic       ir_30,
    input  logic [6:0] ir_opcode,
    input  logic [2:0] ir_funct,

    input  logic       br_eq,
    input  logic       br_lt,
    input  logic       br_ltu,

    output logic [3:0] alu_fun,
    output logic       alu_srca,
    output logic [1:0] alu_srcb,
    output logic [2:0] pc_source,
    output logic [1:0] rf_wr_sel,
    output logic       reg_write,
    output logic       mem_we2,
    output logic       mem_rden2
);

    always_comb begin
        alu_fun   = 4'b0000;
        alu_srca  = 1'b0;
        alu_srcb  = 2'b00;
        pc_source = 3'b000;
        rf_wr_sel = 2'b00;
        reg_write = 1'b0;
        mem_we2   = 1'b0;
        mem_rden2 = 1'b0;

        case (ir_opcode)

            7'b0110111: begin // LUI
                alu_fun   = 4'b1001;
                alu_srca  = 1'b1;
                alu_srcb  = 2'b00;
                rf_wr_sel = 2'b11;
                reg_write = 1'b1;
            end

            7'b0010111: begin // AUIPC
                alu_fun   = 4'b0000;
                alu_srca  = 1'b1;
                alu_srcb  = 2'b11;
                rf_wr_sel = 2'b11;
                reg_write = 1'b1;
            end

            7'b1101111: begin // JAL
                pc_source = 3'b011;
                rf_wr_sel = 2'b00;
                reg_write = 1'b1;
            end

            7'b1100111: begin // JALR
                pc_source = 3'b001;
                rf_wr_sel = 2'b00;
                reg_write = 1'b1;
            end

            7'b0000011: begin // LOAD
                alu_fun   = 4'b0000;
                alu_srca  = 1'b0;
                alu_srcb  = 2'b01;
                rf_wr_sel = 2'b10;
                reg_write = 1'b1;
                mem_rden2 = 1'b1;
            end

            7'b0100011: begin // STORE
                alu_fun   = 4'b0000;
                alu_srca  = 1'b0;
                alu_srcb  = 2'b10;
                mem_we2   = 1'b1;
            end

            7'b0010011: begin // OP-IMM
                alu_srca  = 1'b0;
                alu_srcb  = 2'b01;
                rf_wr_sel = 2'b11;
                reg_write = 1'b1;

                case (ir_funct)
                    3'b000: alu_fun = 4'b0000; // ADDI
                    3'b001: alu_fun = 4'b0001; // SLLI
                    3'b010: alu_fun = 4'b0010; // SLTI
                    3'b011: alu_fun = 4'b0011; // SLTIU
                    3'b100: alu_fun = 4'b0100; // XORI
                    3'b101: begin
                        if (ir_30)
                            alu_fun = 4'b1101; // SRAI
                        else
                            alu_fun = 4'b0101; // SRLI
                    end
                    3'b110: alu_fun = 4'b0110; // ORI
                    3'b111: alu_fun = 4'b0111; // ANDI
                    default: alu_fun = 4'b0000;
                endcase
            end

            7'b0110011: begin // OP
                alu_srca  = 1'b0;
                alu_srcb  = 2'b00;
                rf_wr_sel = 2'b11;
                reg_write = 1'b1;
                alu_fun   = {ir_30, ir_funct};
            end

            7'b1100011: begin // BRANCH
                case (ir_funct)
                    3'b000: pc_source = br_eq  ? 3'b010 : 3'b000;
                    3'b001: pc_source = !br_eq ? 3'b010 : 3'b000;
                    3'b100: pc_source = br_lt  ? 3'b010 : 3'b000;
                    3'b101: pc_source = !br_lt ? 3'b010 : 3'b000;
                    3'b110: pc_source = br_ltu ? 3'b010 : 3'b000;
                    3'b111: pc_source = !br_ltu ? 3'b010 : 3'b000;
                    default: pc_source = 3'b000;
                endcase
            end

            default: begin
            end

        endcase
    end

endmodule