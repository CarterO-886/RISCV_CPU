`timescale 1ns / 1ps

typedef struct packed {
    
    logic [6:0] opcode;    
    
    //IR
    logic [31:0] ir;
    
    //ALU
    logic [3:0]  alu_fun;
    logic        alu_src_a;
    logic [1:0]  alu_src_b; 
    logic [31:0] alu_result;

    logic        memWrite;
    logic        memRead2;
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

module OTTER(
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

    logic mem_rden1;
    logic [31:0] memory_data;

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
    
    logic stall;
    
    assign mem_rden1 = !stall;
    assign pc_write  = !stall;

    logic flush;
    
    logic [31:0] rs1_data;
    logic [31:0] rs2_data;
    
    logic [1:0] fwd_a;
    logic [1:0] fwd_b;

//==== Hazard Unit ================================================

Hazard_Unit HU ( 
    .pc_sel(pc_source),
    .ex_mem_rw(EX_MEM_reg.regWrite),
    .mem_wb_rw(MEM_WB_reg.regWrite),
    .de_ex_mr(DE_EX_reg.memRead2),
    .if_id_rs1(IF_DE_ir[19:15]),
    .de_ex_rs1(DE_EX_reg.rs1_addr),
    .if_id_rs2(IF_DE_ir[24:20]),
    .de_ex_rs2(DE_EX_reg.rs2_addr),
    .de_ex_rd(DE_EX_reg.rd_addr),
    .ex_mem_rd(EX_MEM_reg.rd_addr),
    .mem_wb_rd(MEM_WB_reg.rd_addr),
    .stall(stall),
    .fwd_a(fwd_a),
    .fwd_b(fwd_b),
    .flush(flush)
);

//==== Instruction Fetch ===========================================

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

    always_ff @(posedge CLK) begin
        if (flush) begin
            IF_DE_pc      <= '0;
            IF_DE_pc_plus <= '0;
        end else if (!stall) begin
            IF_DE_pc      <= pc_out;
            IF_DE_pc_plus <= pc_out_inc;
        end
    end

//==== Instruction Decode ===========================================

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
        .IR(IF_DE_ir[31:7]),
        .U_TYPE(Utype), 
        .I_TYPE(Itype),
        .S_TYPE(Stype), 
        .B_TYPE(Btype), 
        .J_TYPE(Jtype));

    CU_DCDR OTTER_DCDR(
        .IR_30(IF_DE_ir[30]), 
        .IR_OPCODE(opcode_t'(IF_DE_ir[6:0])),  
        .IR_FUNCT(IF_DE_ir[14:12]),
        .ALU_FUN(alu_fun), 
        .ALU_SRCA(alu_src_a),
        .ALU_SRCB(alu_src_b),
        .RF_WR_SEL(rf_wr_sel), 
        .REG_WRITE(reg_Write),
        .MEM_WE2(mem_write), 
        .MEM_RDEN2(mem_Read2));

    always_ff @(posedge CLK) begin
        if (stall || flush) begin
            DE_EX_reg <= '0;
        end else begin
            DE_EX_reg.opcode   <= opcode_t'(IF_DE_ir[6:0]);   
            DE_EX_reg.func3    <= IF_DE_ir[14:12];
            DE_EX_reg.rs1_addr <= IF_DE_ir[19:15];
            DE_EX_reg.rs2_addr <= IF_DE_ir[24:20];
            DE_EX_reg.rd_addr  <= IF_DE_ir[11:7];
            DE_EX_reg.rs1      <= rs1;
            DE_EX_reg.rs2      <= rs2;
            DE_EX_reg.pc       <= IF_DE_pc;
            DE_EX_reg.pc_plus  <= IF_DE_pc_plus;
            DE_EX_reg.alu_fun  <= alu_fun;
            DE_EX_reg.alu_src_a<= alu_src_a;
            DE_EX_reg.alu_src_b<= alu_src_b;
            DE_EX_reg.memWrite <= mem_write;
            DE_EX_reg.memRead2 <= mem_Read2;
            DE_EX_reg.rf_wr_sel<= rf_wr_sel;
            DE_EX_reg.regWrite <= reg_Write;
            DE_EX_reg.u_immed  <= Utype;
            DE_EX_reg.s_immed  <= Stype;
            DE_EX_reg.i_immed  <= Itype;
            DE_EX_reg.b_immed  <= Btype;
            DE_EX_reg.j_immed  <= Jtype;
        end
    end

//==== Execute ======================================================

    always_comb begin   
        case (fwd_a)
            2'b00: rs1_data = DE_EX_reg.rs1;
            2'b01: rs1_data = EX_MEM_reg.alu_result;
            2'b10: rs1_data = wd;
            default: rs1_data = DE_EX_reg.rs1;
        endcase
    end
    
    always_comb begin   
        case (fwd_b)
            2'b00: rs2_data = DE_EX_reg.rs2; 
            2'b01: rs2_data = EX_MEM_reg.alu_result;
            2'b10: rs2_data = wd;
            default: rs2_data = DE_EX_reg.rs2;
        endcase
    end

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
        .RS1(rs1_data), 
        .RS2(rs2_data),
        .BR_EQ(br_eq), 
        .BR_LT(br_lt), 
        .BR_LTU(br_ltu));
        
    EX_DCDR EXE_DE ( 
        .de_ex_opcode(DE_EX_reg.opcode),    
        .BR_LT(br_lt),
        .BR_LTU(br_ltu),
        .BR_EQ(br_eq),
        .de_ex_f3(DE_EX_reg.func3),
        .PC_SOURCE(pc_source));

    BAG OTTER_BAG(
        .RS1(rs1_data), 
        .I_TYPE(DE_EX_reg.i_immed), 
        .J_TYPE(DE_EX_reg.j_immed),
        .B_TYPE(DE_EX_reg.b_immed), 
        .FROM_PC(DE_EX_reg.pc),
        .JAL(jal), 
        .JALR(jalr), 
        .BRANCH(branch));
        
    ALU OTTER_ALU(
        .SRC_A(alu_A), 
        .SRC_B(alu_B),
        .ALU_FUN(DE_EX_reg.alu_fun), 
        .RESULT(alu_result));

    always_ff @(posedge CLK) begin
        EX_MEM_reg.rd_addr    <= DE_EX_reg.rd_addr;
        EX_MEM_reg.rs2        <= DE_EX_reg.rs2;
        EX_MEM_reg.alu_result <= alu_result;
        EX_MEM_reg.memRead2   <= DE_EX_reg.memRead2;
        EX_MEM_reg.memWrite   <= DE_EX_reg.memWrite;
        EX_MEM_reg.regWrite   <= DE_EX_reg.regWrite;
        EX_MEM_reg.func3      <= DE_EX_reg.func3;
        EX_MEM_reg.pc_plus    <= DE_EX_reg.pc_plus;
        EX_MEM_reg.rf_wr_sel  <= DE_EX_reg.rf_wr_sel;
    end

//==== Memory ======================================================

    assign IOBUS_ADDR = EX_MEM_reg.alu_result;
    assign IOBUS_OUT  = EX_MEM_reg.rs2;

    Memory OTTER_MEMORY(
        .MEM_CLK(CLK), 
        .MEM_RDEN1(mem_rden1),
        .MEM_RDEN2(EX_MEM_reg.memRead2),
        .MEM_WE2(EX_MEM_reg.memWrite),
        .MEM_ADDR1(pc_out[15:2]),
        .MEM_ADDR2(EX_MEM_reg.alu_result),
        .MEM_DIN2(EX_MEM_reg.rs2),
        .MEM_SIZE(EX_MEM_reg.func3[1:0]),
        .MEM_SIGN(EX_MEM_reg.func3[2]),
        .IO_IN(IOBUS_IN), 
        .IO_WR(IOBUS_WR),
        .MEM_DOUT1(IF_DE_ir),
        .MEM_DOUT2(memory_data),
        .CLR_DOUT1(RST || flush));

    always_ff @(posedge CLK) begin
        MEM_WB_reg.rd_addr    <= EX_MEM_reg.rd_addr;
        MEM_WB_reg.alu_result <= EX_MEM_reg.alu_result;
        MEM_WB_reg.pc_plus    <= EX_MEM_reg.pc_plus;
        MEM_WB_reg.regWrite   <= EX_MEM_reg.regWrite;
        MEM_WB_reg.rf_wr_sel  <= EX_MEM_reg.rf_wr_sel;
        MEM_WB_reg.mem_data   <= memory_data;
    end

//==== Write Back ==================================================

    FourMux OTTER_REG_MUX(
        .SEL(MEM_WB_reg.rf_wr_sel),
        .ZERO(MEM_WB_reg.pc_plus),
        .ONE(32'b0),
        .TWO(MEM_WB_reg.mem_data),
        .THREE(MEM_WB_reg.alu_result),
        .OUT(wd));

endmodule