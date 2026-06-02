`timescale 1ns / 1ps

module Data_FSM (
    input  logic CLK,
    input  logic RST,

    input  logic data_read,
    input  logic data_write,
    input  logic hit,
    input  logic miss,
    input  logic evict_valid,

    output logic FSM_write,
    output logic l2_read,
    output logic l2_write,
    output logic stall
);

    typedef enum logic [2:0] {
        ST_CHECK_L1,
        ST_WRITE_L2,
        ST_READ_L2,
        ST_FILL_L1,
        ST_RETRY_L1
    } state_type;

    state_type PS, NS;

    logic request;

    assign request = data_read || data_write;

    always_ff @(posedge CLK) begin
        if (RST)
            PS <= ST_CHECK_L1;
        else
            PS <= NS;
    end

    always_comb begin
        FSM_write = 1'b0;
        l2_read   = 1'b0;
        l2_write  = 1'b0;
        stall     = 1'b0;
        NS        = PS;

        case (PS)
            ST_CHECK_L1: begin
                if (request && miss) begin
                    stall = 1'b1;
                    NS    = evict_valid ? ST_WRITE_L2 : ST_READ_L2;
                end
            end

            ST_WRITE_L2: begin
                stall    = 1'b1;
                l2_write = 1'b1;
                NS       = ST_READ_L2;
            end

            ST_READ_L2: begin
                stall   = 1'b1;
                l2_read = 1'b1;
                NS      = ST_FILL_L1;
            end

            ST_FILL_L1: begin
                stall     = 1'b1;
                FSM_write = 1'b1;
                NS        = ST_RETRY_L1;
            end

            ST_RETRY_L1: begin
                if (request && hit) begin
                    stall = 1'b0;
                    NS    = ST_CHECK_L1;
                end else if (request && miss) begin
                    stall = 1'b1;
                    NS    = evict_valid ? ST_WRITE_L2 : ST_READ_L2;
                end else begin
                    NS = ST_CHECK_L1;
                end
            end

            default: begin
                NS = ST_CHECK_L1;
            end
        endcase
    end

endmodule
