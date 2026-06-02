`timescale 1ns / 1ps

module CacheFSM (
    input  logic hit,
    input  logic miss,
    input  logic CLK,
    input  logic RST,

    output logic l2_read,
    output logic update,
    output logic pc_stall
);

    typedef enum logic [1:0] {
        ST_READ_CACHE,
        ST_READ_MEM,
        ST_UPDATE_CACHE
    } state_type;

    state_type PS, NS;

    always_ff @(posedge CLK) begin
        if (RST)
            PS <= ST_READ_CACHE;
        else
            PS <= NS;
    end

    always_comb begin
        l2_read  = 1'b0;
        update   = 1'b0;
        pc_stall = 1'b0;
        NS       = PS;

        case (PS)
            ST_READ_CACHE: begin
                if (miss) begin
                    pc_stall = 1'b1;
                    NS       = ST_READ_MEM;
                end else begin
                    NS = ST_READ_CACHE;
                end
            end

            ST_READ_MEM: begin
                pc_stall = 1'b1;
                l2_read  = 1'b1;
                NS       = ST_UPDATE_CACHE;
            end

            ST_UPDATE_CACHE: begin
                pc_stall = 1'b1;
                update   = 1'b1;
                NS       = ST_READ_CACHE;
            end

            default: begin
                NS = ST_READ_CACHE;
            end
        endcase
    end

endmodule
