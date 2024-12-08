`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/06/2024 09:30:56 PM
// Design Name: 
// Module Name: circle_rom
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module circle_rom(
    input [2:0] rom_addr,    // Row address (0 to 5)
    output reg [5:0] rom_data // Output pixel data (6 bits per row)
);
    always @* begin
        case (rom_addr)
            3'b000: rom_data = 6'b001100; //   **  
            3'b001: rom_data = 6'b111111; //  **** 
            3'b010: rom_data = 6'b111111; // ******
            3'b011: rom_data = 6'b111111; // ******
            3'b100: rom_data = 6'b111111; //  **** 
            3'b101: rom_data = 6'b001100; //   **  
            default: rom_data = 6'b000000; // Empty row
        endcase
    end
endmodule




