`timescale 1ns / 1ps

module L2_Memory #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter DEPTH      = 16384
)(
    input  logic                  CLK,
    input  logic                  RST,

    input  logic                  i_read_en,
    input  logic [ADDR_WIDTH-1:0] i_addr,
    output logic [DATA_WIDTH-1:0] i_out1,
    output logic [DATA_WIDTH-1:0] i_out2,
    output logic [DATA_WIDTH-1:0] i_out3,
    output logic [DATA_WIDTH-1:0] i_out4,
    output logic [DATA_WIDTH-1:0] i_out5,
    output logic [DATA_WIDTH-1:0] i_out6,
    output logic [DATA_WIDTH-1:0] i_out7,
    output logic [DATA_WIDTH-1:0] i_out8,

    input  logic                  d_read_en,
    input  logic                  d_write_en,
    input  logic [ADDR_WIDTH-1:0] d_read_addr,
    input  logic [ADDR_WIDTH-1:0] d_write_addr,
    input  logic [DATA_WIDTH-1:0] d_write_w0,
    input  logic [DATA_WIDTH-1:0] d_write_w1,
    input  logic [DATA_WIDTH-1:0] d_write_w2,
    input  logic [DATA_WIDTH-1:0] d_write_w3,
    output logic [DATA_WIDTH-1:0] d_out1,
    output logic [DATA_WIDTH-1:0] d_out2,
    output logic [DATA_WIDTH-1:0] d_out3,
    output logic [DATA_WIDTH-1:0] d_out4
);

    localparam LINE_WORDS = 8;
    localparam LINE_WIDTH = DATA_WIDTH * LINE_WORDS;
    localparam LINE_DEPTH = DEPTH / LINE_WORDS;

    (* ram_style = "block" *) logic [LINE_WIDTH-1:0] line_array [0:LINE_DEPTH-1];
    logic [LINE_WIDTH-1:0] i_line_q;
    logic [LINE_WIDTH-1:0] d_line_q;
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
        $readmemh("performance_l2_lines.mem", line_array, 0, LINE_DEPTH-1);
    end

    always_ff @(posedge CLK) begin
        if (RST)
            i_line_q <= {LINE_WORDS{32'h00000013}};
        else if (i_read_en)
            i_line_q <= line_array[i_line_index];
    end

    always_ff @(posedge CLK) begin
        if (RST) begin
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
