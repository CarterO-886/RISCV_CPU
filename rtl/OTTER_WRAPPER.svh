`timescale 1ns / 1ps
/////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer: J. Calllenes
//           P. Hummel
//
// Create Date: 01/20/2019 10:36:50 AM
// Module Name: OTTER_Wrapper
// Target Devices: OTTER MCU on Basys3
// Description: OTTER_WRAPPER with Switches, LEDs, and 7-segment display
//
// Revision:
// Revision 0.01 - File Created
// Revision 0.02 - Updated MMIO Addresses, signal names
/////////////////////////////////////////////////////////////////////////////
  
module OTTER_Wrapper(
   input clk,
   //input BTNL,
   input btnc,
   input [15:0] switches,
   output logic [15:0] leds,
   output [7:0] cathodes,
   output [3:0] anodes
   );
   
   
    // INPUT PORT IDS ///////////////////////////////////////////////////////
    // Right now, the only possible inputs are the switches
    // In future labs you can add more MMIO, and you'll have
    // to add constants here for the mux below
    localparam switches_ad = 32'h11000000;
           
    // OUTPUT PORT IDS //////////////////////////////////////////////////////
    // In future labs you can add more MMIO
    // Match the MMIO addresses used by the loaded test program.
    localparam leds_ad    = 32'h1100C000;
    localparam sseg_ad    = 32'h1100C00C;
    
   // Signals for connecting OTTER_MCU to OTTER_wrapper /////////////////////
   logic clk_50 = 0;
    
   logic [31:0] iobus_out, iobus_in, iobus_addr;
   logic s_reset, iobus_wr;
   
   // Registers for buffering outputs  /////////////////////////////////////
   logic [15:0] r_sseg;  
     
   // Declare OTTER_CPU ////////////////////////////////////////////////////
   OTTER_MCU cpu (.rst(s_reset), .clk(clk_50), 
                  .iobus_out(iobus_out), .iobus_in(iobus_in),
                  .iobus_addr(iobus_addr), .iobus_wr(iobus_wr)); 
 
   // Declare Seven Segment Display /////////////////////////////////////////
   SevSegDisp ssg_disp (.DATA_IN(r_sseg), .CLK(clk), .MODE(1'b0),
                       .CATHODES(cathodes), .ANODES(anodes));
   
                           
   // Clock Divider to create 50 MHz Clock //////////////////////////////////
   always_ff @(posedge clk) begin
       clk_50 <= ~clk_50;
   end
   
   // Connect Signals ///////////////////////////////////////////////////////
   assign s_reset = btnc;
   
   
   // Connect Board input peripherals (Memory Mapped IO devices) to IOBUS
   always_comb begin
        case(iobus_addr)
            switches_ad: iobus_in = {16'b0,switches};
            default:     iobus_in = 32'b0;    // default bus input to 0
        endcase
    end
   
   
   // Connect Board output peripherals (Memory Mapped IO devices) to IOBUS
    always_ff @ (posedge clk_50) begin
        if(iobus_wr)
            case(iobus_addr)
                leds_ad: leds   <= iobus_out[15:0];
                sseg_ad: r_sseg <= iobus_out[15:0];
            endcase
    end
   
   endmodule
