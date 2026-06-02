`timescale 1ns / 1ps

module Data_Memory #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter DEPTH      = 16384
)(
    input  logic                  CLK,
    input  logic                  RST,
    input  logic                  read_en,
    input  logic                  write_en,
    input  logic [ADDR_WIDTH-1:0] read_addr,
    input  logic [ADDR_WIDTH-1:0] write_addr,
    input  logic [DATA_WIDTH-1:0] write_w0,
    input  logic [DATA_WIDTH-1:0] write_w1,
    input  logic [DATA_WIDTH-1:0] write_w2,
    input  logic [DATA_WIDTH-1:0] write_w3,

    output logic [DATA_WIDTH-1:0] out1,
    output logic [DATA_WIDTH-1:0] out2,
    output logic [DATA_WIDTH-1:0] out3,
    output logic [DATA_WIDTH-1:0] out4
);

    logic [DATA_WIDTH-1:0] storage_array [0:DEPTH-1];
    logic [13:0] read_base;
    logic [13:0] write_base;

    assign read_base  = {read_addr[15:4], 2'b00};
    assign write_base = {write_addr[15:4], 2'b00};

    initial begin
        $readmemh("performance.mem", storage_array, 0, DEPTH-1);
    end

    always_ff @(posedge CLK) begin
        if (RST) begin
            out1 <= 32'b0;
            out2 <= 32'b0;
            out3 <= 32'b0;
            out4 <= 32'b0;
        end else begin
            if (write_en) begin
                storage_array[write_base + 14'd0] <= write_w0;
                storage_array[write_base + 14'd1] <= write_w1;
                storage_array[write_base + 14'd2] <= write_w2;
                storage_array[write_base + 14'd3] <= write_w3;
            end

            if (read_en) begin
                out1 <= storage_array[read_base + 14'd0];
                out2 <= storage_array[read_base + 14'd1];
                out3 <= storage_array[read_base + 14'd2];
                out4 <= storage_array[read_base + 14'd3];
            end
        end
    end

endmodule
