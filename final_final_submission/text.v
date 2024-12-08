
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Reference book: "FPGA Prototyping by Verilog Examples"
//                      "Xilinx Spartan-3 Version"
// Written by: Dr. Pong P. Chu
// Published by: Wiley, 2008
//
// Adapted for Basys 3 by David J. Marion aka FPGA Dude
//
//////////////////////////////////////////////////////////////////////////////////


module pong_text(
    input clk,
    input [3:0] dig0, dig1,dig2,dig3,
    input [9:0] x, y,
    output text_on,
    output reg [11:0] text_rgb
    );
    
    // signal declaration
    wire [10:0] rom_addr;
    reg [6:0] char_addr, char_addr_s;
    reg [3:0] row_addr;
    wire [3:0] row_addr_s;
    reg [2:0] bit_addr;
    wire [2:0] bit_addr_s;
    wire [7:0] ascii_word;
    wire ascii_bit, score_on;
    wire [7:0] rule_rom_addr;
    
   // instantiate ascii rom
   ascii_rom ascii_unit(.clk(clk), .addr(rom_addr), .data(ascii_word));
   
   // ---------------------------------------------------------------------------
   // score region
   // - display two-digit score and ball # on top left
   // - scale to 16 by 32 text size
   // - line 1, 16 chars: "Score: dd Ball: d"
   // ---------------------------------------------------------------------------
   assign score_on = (y >= 32) && (y < 64) && (x[9:4] < 16);
   //assign score_on = (y[9:5] == 0) && (x[9:4] < 16);
   assign row_addr_s = y[4:1];
   assign bit_addr_s = x[3:1];
   always @*
    case(x[7:4])
        4'h0 : char_addr_s = 7'h53;     // S
        4'h1 : char_addr_s = 7'h43;     // C
        4'h2 : char_addr_s = 7'h4F;     // O
        4'h3 : char_addr_s = 7'h52;     // R
        4'h4 : char_addr_s = 7'h45;     // E
        4'h5 : char_addr_s = 7'h3A;     // :
        4'h6 : char_addr_s = {3'b011, dig0};    // tens digit
        4'h7 : char_addr_s = {3'b011, dig1};    // ones digit
        4'h8 : char_addr_s = 7'h2D;     // Dash (-)
        4'h9 : char_addr_s = {3'b011, dig2};    // tens digit
        4'hA : char_addr_s = {3'b011, dig3};    // ones digit
        default: char_addr_s = 7'h00;            // Blank
    endcase

    
    // mux for ascii ROM addresses and rgb
    always @* begin
        text_rgb = 12'h0FF;     // aqua background
        
        if(score_on) begin
            char_addr = char_addr_s;
            row_addr = row_addr_s;
            bit_addr = bit_addr_s;
            if(ascii_bit)
                text_rgb = 12'hF00; // red
        end
        
      
    end
    
    assign text_on = score_on;
    
    // ascii ROM interface
    assign rom_addr = {char_addr, row_addr};
    assign ascii_bit = ascii_word[~bit_addr];
      
endmodule
