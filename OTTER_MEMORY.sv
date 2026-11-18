`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer: J. Callenes, P. Hummel
//
// Create Date: 01/27/2019 08:37:11 AM
// Module Name: OTTER_mem
// Project Name: Memory for OTTER RV32I RISC-V
// Tool Versions: Xilinx Vivado 2019.2
// Description: 64k Memory, dual access read single access write. Designed to
//              purposely utilize BRAM which requires synchronous reads and write
//              ADDR1 used for Program Memory Instruction. Word addressable so it
//              must be adapted from byte addresses in connection from PC
//              ADDR2 used for data access, both internal and external memory
//              mapped IO. ADDR2 is byte addressable.
//              RDEN1 and EDEN2 are read enables for ADDR1 and ADDR2. These are 
//              needed due to synchronous reading
//              MEM_SIZE used to specify reads as byte (0), half (1), or word (2)
//              MEM_SIGN used to specify unsigned (1) vs signed (0) extension
//              IO_IN is data from external IO and synchronously buffered
//
// Memory OTTER_MEMORY (
//    .MEM_CLK   (),
//    .MEM_RDEN1 (), 
//    .MEM_RDEN2 (), 
//    .MEM_WE2   (),
//    .MEM_ADDR1 (),
//    .MEM_ADDR2 (),
//    .MEM_DIN2  (),  
//    .MEM_SIZE  (),
//    .MEM_SIGN  (),
//    .IO_IN     (),
//    .IO_WR     (),
//    .MEM_DOUT1 (),
//    .MEM_DOUT2 ()  ); 
//
// Revision  History:
// Revision 0.01 - Original by J. Callenes
// Revision 1.02 - Rewrite to simplify logic by P. Hummel
// Revision 1.03 - changed signal names, added instantiation template
// Revision 1.04 - added defualt to write case statement
// Revision 1.05 - changed MEM_WD to MEM_DIN2, changed default to save nothing
// Revision 1.06 - removed type in instantiation template
//
//////////////////////////////////////////////////////////////////////////////////
                                                                                                                             
  module Memory (
    input mem_clk,
    input mem_rden1,        // read enable Instruction
    input mem_rden2,        // read enable data
    input mem_we2,          // write enable.
    input [13:0] mem_addr1, // Instruction Memory word Addr (Connect to PC[15:2])
    input [31:0] mem_addr2, // Data Memory Addr
    input [31:0] mem_din2,  // Data to save
    input [1:0] mem_size,   // 0-Byte, 1-Half, 2-Word
    input mem_sign,         // 1-unsigned 0-signed
    input [31:0] io_in,     // Data from IO     
    input clr_dout1,
    //output ERR,
    output logic io_wr,     // IO 1-write 0-read
    output logic [31:0] mem_dout1 = 32'h00000013,  // Instruction
    output logic [31:0] mem_dout2 = 32'h00000000); // Data
    
    logic [13:0] wordaddr1, wordaddr2;
    logic [31:0] memreadword, iobuffer, memreadsized;
    logic [1:0] byteoffset;
    logic mem_sign_reg;
    logic [1:0] mem_size_reg;
    logic [1:0] byteoffset_reg; // reg version of byteOffset for loads
    logic weaddrvalid; // active when saving (WE) to valid memory address
    logic mmio_sel; // active when LOADing in the MMIO region
       
    (* rom_style="{distributed | block}" *)
    (* ram_decomp = "power" *) logic [31:0] memory [0:16383];
    
    initial begin
        $readmemh("performance.mem", memory, 0, 16383);
    end
    
    assign wordaddr2 = mem_addr2[15:2];
    assign byteoffset = mem_addr2[1:0];     // byte offset of memory address
            
    // buffer the IO input for reading
    always_ff @(posedge mem_clk) begin
        if(mem_rden2) begin
            iobuffer <= io_in;
            // Select signal used for deciding if
            // LOADs are in MMIO region or not
            mmio_sel <= (mem_addr2 >= 32'h00010000);
        end
    end
    
    // BRAM requires all reads and writes to occur synchronously
    always_ff @(posedge mem_clk) begin
    
      // save data (WD) to memory (ADDR2)
      if (weaddrvalid == 1) begin  //(MEM_WE == 1) && (MEM_ADDR2 < 16'hFFFD)) begin   // write enable and valid address space
        case({mem_size,byteoffset})
            4'b0000: memory[wordaddr2][7:0]   <= mem_din2[7:0];     // sb at byte offsets
            4'b0001: memory[wordaddr2][15:8]  <= mem_din2[7:0];
            4'b0010: memory[wordaddr2][23:16] <= mem_din2[7:0];
            4'b0011: memory[wordaddr2][31:24] <= mem_din2[7:0];
            4'b0100: memory[wordaddr2][15:0]  <= mem_din2[15:0];    // sh at byte offsets
            4'b0101: memory[wordaddr2][23:8]  <= mem_din2[15:0];
            4'b0110: memory[wordaddr2][31:16] <= mem_din2[15:0];
            4'b1000: memory[wordaddr2]        <= mem_din2;          // sw
			
			//default: memory[wordAddr2] <= 32'b0  // unsupported size, byte offset combination
			// removed to avoid mistakes causing memory to be zeroed.
        endcase
      end

        // read all data synchronously required for BRAM
        if (clr_dout1) // clear signal used for flush_DE signal
            mem_dout1 <= 32'h00000013;
        else if(mem_rden1) // need EN for extra load cycle to not change instruction
            mem_dout1 <= memory[mem_addr1];
        

        if(mem_rden2) begin // Read word from memory
            memreadword <= memory[wordaddr2];
            // Register size, sign, and offset for reading
            // if this is not done, MEM_SIZE, MEM_SIGN, and the offset can change 
            // combinationally, causing issues with the below always_comb block
            mem_size_reg <= mem_size;
            mem_sign_reg <= mem_sign;
            byteoffset_reg <= byteoffset;
        end 
    end
       
    // Change the data word into sized bytes and sign extend 
    always_comb begin
        case({mem_sign_reg,mem_size_reg,byteoffset_reg})
            5'b00011: memreadsized = {{24{memreadword[31]}},memreadword[31:24]};    // signed byte
            5'b00010: memreadsized = {{24{memreadword[23]}},memreadword[23:16]};
            5'b00001: memreadsized = {{24{memreadword[15]}},memreadword[15:8]};
            5'b00000: memreadsized = {{24{memreadword[7]}},memreadword[7:0]};
                                    
            5'b00110: memreadsized = {{16{memreadword[31]}},memreadword[31:16]};    // signed half
            5'b00101: memreadsized = {{16{memreadword[23]}},memreadword[23:8]};
            5'b00100: memreadsized = {{16{memreadword[15]}},memreadword[15:0]};
            
            5'b01000: memreadsized = memreadword;                   // word
               
            5'b10011: memreadsized = {24'd0,memreadword[31:24]};    // unsigned byte
            5'b10010: memreadsized = {24'd0,memreadword[23:16]};
            5'b10001: memreadsized = {24'd0,memreadword[15:8]};
            5'b10000: memreadsized = {24'd0,memreadword[7:0]};
               
            5'b10110: memreadsized = {16'd0,memreadword[31:16]};    // unsigned half
            5'b10101: memreadsized = {16'd0,memreadword[23:8]};
            5'b10100: memreadsized = {16'd0,memreadword[15:0]};
            
            default:  memreadsized = 32'b0;     // unsupported size, byte offset combination 
        endcase
    end
 
    // Memory Mapped IO 
    always_comb begin
        // writes
        if (mem_addr2 >= 32'h00010000) begin
            // writes in the mmio region
            // combinational, as store happens @ clock cycle N
            io_wr = mem_we2;
            weaddrvalid = 1'b0;
        end else begin
            // writes to real dmem
            io_wr = 1'b0;
            weaddrvalid = mem_we2;
        end

        // reads
        // uses registered mmio_sel, as load happens @ clock cycle N + 1
        mem_dout2 = mmio_sel ? iobuffer : memreadsized;
    end
        
 endmodule