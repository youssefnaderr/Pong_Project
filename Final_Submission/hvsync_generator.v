
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/30/2024 05:18:02 PM
// Design Name: 
// Module Name: hvsync_generator
// Project Name: Pong Game for Basys 3
// Target Devices: Basys 3
// Tool Versions: 
// Description: 
//  - VGA signal generator for 640x480 @ 60 Hz.
// 
//////////////////////////////////////////////////////////////////////////////////

module hvsync_generator(
    input clk,          // Pixel clock (25 MHz for 640x480 @ 60 Hz)
    input reset,        // Reset signal
    output reg hsync,   // Horizontal sync output
    output reg vsync,   // Vertical sync output
    output display_on,  // Active video region (1 when displaying video)
    output [9:0] hpos,  // Current pixel position (horizontal)
    output [9:0] vpos   // Current pixel position (vertical)
);

    // VGA Timing Parameters for 640x480 @ 60 Hz
    localparam H_ACTIVE   = 640;  // Horizontal active pixels
    localparam H_FRONT    = 16;   // Horizontal front porch
    localparam H_SYNC     = 96;   // Horizontal sync pulse
    localparam H_BACK     = 46;   // Horizontal back porch
    localparam H_TOTAL    = H_ACTIVE + H_FRONT + H_SYNC + H_BACK; // Total pixels per line

    localparam V_ACTIVE   = 480;  // Vertical active lines
    localparam V_FRONT    = 15;   // Vertical front porch
    localparam V_SYNC     = 2;    // Vertical sync pulse
    localparam V_BACK     = 33;   // Vertical back porch
    localparam V_TOTAL    = V_ACTIVE + V_FRONT + V_SYNC + V_BACK; // Total lines per frame

    // Horizontal and Vertical Counters
    reg [9:0] hcounter;  // Horizontal pixel counter
    reg [9:0] vcounter;  // Vertical line counter

    // Horizontal Sync Generation
    always @(posedge clk or posedge reset)
    begin
        if (reset)
            hcounter <= 0;
        else if (hcounter == H_TOTAL - 1)
            hcounter <= 0;  // Reset at end of line
        else
            hcounter <= hcounter + 1;
    end

    // Vertical Sync Generation
    always @(posedge clk or posedge reset)
    begin
        if (reset)
            vcounter <= 0;
        else if (hcounter == H_TOTAL - 1) begin
            if (vcounter == V_TOTAL - 1)
                vcounter <= 0;  // Reset at end of frame
            else
                vcounter <= vcounter + 1;
        end
    end

    // Assign Horizontal Sync Signal
    always @(posedge clk)
    begin
        hsync <= (hcounter >= H_ACTIVE + H_FRONT) && (hcounter < H_ACTIVE + H_FRONT + H_SYNC);
    end

    // Assign Vertical Sync Signal
    always @(posedge clk)
    begin
        vsync <= (vcounter >= V_ACTIVE + V_FRONT) && (vcounter < V_ACTIVE + V_FRONT + V_SYNC);
    end

    // Display On Signal (Active Video Region)
    assign display_on = (hcounter < H_ACTIVE) && (vcounter < V_ACTIVE);

    // Output Current Pixel Position
    assign hpos = hcounter;
    assign vpos = vcounter;

endmodule

