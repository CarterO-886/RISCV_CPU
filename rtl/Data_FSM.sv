`timescale 1ns / 1ps

module Data_FSM (
    input  logic clk,
    input  logic rst,

    input  logic data_read,
    input  logic data_write,
    input  logic hit,
    input  logic miss,
    input  logic evict_valid,

    output logic fsm_write,
    output logic l2_read,
    output logic l2_write,
    output logic stall
);

    typedef enum logic [2:0] {
        st_check_l1,
        st_write_l2,
        st_read_l2,
        st_fill_l1,
        st_retry_l1
    } state_type;

    state_type ps, ns;

    logic request;

    assign request = data_read || data_write;

    always_ff @(posedge clk) begin
        if (rst)
            ps <= st_check_l1;
        else
            ps <= ns;
    end

    always_comb begin
        fsm_write = 1'b0;
        l2_read   = 1'b0;
        l2_write  = 1'b0;
        stall     = 1'b0;
        ns        = ps;

        case (ps)
            st_check_l1: begin
                if (request && miss) begin
                    stall = 1'b1;
                    ns    = evict_valid ? st_write_l2 : st_read_l2;
                end
            end

            st_write_l2: begin
                stall    = 1'b1;
                l2_write = 1'b1;
                ns       = st_read_l2;
            end

            st_read_l2: begin
                stall   = 1'b1;
                l2_read = 1'b1;
                ns      = st_fill_l1;
            end

            st_fill_l1: begin
                stall     = 1'b1;
                fsm_write = 1'b1;
                ns        = st_retry_l1;
            end

            st_retry_l1: begin
                if (request && hit) begin
                    stall = 1'b0;
                    ns    = st_check_l1;
                end else if (request && miss) begin
                    stall = 1'b1;
                    ns    = evict_valid ? st_write_l2 : st_read_l2;
                end else begin
                    ns = st_check_l1;
                end
            end

            default: begin
                ns = st_check_l1;
            end
        endcase
    end

endmodule
