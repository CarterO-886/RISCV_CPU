`timescale 1ns / 1ps
//////////////////////////////////////////////////////////
// Engineer: Carter Oates
// Create Date: 5/24/26
// Design Name: Unified RISCV L2 Cache Memory
// Description: This design is a unified L2 memory that feeds in to L1 instruction and memory caches.
// ///////////////////////////////////////////////////////              



module L2_Memory #(
    parameter addr_width = 32,
    parameter data_width = 32,
    parameter depth      = 16384 //Number of uniquely addressable spaces
)(
    input  logic                  clk,
    input  logic                  rst,

    input  logic                  i_read_en,
    input  logic [addr_width-1:0] i_addr,
    output logic [data_width-1:0] i_out1,
    output logic [data_width-1:0] i_out2,
    output logic [data_width-1:0] i_out3,
    output logic [data_width-1:0] i_out4,
    output logic [data_width-1:0] i_out5,
    output logic [data_width-1:0] i_out6,
    output logic [data_width-1:0] i_out7,
    output logic [data_width-1:0] i_out8,

    input  logic                  d_read_en,
    input  logic                  d_write_en,
    input  logic [addr_width-1:0] d_read_addr,
    input  logic [addr_width-1:0] d_write_addr,
    input  logic [data_width-1:0] d_write_w0,
    input  logic [data_width-1:0] d_write_w1,
    input  logic [data_width-1:0] d_write_w2,
    input  logic [data_width-1:0] d_write_w3,
    output logic [data_width-1:0] d_out1,
    output logic [data_width-1:0] d_out2,
    output logic [data_width-1:0] d_out3,
    output logic [data_width-1:0] d_out4
);

    localparam line_words = 8;
    localparam line_width = data_width * line_words;
    localparam line_depth = depth / line_words;

    (* ram_style = "block" *) logic [line_width-1:0] line_array [0:line_depth-1];
    logic [line_width-1:0] i_line_q;
    logic [line_width-1:0] d_line_q;
    logic                  d_read_upper_half_q;

    logic [10:0] i_line_index;
    logic [10:0] d_read_line_index;
    logic [10:0] d_write_line_index;

    assign i_line_index       = i_addr[15:5];
    assign d_read_line_index  = d_read_addr[15:5];
    assign d_write_line_index = d_write_addr[15:5];

    assign i_out1 = i_line_q[31:0];
    assign i_out2 = i_line_q[63:32];
    assign i_out3 = i_line_q[95:64];
    assign i_out4 = i_line_q[127:96];
    assign i_out5 = i_line_q[159:128];
    assign i_out6 = i_line_q[191:160];
    assign i_out7 = i_line_q[223:192];
    assign i_out8 = i_line_q[255:224];

    assign d_out1 = d_read_upper_half_q ? d_line_q[159:128] : d_line_q[31:0];
    assign d_out2 = d_read_upper_half_q ? d_line_q[191:160] : d_line_q[63:32];
    assign d_out3 = d_read_upper_half_q ? d_line_q[223:192] : d_line_q[95:64];
    assign d_out4 = d_read_upper_half_q ? d_line_q[255:224] : d_line_q[127:96];

    initial begin
        $readmemh("performance_l2_lines.mem", line_array, 0, line_depth-1);
    end

    always_ff @(posedge clk) begin
        if (rst)
            i_line_q <= {line_words{32'h00000013}};
        else if (i_read_en)
            i_line_q <= line_array[i_line_index];
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            d_line_q <= '0;
            d_read_upper_half_q <= 1'b0;
        end else begin
            if (d_write_en) begin
                if (d_write_addr[4])
                    line_array[d_write_line_index][255:128] <= {d_write_w3, d_write_w2, d_write_w1, d_write_w0};
                else
                    line_array[d_write_line_index][127:0] <= {d_write_w3, d_write_w2, d_write_w1, d_write_w0};
            end

            if (d_read_en) begin
                d_line_q <= line_array[d_read_line_index];
                d_read_upper_half_q <= d_read_addr[4];
            end
        end
    end

endmodule
