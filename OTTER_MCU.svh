`timescale 1ns / 1ps

typedef struct packed {
    
    logic [6:0] opcode;    
    
    
    //ALU
    logic [3:0]  alu_fun;
    logic        alu_src_a;
    logic [1:0]  alu_src_b; 
    logic [31:0] alu_result;

    //MEMORY
    logic        memWrite;
    logic        memRead2;

    //REGISTER FILE
    logic        regWrite;
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
    input  logic        CLK,
    input  logic        RST,
    input  logic [31:0] IOBUS_IN,
    output logic [31:0] IOBUS_OUT,
    output logic [31:0] IOBUS_ADDR,
    output logic        IOBUS_WR
);

    // PIPELINE REGS
    pipe_reg_t DE_EX_reg;
    pipe_reg_t EX_MEM_reg;
    pipe_reg_t MEM_WB_reg;

    // Branch and PC Control Signals
    logic pc_rst, pc_write;
    logic [2:0] pc_source;
    logic [31:0] pc_out, pc_out_inc, jalr, branch, jal;

    assign pc_rst   = RST;

    logic [31:0] memory_data;
    logic [31:0] ir;

    logic [31:0] IF_DE_ir;
    logic [31:0] IF_DE_pc;
    logic [31:0] IF_DE_pc_plus;

    logic [31:0] wd, rs1, rs2;
    logic [31:0] Utype, Itype, Stype, Btype, Jtype;
    logic [31:0] alu_A, alu_B;
    logic        alu_src_a;
    logic [1:0]  alu_src_b;
    logic [3:0]  alu_fun;
    logic [31:0] alu_result;
    logic        br_eq, br_lt, br_ltu;
    logic        reg_Write, mem_write, mem_Read2;
    logic [1:0]  rf_wr_sel;
    
    logic lw_stall;
    logic cache_stall;

    logic flush_IF_ID;
    logic flush_DE_EX;
    
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
Hazard_Unit HU ( 

    //INPUTS
    .pc_sel(pc_source),
    .ex_mem_rw(EX_MEM_reg.regWrite),
    .mem_wb_rw(MEM_WB_reg.regWrite),
    .de_ex_mr(DE_EX_reg.memRead2),
    // Tell the hazard unit about loads still in MEM for synchronous memory timing.
    .ex_mem_mr(EX_MEM_reg.memRead2),
    .if_id_rs1(IF_DE_ir[19:15]),
    .de_ex_rs1(DE_EX_reg.rs1_addr),
    .if_id_rs2(IF_DE_ir[24:20]),
    .de_ex_rs2(DE_EX_reg.rs2_addr),
    .de_ex_rd(DE_EX_reg.rd_addr),
    .ex_mem_rd(EX_MEM_reg.rd_addr),
    .mem_wb_rd(MEM_WB_reg.rd_addr),

    //OUTPUTS
    .fwd_a(fwd_a),
    .fwd_b(fwd_b),
    .flush_IF_ID(flush_IF_ID),
    .flush_DE_EX(flush_DE_EX),
    .lw_stall(lw_stall)
);

//==================================================================
//==== Instruction Fetch ===========================================
//==================================================================

    assign pc_write = !(lw_stall || cache_stall);

    PC OTTER_PC(
        .CLK(CLK), 
        .RST(pc_rst), 
        .PC_WRITE(pc_write), 
        .PC_SOURCE(pc_source),
        .JALR(jalr), 
        .JAL(jal), 
        .BRANCH(branch), 
        .MTVEC(32'b0), 
        .MEPC(32'b0),
        .PC_OUT(pc_out), 
        .PC_OUT_INC(pc_out_inc));

    CacheFSM I_CACHE_FSM(
        .hit(i_cache_hit),
        .miss(i_cache_miss),
        .CLK(CLK),
        .RST(RST),
        .l2_read(i_l2_read),
        .update(i_cache_update),
        .pc_stall(i_stall));

    Instruction_Memory I_L2_MEMORY(
        .CLK(CLK),
        .RST(RST),
        .read_en(i_l2_read),
        .pc_in(pc_out),
        .data_out1(i_w0),
        .data_out2(i_w1),
        .data_out3(i_w2),
        .data_out4(i_w3),
        .data_out5(i_w4),
        .data_out6(i_w5),
        .data_out7(i_w6),
        .data_out8(i_w7));

    L1_I_Cache I_CACHE(
        .PC(pc_out),
        .CLK(CLK),
        .RST(RST),
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

    always_ff @(posedge CLK) begin
        if (RST) begin
            IF_DE_pc      <= '0;
            IF_DE_pc_plus <= '0;
            IF_DE_ir      <= 32'h00000013; //NOP
        end else if (cache_stall) begin
            IF_DE_pc      <= IF_DE_pc;
            IF_DE_pc_plus <= IF_DE_pc_plus;
            IF_DE_ir      <= IF_DE_ir;
        end else if (flush_IF_ID) begin
            IF_DE_pc      <= '0;
            IF_DE_pc_plus <= '0;
            IF_DE_ir      <= 32'h00000013; //NOP
        end else if (!lw_stall) begin
            IF_DE_pc      <= pc_out;
            IF_DE_pc_plus <= pc_out_inc;
            IF_DE_ir      <= ir;
        end
        //If we are in a stall, then nothing happens
    end

//===================================================================
//==== Instruction Decode ===========================================
//===================================================================

    REG_FILE OTTER_REG_FILE(
        .CLK(CLK), 
        .EN(MEM_WB_reg.regWrite),
        .ADR1(IF_DE_ir[19:15]), 
        .ADR2(IF_DE_ir[24:20]),
        .WA(MEM_WB_reg.rd_addr),
        .WD(wd), 
        .RS1(rs1), 
        .RS2(rs2));

    ImmediateGenerator OTTER_IMGEN(
        //INPUTS
        .IR(IF_DE_ir[31:7]),

        //OUTPUTS
        .U_TYPE(Utype), 
        .I_TYPE(Itype),
        .S_TYPE(Stype), 
        .B_TYPE(Btype), 
        .J_TYPE(Jtype));

    CU_DCDR OTTER_DCDR(
        //INPUTS
        .IR_30(IF_DE_ir[30]), 
        .IR_OPCODE(IF_DE_ir[6:0]),  
        .IR_FUNCT(IF_DE_ir[14:12]),
        .BR_EQ(1'b0), 
        .BR_LT(1'b0),
        .BR_LTU(1'b0),

        //OUTPUTS
        .PC_SOURCE(),
        .ALU_FUN(alu_fun), 
        .ALU_SRCA(alu_src_a),
        .ALU_SRCB(alu_src_b),
        .RF_WR_SEL(rf_wr_sel), 
        .REG_WRITE(reg_Write),
        .MEM_WE2(mem_write), 
        .MEM_RDEN2(mem_Read2));

    always_ff @(posedge CLK) begin
        if (RST) begin

            DE_EX_reg <= '0;//inject a NOP by clearing the DE/EX pipeline register

        end else if (cache_stall) begin

            DE_EX_reg <= DE_EX_reg;

        end else if (flush_DE_EX) begin

            DE_EX_reg <= '0;//inject a NOP by clearing the DE/EX pipeline register

        end else begin
            
        //IR CONCATENATIONS
            DE_EX_reg.opcode   <= IF_DE_ir[6:0];   
            DE_EX_reg.func3    <= IF_DE_ir[14:12];
        //REGISTER ADDRESSES
            DE_EX_reg.rs1_addr <= IF_DE_ir[19:15];
            DE_EX_reg.rs2_addr <= IF_DE_ir[24:20];
            DE_EX_reg.rd_addr  <= IF_DE_ir[11:7];
        //REGISTER VALUES
            DE_EX_reg.rs1      <= rs1;
            DE_EX_reg.rs2      <= rs2;
        //PC CONTROL SIGNALS
            DE_EX_reg.pc       <= IF_DE_pc;
            DE_EX_reg.pc_plus  <= IF_DE_pc_plus;
        //ALU CONTROL SIGNALS
            DE_EX_reg.alu_fun  <= alu_fun;
            DE_EX_reg.alu_src_a<= alu_src_a;
            DE_EX_reg.alu_src_b<= alu_src_b;
        //MEMORY CONTROL SIGNALS
            DE_EX_reg.memWrite <= mem_write;
            DE_EX_reg.memRead2 <= mem_Read2;
        //REGISTER FILE CONTROL SIGNALS
            DE_EX_reg.rf_wr_sel<= rf_wr_sel;
            DE_EX_reg.regWrite <= reg_Write;
        //IMMEDIATE VALUES
            DE_EX_reg.u_immed  <= Utype;
            DE_EX_reg.s_immed  <= Stype;
            DE_EX_reg.i_immed  <= Itype;
            DE_EX_reg.b_immed  <= Btype;
            DE_EX_reg.j_immed  <= Jtype;
        end
    end


//===================================================================
//==== Execute ======================================================
//====================================================================
    
    // Forwarding Muxes (before ALU src muxes because they feed into them)
    always_comb begin   
        case (fwd_a)
            2'b00: rs1_data = DE_EX_reg.rs1;
            2'b01: rs1_data = EX_MEM_reg.alu_result;
            2'b10: rs1_data = wd; //MEM_WB value
            default: rs1_data = DE_EX_reg.rs1;
        endcase
    end
    
    always_comb begin   
        case (fwd_b)
            2'b00: rs2_data = DE_EX_reg.rs2; 
            2'b01: rs2_data = EX_MEM_reg.alu_result;
            2'b10: rs2_data = wd; //MEM_WB value
            default: rs2_data = DE_EX_reg.rs2;
        endcase
    end

    //ALU SRC MUXES
    always_comb begin
        case (DE_EX_reg.alu_src_a)
            1'b0:    alu_A = rs1_data;
            1'b1:    alu_A = DE_EX_reg.u_immed;
            default: alu_A = rs1_data;
        endcase
    end

    always_comb begin
        case (DE_EX_reg.alu_src_b)
            2'b00:   alu_B = rs2_data;
            2'b01:   alu_B = DE_EX_reg.i_immed;
            2'b10:   alu_B = DE_EX_reg.s_immed;
            2'b11:   alu_B = DE_EX_reg.pc;
            default: alu_B = rs2_data;
        endcase
    end
    
    BCG OTTER_BCG(
        //INPUTS
        .RS1(rs1_data), 
        .RS2(rs2_data),
        //OUTPUTS
        .BR_EQ(br_eq), 
        .BR_LT(br_lt), 
        .BR_LTU(br_ltu));
        

    BAG OTTER_BAG(
        //INPUTS
        .RS1(rs1_data), 
        .I_TYPE(DE_EX_reg.i_immed), 
        .J_TYPE(DE_EX_reg.j_immed),
        .B_TYPE(DE_EX_reg.b_immed), 
        .FROM_PC(DE_EX_reg.pc),
        //OUTPUTS
        .JAL(jal), 
        .JALR(jalr), 
        .BRANCH(branch));
    
    EX_DCDR EX_DCDR(
        //INPUTS
        .de_ex_opcode(DE_EX_reg.opcode),    
        .BR_LT(br_lt),
        .BR_LTU(br_ltu),
        .BR_EQ(br_eq),
        .de_ex_f3(DE_EX_reg.func3),
        //OUTPUTS
        .PC_SOURCE(pc_source));
      
    ALU OTTER_ALU(
        .SRC_A(alu_A), 
        .SRC_B(alu_B),
        .ALU_FUN(DE_EX_reg.alu_fun), 
        .RESULT(alu_result));

    always_ff @(posedge CLK) begin
        if (RST) begin
            EX_MEM_reg <= '0; //Inject a NOP by clearing the EX/MEM
        end else if (cache_stall) begin
            EX_MEM_reg <= EX_MEM_reg;
        end else begin

            //RD ADDRESS
            EX_MEM_reg.rd_addr    <= DE_EX_reg.rd_addr;
            //RS2 VALUE (for stores) — use forwarded value so stores see correct data
            EX_MEM_reg.rs2        <= rs2_data;
            //ALU RESULT
            EX_MEM_reg.alu_result <= alu_result;
            //MEMORY READ
            EX_MEM_reg.memRead2   <= DE_EX_reg.memRead2;
            //MEMORY WRITE
            EX_MEM_reg.memWrite   <= DE_EX_reg.memWrite;
            //REGISTER WRITE
            EX_MEM_reg.regWrite   <= DE_EX_reg.regWrite;
            //FUNC3
            EX_MEM_reg.func3      <= DE_EX_reg.func3;
            //PC PLUS
            EX_MEM_reg.pc_plus    <= DE_EX_reg.pc_plus;
            //RF Write Select
            EX_MEM_reg.rf_wr_sel  <= DE_EX_reg.rf_wr_sel;
        end
    end

//==== Memory ======================================================

    assign IOBUS_ADDR = EX_MEM_reg.alu_result;
    assign IOBUS_OUT  = EX_MEM_reg.rs2;
    assign d_cacheable = (EX_MEM_reg.alu_result < 32'h00010000);
    assign d_data_read = EX_MEM_reg.memRead2 && d_cacheable;
    assign d_data_write = EX_MEM_reg.memWrite && d_cacheable;
    assign IOBUS_WR = EX_MEM_reg.memWrite && !d_cacheable && !cache_stall;

    always_comb begin
        case ({EX_MEM_reg.func3[2], EX_MEM_reg.func3[1:0], EX_MEM_reg.alu_result[1:0]})
            5'b00011: io_load_data = {{24{IOBUS_IN[31]}}, IOBUS_IN[31:24]};
            5'b00010: io_load_data = {{24{IOBUS_IN[23]}}, IOBUS_IN[23:16]};
            5'b00001: io_load_data = {{24{IOBUS_IN[15]}}, IOBUS_IN[15:8]};
            5'b00000: io_load_data = {{24{IOBUS_IN[7]}},  IOBUS_IN[7:0]};

            5'b00110: io_load_data = {{16{IOBUS_IN[31]}}, IOBUS_IN[31:16]};
            5'b00101: io_load_data = {{16{IOBUS_IN[23]}}, IOBUS_IN[23:8]};
            5'b00100: io_load_data = {{16{IOBUS_IN[15]}}, IOBUS_IN[15:0]};

            5'b01000: io_load_data = IOBUS_IN;

            5'b10011: io_load_data = {24'b0, IOBUS_IN[31:24]};
            5'b10010: io_load_data = {24'b0, IOBUS_IN[23:16]};
            5'b10001: io_load_data = {24'b0, IOBUS_IN[15:8]};
            5'b10000: io_load_data = {24'b0, IOBUS_IN[7:0]};

            5'b10110: io_load_data = {16'b0, IOBUS_IN[31:16]};
            5'b10101: io_load_data = {16'b0, IOBUS_IN[23:8]};
            5'b10100: io_load_data = {16'b0, IOBUS_IN[15:0]};

            default:  io_load_data = 32'b0;
        endcase
    end

    assign memory_data = d_cacheable ? d_cache_data : io_load_data;

    Data_FSM D_CACHE_FSM(
        .CLK(CLK),
        .RST(RST),
        .data_read(d_data_read),
        .data_write(d_data_write),
        .hit(d_cache_hit),
        .miss(d_cache_miss),
        .evict_valid(d_evict_valid),
        .FSM_write(d_cache_fill),
        .l2_read(d_l2_read),
        .l2_write(d_l2_write),
        .stall(d_stall));

    L1_D_Cache D_CACHE(
        .CLK(CLK),
        .RST(RST),
        .alu_result(EX_MEM_reg.alu_result),
        .rs2_data(EX_MEM_reg.rs2),
        .data_read(d_data_read),
        .data_write(d_data_write),
        .mem_size(EX_MEM_reg.func3[1:0]),
        .mem_sign(EX_MEM_reg.func3[2]),
        .FSM_write(d_cache_fill),
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

    Data_Memory D_L2_MEMORY(
        .CLK(CLK),
        .RST(RST),
        .read_en(d_l2_read),
        .write_en(d_l2_write),
        .read_addr(EX_MEM_reg.alu_result),
        .write_addr(d_evict_addr),
        .write_w0(d_evict_w0),
        .write_w1(d_evict_w1),
        .write_w2(d_evict_w2),
        .write_w3(d_evict_w3),
        .out1(d_w0),
        .out2(d_w1),
        .out3(d_w2),
        .out4(d_w3));

    always_ff @(posedge CLK) begin
        if (RST) begin
            MEM_WB_reg <= '0; //Inject a NOP by clearing the MEM/WB
        end else if (cache_stall) begin
            MEM_WB_reg <= MEM_WB_reg;
        end else begin
        //RD ADDRESS
        MEM_WB_reg.rd_addr    <= EX_MEM_reg.rd_addr;
        //ALU RESULT
        MEM_WB_reg.alu_result <= EX_MEM_reg.alu_result;
        //MEMORY DATA
        MEM_WB_reg.mem_data   <= memory_data;
        //REGISTER WRITE
        MEM_WB_reg.regWrite   <= EX_MEM_reg.regWrite;
        //RF Write Select
        MEM_WB_reg.rf_wr_sel  <= EX_MEM_reg.rf_wr_sel;
        //PC PLUS
        MEM_WB_reg.pc_plus    <= EX_MEM_reg.pc_plus;
        end
    end

//==== Write Back ==================================================

    FourMux OTTER_REG_MUX(
        //INPUTS
        .SEL(MEM_WB_reg.rf_wr_sel),
        .ZERO(MEM_WB_reg.pc_plus),
        .ONE(32'b0),
        .TWO(MEM_WB_reg.mem_data),
        .THREE(MEM_WB_reg.alu_result),
        //OUTPUT
        .OUT(wd));

endmodule
