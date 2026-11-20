`timescale 1ns / 1ps

module L1_D_Cache (
    input  logic        clk,
    input  logic        rst,

    //Inputs from EX/MEM register
    input  logic [31:0] alu_result,
    input  logic [31:0] rs2_data,
    input  logic        data_read,
    input  logic        data_write,
    input  logic [1:0]  mem_size,
    input  logic        mem_sign,

    //Inputs from Data FSM
    input  logic        fsm_write,
    input  logic [31:0] w0,
    input  logic [31:0] w1,
    input  logic [31:0] w2,
    input  logic [31:0] w3,

    //Outputs to Data FSM 
    output logic        hit,
    output logic        miss,
    output logic [31:0] data,

    //Outputs to L2 Memory
    output logic        evict_valid,
    output logic [31:0] evict_addr,
    output logic [31:0] evict_w0,
    output logic [31:0] evict_w1,
    output logic [31:0] evict_w2,
    output logic [31:0] evict_w3
);
    // Set Associate Cache Parameters
    localparam sets            = 4;
    localparam ways            = 4;
    localparam words_per_block = 4;
    localparam tag_bits        = 26;

    //Defining Set Associative Cache Data Structures
    logic [31:0]         cache_data [sets-1:0][ways-1:0][words_per_block-1:0];
    logic [tag_bits-1:0] cache_tags [sets-1:0][ways-1:0];
    logic                valid_bits [sets-1:0][ways-1:0];
    logic                dirty_bits [sets-1:0][ways-1:0];
    logic [1:0]          lru_age [sets-1:0][ways-1:0]; // 0 = most recent, 3 = least recent

    //Intermediate Signals For Checking Hit/Miss, determining memory accesses
    logic [1:0]          addr_byte_off;
    logic [1:0]          addr_word_off;
    logic [1:0]          addr_index;
    logic [tag_bits-1:0] addr_tag;
    logic [1:0]          victim_way;
    logic                request;
    logic [ways-1:0]     way_hit;
    logic [1:0]          hit_way;
    logic [31:0]         hit_word;

    //Decoding incoming address into tag, index, and offset
    assign addr_byte_off = alu_result[1:0];
    assign addr_word_off = alu_result[3:2];
    assign addr_index    = alu_result[5:4];
    assign addr_tag      = alu_result[31:6];
    assign request       = data_read || data_write; //Determing if a request is being made

    //Generate ways
    genvar g;
    generate
        for (g = 0; g < ways; g++) begin : way_hit_gen
            assign way_hit[g] = valid_bits[addr_index][g] && (cache_tags[addr_index][g] == addr_tag);
        end
    endgenerate

    //Determine which way was hit
    always_comb begin
        case (1'b1)
            way_hit[3]: hit_way = 2'd3;
            way_hit[2]: hit_way = 2'd2;
            way_hit[1]: hit_way = 2'd1;
            default:    hit_way = 2'd0;
        endcase
    end

    //Determine which way to evict based on valid bits and LRU age
    always_comb begin
        if (!valid_bits[addr_index][0])
            victim_way = 2'd0;
        else if (!valid_bits[addr_index][1])
            victim_way = 2'd1;
        else if (!valid_bits[addr_index][2])
            victim_way = 2'd2;
        else if (!valid_bits[addr_index][3])
            victim_way = 2'd3;
        else if (lru_age[addr_index][0] == 2'd3)
            victim_way = 2'd0;
        else if (lru_age[addr_index][1] == 2'd3)
            victim_way = 2'd1;
        else if (lru_age[addr_index][2] == 2'd3)
            victim_way = 2'd2;
        else
            victim_way = 2'd3;
    end


    assign hit      = request && (|way_hit);
    assign miss     = request && ~(|way_hit);
    assign hit_word = cache_data[addr_index][hit_way][addr_word_off];

    /*
        Search way and determine exact location of data

    */
    always_comb begin
        data = 32'b0;

        if (data_read && hit) begin
            case ({mem_sign, mem_size, addr_byte_off})
                5'b00011: data = {{24{hit_word[31]}}, hit_word[31:24]};
                5'b00010: data = {{24{hit_word[23]}}, hit_word[23:16]};
                5'b00001: data = {{24{hit_word[15]}}, hit_word[15:8]};
                5'b00000: data = {{24{hit_word[7]}},  hit_word[7:0]};

                5'b00110: data = {{16{hit_word[31]}}, hit_word[31:16]};
                5'b00101: data = {{16{hit_word[23]}}, hit_word[23:8]};
                5'b00100: data = {{16{hit_word[15]}}, hit_word[15:0]};

                5'b01000: data = hit_word;

                5'b10011: data = {24'b0, hit_word[31:24]};
                5'b10010: data = {24'b0, hit_word[23:16]};
                5'b10001: data = {24'b0, hit_word[15:8]};
                5'b10000: data = {24'b0, hit_word[7:0]};

                5'b10110: data = {16'b0, hit_word[31:16]};
                5'b10101: data = {16'b0, hit_word[23:8]};
                5'b10100: data = {16'b0, hit_word[15:0]};

                default:  data = 32'b0;
            endcase
        end
    end

    /*

        Predetermine which blocks of data to evict from individual ways
        Also determine the current block that is next evicted

    */

    always_comb begin
        evict_valid = miss && valid_bits[addr_index][victim_way] && dirty_bits[addr_index][victim_way];
        evict_addr  = {cache_tags[addr_index][victim_way], addr_index, 4'b0000};
        evict_w0    = cache_data[addr_index][victim_way][0];
        evict_w1    = cache_data[addr_index][victim_way][1];
        evict_w2    = cache_data[addr_index][victim_way][2];
        evict_w3    = cache_data[addr_index][victim_way][3];
    end

    //Initial setup of cache upon startup
    initial begin
        for (int i = 0; i < sets; i++) begin
            for (int j = 0; j < ways; j++) begin
                valid_bits[i][j] = 1'b0;
                dirty_bits[i][j] = 1'b0;
                cache_tags[i][j] = '0;
                lru_age[i][j]    = j[1:0];
                for (int k = 0; k < words_per_block; k++)
                    cache_data[i][j][k] = 32'b0;
            end
        end
    end

    //Write logic
    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < sets; i++) begin
                for (int j = 0; j < ways; j++) begin
                    valid_bits[i][j] <= 1'b0;
                    dirty_bits[i][j] <= 1'b0;
                    lru_age[i][j]    <= j[1:0];
                end
            end
        end else begin
            if (fsm_write) begin
                cache_data[addr_index][victim_way][0] <= w0;
                cache_data[addr_index][victim_way][1] <= w1;
                cache_data[addr_index][victim_way][2] <= w2;
                cache_data[addr_index][victim_way][3] <= w3;
                cache_tags[addr_index][victim_way]    <= addr_tag;
                valid_bits[addr_index][victim_way]    <= 1'b1;
                dirty_bits[addr_index][victim_way]    <= 1'b0;

                for (int j = 0; j < ways; j++) begin
                    if (j[1:0] == victim_way)
                        lru_age[addr_index][j] <= 2'd0;
                    else if (valid_bits[addr_index][j] && (lru_age[addr_index][j] != 2'd3))
                        lru_age[addr_index][j] <= lru_age[addr_index][j] + 1'b1;
                end
            end

            if (hit) begin
                for (int j = 0; j < ways; j++) begin
                    if (j[1:0] == hit_way)
                        lru_age[addr_index][j] <= 2'd0;
                    else if (valid_bits[addr_index][j] &&
                             (lru_age[addr_index][j] < lru_age[addr_index][hit_way]))
                        lru_age[addr_index][j] <= lru_age[addr_index][j] + 1'b1;
                end

                if (data_write) begin
                    case ({mem_size, addr_byte_off})
                        4'b0000: cache_data[addr_index][hit_way][addr_word_off][7:0]   <= rs2_data[7:0];
                        4'b0001: cache_data[addr_index][hit_way][addr_word_off][15:8]  <= rs2_data[7:0];
                        4'b0010: cache_data[addr_index][hit_way][addr_word_off][23:16] <= rs2_data[7:0];
                        4'b0011: cache_data[addr_index][hit_way][addr_word_off][31:24] <= rs2_data[7:0];

                        4'b0100: cache_data[addr_index][hit_way][addr_word_off][15:0]  <= rs2_data[15:0];
                        4'b0101: cache_data[addr_index][hit_way][addr_word_off][23:8]  <= rs2_data[15:0];
                        4'b0110: cache_data[addr_index][hit_way][addr_word_off][31:16] <= rs2_data[15:0];

                        4'b1000: cache_data[addr_index][hit_way][addr_word_off]        <= rs2_data;
                        default: begin
                        end
                    endcase

                    dirty_bits[addr_index][hit_way] <= 1'b1;
                end
            end
        end
    end

endmodule
