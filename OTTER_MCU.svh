`timescale 1ns / 1ps

typedef struct packed {
    
    logic [6:0] opcode;    
    
    
    //ALU
    logic [3:0]  alu_fun;
    logic        alu_src_a;
    logic [1:0]  alu_src_b; 
    logic [31:0] alu_result;

    //MEMORY
    logic        memwrite;
    logic        memread2;

    //REGISTER FILE
    logic        regwrite;
    logic [1:0]  rf_wr_sel;

    
    //PC
    logic [31:0] pc;
    logic [31:0] pc_plus;

    
    //Register addresses
    logic [4:0]  rs1_addr;
    logic [4:0]  rs2_addr;
    logic [4:0]  rd_addr;
    
    //Register Values
    logic [31:0] rs1;
    logic [31:0] rs2;
    
    //Immediates
    logic [31:0] i_immed;
    logic [31:0] b_immed;
    logic [31:0] j_immed;
    logic [31:0] u_immed;
    logic [31:0] s_immed;
    
    
    logic [2:0] func3;
    logic [31:0] mem_data;
} pipe_reg_t;

module OTTER_MCU(
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] iobus_in,
    output logic [31:0] iobus_out,
    output logic [31:0] iobus_addr,
    output logic        iobus_wr
);

    // PIPELINE REGS
    pipe_reg_t de_ex_reg;
    pipe_reg_t ex_mem_reg;
    pipe_reg_t mem_wb_reg;

    // Branch and PC Control Signals
    logic pc_rst, pc_write;
    logic [2:0] pc_source;
    logic [31:0] pc_out, pc_out_inc, jalr, branch, jal;

    assign pc_rst   = rst;

    logic [31:0] memory_data;
    logic [31:0] ir;

    logic [31:0] if_de_ir;
    logic [31:0] if_de_pc;
    logic [31:0] if_de_pc_plus;

    logic [31:0] wd, rs1, rs2;
    logic [31:0] utype, itype, stype, btype, jtype;
    logic [31:0] alu_a, alu_b;
    logic        alu_src_a;
    logic [1:0]  alu_src_b;
    logic [3:0]  alu_fun;
    logic [31:0] alu_result;
    logic        br_eq, br_lt, br_ltu;
    logic        reg_write, mem_write, mem_read2;
    logic [1:0]  rf_wr_sel;
    
    logic lw_stall;
    logic cache_stall;

    logic flush_if_id;
    logic flush_de_ex;
    
    logic [31:0] rs1_data;
    logic [31:0] rs2_data;
    
    logic [1:0] fwd_a;
    logic [1:0] fwd_b;

    logic        i_cache_hit;
    logic        i_cache_miss;
    logic        i_cache_update;
    logic        i_l2_read;
    logic        i_stall;
    logic [31:0] i_w0, i_w1, i_w2, i_w3;
    logic [31:0] i_w4, i_w5, i_w6, i_w7;

    logic        d_cacheable;
    logic        d_data_read;
    logic        d_data_write;
    logic        d_cache_hit;
    logic        d_cache_miss;
    logic        d_cache_fill;
    logic        d_l2_read;
    logic        d_l2_write;
    logic        d_stall;
    logic        d_evict_valid;
    logic [31:0] d_cache_data;
    logic [31:0] d_w0, d_w1, d_w2, d_w3;
    logic [31:0] d_evict_addr;
    logic [31:0] d_evict_w0, d_evict_w1, d_evict_w2, d_evict_w3;
    logic [31:0] io_load_data;

    assign cache_stall = i_stall || d_stall;

//=================================================================
//==== Hazard Unit ================================================
//=================================================================
Hazard_Unit hu ( 

    //INPUTS
    .pc_sel(pc_source),
    .ex_mem_rw(ex_mem_reg.regwrite),
    .mem_wb_rw(mem_wb_reg.regwrite),
    .de_ex_mr(de_ex_reg.memread2),
    // Tell the hazard unit about loads still in MEM for synchronous memory timing.
    .ex_mem_mr(ex_mem_reg.memread2),
    .if_id_rs1(if_de_ir[19:15]),
    .de_ex_rs1(de_ex_reg.rs1_addr),
    .if_id_rs2(if_de_ir[24:20]),
    .de_ex_rs2(de_ex_reg.rs2_addr),
    .de_ex_rd(de_ex_reg.rd_addr),
    .ex_mem_rd(ex_mem_reg.rd_addr),
    .mem_wb_rd(mem_wb_reg.rd_addr),

    //OUTPUTS
    .fwd_a(fwd_a),
    .fwd_b(fwd_b),
    .flush_if_id(flush_if_id),
    .flush_de_ex(flush_de_ex),
    .lw_stall(lw_stall)
);

//==================================================================
//==== Instruction Fetch ===========================================
//==================================================================

    assign pc_write = !(lw_stall || cache_stall);

    PC otter_pc(
        .clk(clk), 
        .rst(pc_rst), 
        .pc_write(pc_write), 
        .pc_source(pc_source),
        .jalr(jalr), 
        .jal(jal), 
        .branch(branch), 
        .mtvec(32'b0), 
        .mepc(32'b0),
        .pc_out(pc_out), 
        .pc_out_inc(pc_out_inc));

    CacheFSM i_cache_fsm(
        .hit(i_cache_hit),
        .miss(i_cache_miss),
        .clk(clk),
        .rst(rst),
        .l2_read(i_l2_read),
        .update(i_cache_update),
        .pc_stall(i_stall));

    L1_I_Cache i_cache(
        .PC(pc_out),
        .clk(clk),
        .rst(rst),
        .update(i_cache_update),
        .w0(i_w0),
        .w1(i_w1),
        .w2(i_w2),
        .w3(i_w3),
        .w4(i_w4),
        .w5(i_w5),
        .w6(i_w6),
        .w7(i_w7),
        .rd(ir),
        .hit(i_cache_hit),
        .miss(i_cache_miss));

    always_ff @(posedge clk) begin
        if (rst) begin
            if_de_pc      <= '0;
            if_de_pc_plus <= '0;
            if_de_ir      <= 32'h00000013; //NOP
        end else if (cache_stall) begin
            if_de_pc      <= if_de_pc;
            if_de_pc_plus <= if_de_pc_plus;
            if_de_ir      <= if_de_ir;
        end else if (flush_if_id) begin
            if_de_pc      <= '0;
            if_de_pc_plus <= '0;
            if_de_ir      <= 32'h00000013; //NOP
        end else if (!lw_stall) begin
            if_de_pc      <= pc_out;
            if_de_pc_plus <= pc_out_inc;
            if_de_ir      <= ir;
        end
        //If we are in a stall, then nothing happens
    end

//===================================================================
//==== Instruction Decode ===========================================
//===================================================================

    REG_FILE otter_reg_file(
        .clk(clk), 
        .en(mem_wb_reg.regwrite),
        .adr1(if_de_ir[19:15]), 
        .adr2(if_de_ir[24:20]),
        .wa(mem_wb_reg.rd_addr),
        .wd(wd), 
        .rs1(rs1), 
        .rs2(rs2));

    ImmediateGenerator otter_imgen(
        //INPUTS
        .ir(if_de_ir[31:7]),

        //OUTPUTS
        .u_type(utype), 
        .i_type(itype),
        .s_type(stype), 
        .b_type(btype), 
        .j_type(jtype));

    CU_DCDR otter_dcdr(
        //INPUTS
        .ir_30(if_de_ir[30]), 
        .ir_opcode(if_de_ir[6:0]),  
        .ir_funct(if_de_ir[14:12]),
        .br_eq(1'b0), 
        .br_lt(1'b0),
        .br_ltu(1'b0),

        //OUTPUTS
        .pc_source(),
        .alu_fun(alu_fun), 
        .alu_srca(alu_src_a),
        .alu_srcb(alu_src_b),
        .rf_wr_sel(rf_wr_sel), 
        .reg_write(reg_write),
        .mem_we2(mem_write), 
        .mem_rden2(mem_read2));

    always_ff @(posedge clk) begin
        if (rst) begin

            de_ex_reg <= '0;//inject a NOP by clearing the DE/EX pipeline register

        end else if (cache_stall) begin

            de_ex_reg <= de_ex_reg;

        end else if (flush_de_ex) begin

            de_ex_reg <= '0;//inject a NOP by clearing the DE/EX pipeline register

        end else begin
            
        //IR CONCATENATIONS
            de_ex_reg.opcode   <= if_de_ir[6:0];   
            de_ex_reg.func3    <= if_de_ir[14:12];
        //REGISTER ADDRESSES
            de_ex_reg.rs1_addr <= if_de_ir[19:15];
            de_ex_reg.rs2_addr <= if_de_ir[24:20];
            de_ex_reg.rd_addr  <= if_de_ir[11:7];
        //REGISTER VALUES
            de_ex_reg.rs1      <= rs1;
            de_ex_reg.rs2      <= rs2;
        //PC CONTROL SIGNALS
            de_ex_reg.pc       <= if_de_pc;
            de_ex_reg.pc_plus  <= if_de_pc_plus;
        //ALU CONTROL SIGNALS
            de_ex_reg.alu_fun  <= alu_fun;
            de_ex_reg.alu_src_a<= alu_src_a;
            de_ex_reg.alu_src_b<= alu_src_b;
        //MEMORY CONTROL SIGNALS
            de_ex_reg.memwrite <= mem_write;
            de_ex_reg.memread2 <= mem_read2;
        //REGISTER FILE CONTROL SIGNALS
            de_ex_reg.rf_wr_sel<= rf_wr_sel;
            de_ex_reg.regwrite <= reg_write;
        //IMMEDIATE VALUES
            de_ex_reg.u_immed  <= utype;
            de_ex_reg.s_immed  <= stype;
            de_ex_reg.i_immed  <= itype;
            de_ex_reg.b_immed  <= btype;
            de_ex_reg.j_immed  <= jtype;
        end
    end


//===================================================================
//==== Execute ======================================================
//====================================================================
    
    // Forwarding Muxes (before ALU src muxes because they feed into them)
    always_comb begin   
        case (fwd_a)
            2'b00: rs1_data = de_ex_reg.rs1;
            2'b01: rs1_data = ex_mem_reg.alu_result;
            2'b10: rs1_data = wd; //MEM_WB value
            default: rs1_data = de_ex_reg.rs1;
        endcase
    end
    
    always_comb begin   
        case (fwd_b)
            2'b00: rs2_data = de_ex_reg.rs2; 
            2'b01: rs2_data = ex_mem_reg.alu_result;
            2'b10: rs2_data = wd; //MEM_WB value
            default: rs2_data = de_ex_reg.rs2;
        endcase
    end

    //ALU SRC MUXES
    always_comb begin
        case (de_ex_reg.alu_src_a)
            1'b0:    alu_a = rs1_data;
            1'b1:    alu_a = de_ex_reg.u_immed;
            default: alu_a = rs1_data;
        endcase
    end

    always_comb begin
        case (de_ex_reg.alu_src_b)
            2'b00:   alu_b = rs2_data;
            2'b01:   alu_b = de_ex_reg.i_immed;
            2'b10:   alu_b = de_ex_reg.s_immed;
            2'b11:   alu_b = de_ex_reg.pc;
            default: alu_b = rs2_data;
        endcase
    end
    
    BCG otter_bcg(
        //INPUTS
        .rs1(rs1_data), 
        .rs2(rs2_data),
        //OUTPUTS
        .br_eq(br_eq), 
        .br_lt(br_lt), 
        .br_ltu(br_ltu));
        

    BAG otter_bag(
        //INPUTS
        .rs1(rs1_data), 
        .i_type(de_ex_reg.i_immed), 
        .j_type(de_ex_reg.j_immed),
        .b_type(de_ex_reg.b_immed), 
        .from_pc(de_ex_reg.pc),
        //OUTPUTS
        .jal(jal), 
        .jalr(jalr), 
        .branch(branch));
    
    EX_DCDR EX_DCDR(
        //INPUTS
        .de_ex_opcode(de_ex_reg.opcode),    
        .br_lt(br_lt),
        .br_ltu(br_ltu),
        .br_eq(br_eq),
        .de_ex_f3(de_ex_reg.func3),
        //OUTPUTS
        .pc_source(pc_source));
      
    ALU otter_alu(
        .src_a(alu_a), 
        .src_b(alu_b),
        .alu_fun(de_ex_reg.alu_fun), 
        .result(alu_result));

    always_ff @(posedge clk) begin
        if (rst) begin
            ex_mem_reg <= '0; //Inject a NOP by clearing the EX/MEM
        end else if (cache_stall) begin
            ex_mem_reg <= ex_mem_reg;
        end else begin

            //RD ADDRESS
            ex_mem_reg.rd_addr    <= de_ex_reg.rd_addr;
            //RS2 VALUE (for stores) — use forwarded value so stores see correct data
            ex_mem_reg.rs2        <= rs2_data;
            //ALU RESULT
            ex_mem_reg.alu_result <= alu_result;
            //MEMORY READ
            ex_mem_reg.memread2   <= de_ex_reg.memread2;
            //MEMORY WRITE
            ex_mem_reg.memwrite   <= de_ex_reg.memwrite;
            //REGISTER WRITE
            ex_mem_reg.regwrite   <= de_ex_reg.regwrite;
            //FUNC3
            ex_mem_reg.func3      <= de_ex_reg.func3;
            //PC PLUS
            ex_mem_reg.pc_plus    <= de_ex_reg.pc_plus;
            //RF Write Select
            ex_mem_reg.rf_wr_sel  <= de_ex_reg.rf_wr_sel;
        end
    end

//==== Memory ======================================================

    assign iobus_addr = ex_mem_reg.alu_result;
    assign iobus_out  = ex_mem_reg.rs2;
    assign d_cacheable = (ex_mem_reg.alu_result < 32'h00010000);
    assign d_data_read = ex_mem_reg.memread2 && d_cacheable;
    assign d_data_write = ex_mem_reg.memwrite && d_cacheable;
    assign iobus_wr = ex_mem_reg.memwrite && !d_cacheable && !cache_stall;

    always_comb begin
        case ({ex_mem_reg.func3[2], ex_mem_reg.func3[1:0], ex_mem_reg.alu_result[1:0]})
            5'b00011: io_load_data = {{24{iobus_in[31]}}, iobus_in[31:24]};
            5'b00010: io_load_data = {{24{iobus_in[23]}}, iobus_in[23:16]};
            5'b00001: io_load_data = {{24{iobus_in[15]}}, iobus_in[15:8]};
            5'b00000: io_load_data = {{24{iobus_in[7]}},  iobus_in[7:0]};

            5'b00110: io_load_data = {{16{iobus_in[31]}}, iobus_in[31:16]};
            5'b00101: io_load_data = {{16{iobus_in[23]}}, iobus_in[23:8]};
            5'b00100: io_load_data = {{16{iobus_in[15]}}, iobus_in[15:0]};

            5'b01000: io_load_data = iobus_in;

            5'b10011: io_load_data = {24'b0, iobus_in[31:24]};
            5'b10010: io_load_data = {24'b0, iobus_in[23:16]};
            5'b10001: io_load_data = {24'b0, iobus_in[15:8]};
            5'b10000: io_load_data = {24'b0, iobus_in[7:0]};

            5'b10110: io_load_data = {16'b0, iobus_in[31:16]};
            5'b10101: io_load_data = {16'b0, iobus_in[23:8]};
            5'b10100: io_load_data = {16'b0, iobus_in[15:0]};

            default:  io_load_data = 32'b0;
        endcase
    end

    assign memory_data = d_cacheable ? d_cache_data : io_load_data;

    Data_FSM d_cache_fsm(
        .clk(clk),
        .rst(rst),
        .data_read(d_data_read),
        .data_write(d_data_write),
        .hit(d_cache_hit),
        .miss(d_cache_miss),
        .evict_valid(d_evict_valid),
        .fsm_write(d_cache_fill),
        .l2_read(d_l2_read),
        .l2_write(d_l2_write),
        .stall(d_stall));

    L1_D_Cache d_cache(
        .clk(clk),
        .rst(rst),
        .alu_result(ex_mem_reg.alu_result),
        .rs2_data(ex_mem_reg.rs2),
        .data_read(d_data_read),
        .data_write(d_data_write),
        .mem_size(ex_mem_reg.func3[1:0]),
        .mem_sign(ex_mem_reg.func3[2]),
        .fsm_write(d_cache_fill),
        .w0(d_w0),
        .w1(d_w1),
        .w2(d_w2),
        .w3(d_w3),
        .hit(d_cache_hit),
        .miss(d_cache_miss),
        .data(d_cache_data),
        .evict_valid(d_evict_valid),
        .evict_addr(d_evict_addr),
        .evict_w0(d_evict_w0),
        .evict_w1(d_evict_w1),
        .evict_w2(d_evict_w2),
        .evict_w3(d_evict_w3));

    L2_Memory shared_l2_memory(
        .clk(clk),
        .rst(rst),

        .i_read_en(i_l2_read),
        .i_addr(pc_out),
        .i_out1(i_w0),
        .i_out2(i_w1),
        .i_out3(i_w2),
        .i_out4(i_w3),
        .i_out5(i_w4),
        .i_out6(i_w5),
        .i_out7(i_w6),
        .i_out8(i_w7),

        .d_read_en(d_l2_read),
        .d_write_en(d_l2_write),
        .d_read_addr(ex_mem_reg.alu_result),
        .d_write_addr(d_evict_addr),
        .d_write_w0(d_evict_w0),
        .d_write_w1(d_evict_w1),
        .d_write_w2(d_evict_w2),
        .d_write_w3(d_evict_w3),
        .d_out1(d_w0),
        .d_out2(d_w1),
        .d_out3(d_w2),
        .d_out4(d_w3));

    always_ff @(posedge clk) begin
        if (rst) begin
            mem_wb_reg <= '0; //Inject a NOP by clearing the MEM/WB
        end else if (cache_stall) begin
            mem_wb_reg <= mem_wb_reg;
        end else begin
        //RD ADDRESS
        mem_wb_reg.rd_addr    <= ex_mem_reg.rd_addr;
        //ALU RESULT
        mem_wb_reg.alu_result <= ex_mem_reg.alu_result;
        //MEMORY DATA
        mem_wb_reg.mem_data   <= memory_data;
        //REGISTER WRITE
        mem_wb_reg.regwrite   <= ex_mem_reg.regwrite;
        //RF Write Select
        mem_wb_reg.rf_wr_sel  <= ex_mem_reg.rf_wr_sel;
        //PC PLUS
        mem_wb_reg.pc_plus    <= ex_mem_reg.pc_plus;
        end
    end

//==== Write Back ==================================================

    FourMux otter_reg_mux(
        //INPUTS
        .sel(mem_wb_reg.rf_wr_sel),
        .zero(mem_wb_reg.pc_plus),
        .one(32'b0),
        .two(mem_wb_reg.mem_data),
        .three(mem_wb_reg.alu_result),
        //OUTPUT
        .out(wd));

endmodule
