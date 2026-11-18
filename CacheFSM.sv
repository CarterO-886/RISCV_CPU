`timescale 1ns / 1ps

module CacheFSM (
    input  logic hit,
    input  logic miss,
    input  logic clk,
    input  logic rst,

    output logic l2_read,
    output logic update,
    output logic pc_stall
);

    typedef enum logic [1:0] {
        st_read_cache,
        st_read_mem,
        st_update_cache
    } state_type;

    state_type ps, ns;

    always_ff @(posedge clk) begin
        if (rst)
            ps <= st_read_cache;
        else
            ps <= ns;
    end

    always_comb begin
        l2_read  = 1'b0;
        update   = 1'b0;
        pc_stall = 1'b0;
        ns       = ps;

        case (ps)
            st_read_cache: begin
                if (miss) begin
                    pc_stall = 1'b1;
                    ns       = st_read_mem;
                end else begin
                    ns = st_read_cache;
                end
            end

            st_read_mem: begin
                pc_stall = 1'b1;
                l2_read  = 1'b1;
                ns       = st_update_cache;
            end

            st_update_cache: begin
                pc_stall = 1'b1;
                update   = 1'b1;
                ns       = st_read_cache;
            end

            default: begin
                ns = st_read_cache;
            end
        endcase
    end

endmodule
