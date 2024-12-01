`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/30/2024 05:12:44 PM
// Design Name: Pong Game
// Module Name: pong
// Project Name: Pong Game for Basys 3
// Target Devices: Basys 3
// Tool Versions: 
// Description: 
//  - Implements Pong with two paddles and ball bouncing logic.
//  - Integrates scoreboard and VGA display for Basys 3 board.
//  - Uses 12-bit RGB (4 bits per channel) for better color clarity.
//  - Includes clock divider, debouncing, and dynamic ball velocity.
// 
//////////////////////////////////////////////////////////////////////////////////

module pong(
    input clk,        // 100 MHz clock from Basys 3 board
    input reset,      // Reset button
    input p1_up,      // Player 1 up button
    input p1_down,    // Player 1 down button
    input p2_up,      // Player 2 up button
    input p2_down,    // Player 2 down button
    output hsync,     // VGA horizontal sync
    output vsync,       // VGA vertical sync
    output [6:0] seg,    // Segment outputs for the 7-segment display
    output reg [3:0] an,      // Anode signals for the 7-segment display 
    output [11:0] rgb // 12-bit RGB color signals (4 bits per channel)
);

  // Clock divider for paddle and ball
  reg [18:0] slow_clk_div;
  wire slow_clk;
  always @(posedge clk or posedge reset) begin
      if (reset)
          slow_clk_div <= 0;
      else
          slow_clk_div <= slow_clk_div + 1;
  end
  assign slow_clk = slow_clk_div[18]; // Adjust speed by selecting a higher or lower bit

  // VGA clock divider for 25 MHz VGA pixel clock
  reg [1:0] vga_clk_div;
  always @(posedge clk) vga_clk_div <= vga_clk_div + 1;
  wire vga_clk = vga_clk_div[1];  // Divide 100 MHz by 4 to get ~25 MHz
  
  reg [16:0] refresh_counter;  // 17-bit counter for refresh rate
always @(posedge clk or posedge reset) begin
    if (reset)
        refresh_counter <= 0;
    else
        refresh_counter <= refresh_counter + 1;
end
wire refresh_clk = refresh_counter[16]; // Use the MSB for a slow clock


  wire display_on;
  wire [9:0] hpos;
  wire [9:0] vpos;
  
  reg [9:0] paddle1_pos;  // Player 1 paddle vertical position
  reg [9:0] paddle2_pos;  // Player 2 paddle vertical position

  reg [9:0] ball_x;       // Ball X position
  reg [9:0] ball_y;       // Ball Y position
  reg ball_dir_x;         // Ball X direction (0=left, 1=right)
  reg ball_dir_y;         // Ball Y direction (0=up, 1=down)
  reg [1:0] ball_vel_x;   // Ball velocity in X direction
  reg [1:0] ball_vel_y;   // Ball velocity in Y direction


  localparam BALL_SIZE = 6;      // Ball size
  localparam PADDLE_HEIGHT = 40; // Paddle height
  localparam PADDLE_WIDTH = 4;   // Paddle width
  localparam SCREEN_WIDTH = 640; // Screen width
  localparam SCREEN_HEIGHT = 480;// Screen height
  localparam TOP_BOUNDARY = 10;  // Top boundary position
  localparam BOTTOM_BOUNDARY = SCREEN_HEIGHT - 10; // Bottom boundary position

  //Sync
  hvsync_generator hvsync_gen(
    .clk(vga_clk),
    .reset(reset),
    .hsync(hsync),
    .vsync(vsync),
    .display_on(display_on),
    .hpos(hpos),
    .vpos(vpos)
  );

  // Button Debouncing
  reg [19:0] p1_up_debounce, p1_down_debounce, p2_up_debounce, p2_down_debounce;
  wire p1_up_stable, p1_down_stable, p2_up_stable, p2_down_stable;

  always @(posedge clk or posedge reset) begin
      if (reset) begin
          p1_up_debounce <= 0;
          p1_down_debounce <= 0;
          p2_up_debounce <= 0;
          p2_down_debounce <= 0;
      end else begin
          p1_up_debounce <= {p1_up_debounce[18:0], p1_up};
          p1_down_debounce <= {p1_down_debounce[18:0], p1_down};
          p2_up_debounce <= {p2_up_debounce[18:0], p2_up};
          p2_down_debounce <= {p2_down_debounce[18:0], p2_down};
      end
  end

  assign p1_up_stable = &p1_up_debounce;     // Stable high when all bits are 1
  assign p1_down_stable = &p1_down_debounce; // Stable high when all bits are 1
  assign p2_up_stable = &p2_up_debounce;     // Stable high when all bits are 1
  assign p2_down_stable = &p2_down_debounce; // Stable high when all bits are 1

  // Paddle control logic for Player 1
  always @(posedge slow_clk or posedge reset) begin
      if (reset)
          paddle1_pos <= (SCREEN_HEIGHT / 2) - (PADDLE_HEIGHT / 2);
      else if (p1_up_stable && paddle1_pos > TOP_BOUNDARY)
          paddle1_pos <= paddle1_pos - 1;
      else if (p1_down_stable && paddle1_pos < SCREEN_HEIGHT - PADDLE_HEIGHT)
          paddle1_pos <= paddle1_pos + 1;
  end

  // Paddle control logic for Player 2
  always @(posedge slow_clk or posedge reset) begin
      if (reset)
          paddle2_pos <= (SCREEN_HEIGHT / 2) - (PADDLE_HEIGHT / 2);
      else if (p2_up_stable && paddle2_pos > TOP_BOUNDARY)
          paddle2_pos <= paddle2_pos - 1;
      else if (p2_down_stable && paddle2_pos < SCREEN_HEIGHT - PADDLE_HEIGHT)
          paddle2_pos <= paddle2_pos + 1;
  end
  
reg [3:0] p1_score; // Player 1 score (max 15)
reg [3:0] p2_score; // Player 2 score (max 15)
reg p1_incscore; // Signal to increment Player 1's score
reg p2_incscore; // Signal to increment Player 2's score
reg p1_score_ack; // Acknowledgment signal for Player 1 scoring
reg p2_score_ack; // Acknowledgment signal for Player 2 scoring
  
  // Ball movement and collision logic
  always @(posedge slow_clk or posedge reset) begin
      if (reset) begin
          ball_x <= SCREEN_WIDTH / 2;
          ball_y <= SCREEN_HEIGHT / 2;
          ball_dir_x <= 1;  // Start moving right
          ball_dir_y <= 1;  // Start moving down
          ball_vel_x <= 1;  // Default velocity in X
          ball_vel_y <= 1;  // Default velocity in Y
      end else begin
          // Ball position update
          ball_x <= ball_x + (ball_dir_x ? ball_vel_x : -ball_vel_x);
          ball_y <= ball_y + (ball_dir_y ? ball_vel_y : -ball_vel_y);

          // Ball collision with top and bottom boundaries
          if (ball_y <= TOP_BOUNDARY)
              ball_dir_y <= 1;  // Bounce down
          else if (ball_y + BALL_SIZE >= BOTTOM_BOUNDARY)
              ball_dir_y <= 0;  // Bounce up

          // Ball collision with paddles
          if (ball_x <= PADDLE_WIDTH && ball_y + BALL_SIZE >= paddle1_pos && ball_y <= paddle1_pos + PADDLE_HEIGHT) begin
              ball_dir_x <= 1; // Bounce right
              
          end else if (ball_x + BALL_SIZE >= SCREEN_WIDTH - PADDLE_WIDTH && ball_y + BALL_SIZE >= paddle2_pos && ball_y <= paddle2_pos + PADDLE_HEIGHT) begin
              ball_dir_x <= 0; 
          end

          // Ball out of bounds
if (ball_x <= 0) begin
    // Player 2 scores
    ball_x <= SCREEN_WIDTH / 2; // Reset ball position
    ball_y <= SCREEN_HEIGHT / 2;
    ball_dir_x <= ~ball_dir_x;  // Reverse direction
    ball_vel_x <= 1;            // Reset X velocity
    ball_vel_y <= 1;            // Reset Y velocity
    if (!p2_score_ack) begin    // Assert score signal only if not already acknowledged
        p2_incscore <= 1;
    end else begin
        p2_incscore <= 0;       // Ensure signal is deasserted if acknowledged
    end
end else if (ball_x + BALL_SIZE >= SCREEN_WIDTH) begin
    // Player 1 scores
    ball_x <= SCREEN_WIDTH / 2; // Reset ball position
    ball_y <= SCREEN_HEIGHT / 2;
    ball_dir_x <= ~ball_dir_x;  // Reverse direction
    ball_vel_x <= 1;            // Reset X velocity
    ball_vel_y <= 1;            // Reset Y velocity
    if (!p1_score_ack) begin    // Assert score signal only if not already acknowledged
        p1_incscore <= 1;
    end else begin
        p1_incscore <= 0;       // Ensure signal is deasserted if acknowledged
    end
end else begin
    // Deassert score increment signals if no scoring
    p1_incscore <= 0;
    p2_incscore <= 0;
end
      end
  end
  
always @(posedge clk or posedge reset) begin
    if (reset) begin
        p1_score <= 0;          // Reset Player 1's score
        p2_score <= 0;          // Reset Player 2's score
        p1_score_ack <= 0;      // Reset Player 1's acknowledgment
        p2_score_ack <= 0;      // Reset Player 2's acknowledgment
    end else begin
        // Player 1 Score
        if (p1_incscore && !p1_score_ack) begin
            p1_score <= p1_score + 1;  // Increment Player 1's score
            p1_score_ack <= 1;        // Set acknowledgment
        end else if (!p1_incscore) begin
            p1_score_ack <= 0;        // Clear acknowledgment when signal is deasserted
        end

        // Player 2 Score
        if (p2_incscore && !p2_score_ack) begin
            p2_score <= p2_score + 1;  // Increment Player 2's score
            p2_score_ack <= 1;        // Set acknowledgment
        end else if (!p2_incscore) begin
            p2_score_ack <= 0;        // Clear acknowledgment when signal is deasserted
        end
    end
end

reg [1:0] anode_select; // Selects which display to activate

always @(posedge refresh_clk or posedge reset) begin
    if (reset)
        anode_select <= 0; // Start at the first display
    else
        anode_select <= anode_select + 1; // Cycle through all four displays
end

always @(*) begin
    case (anode_select)
        2'b00: an = 4'b1110; // Activate the first display (Player 2 ones digit)
        2'b01: an = 4'b1101; // Activate the second display (Player 2 tens digit)
        2'b10: an = 4'b1011; // Activate the third display (Player 1 ones digit)
        2'b11: an = 4'b0111; // Activate the fourth display (Player 1 tens digit)
        default: an = 4'b1111; // Turn off all displays
    endcase
end

reg [3:0] current_digit; // Digit to display
reg [6:0] seg;           // Segment outputs

always @(*) begin
    case (anode_select)
        2'b00: current_digit = p2_score % 10;  // Player 2 ones digit (leftmost display)
        2'b01: current_digit = p2_score / 10;  // Player 2 tens digit (second leftmost display)
        2'b10: current_digit = p1_score % 10;  // Player 1 ones digit (third display from left)
        2'b11: current_digit = p1_score / 10;  // Player 1 tens digit (rightmost display)
        default: current_digit = 4'd0;         // Default to 0
    endcase

    // Convert digit to 7-segment encoding
    case (current_digit)
        4'd0: seg = 7'b1000000; // 0
        4'd1: seg = 7'b1111001; // 1
        4'd2: seg = 7'b0100100; // 2
        4'd3: seg = 7'b0110000; // 3
        4'd4: seg = 7'b0011001; // 4
        4'd5: seg = 7'b0010010; // 5
        4'd6: seg = 7'b0000010; // 6
        4'd7: seg = 7'b1111000; // 7
        4'd8: seg = 7'b0000000; // 8
        4'd9: seg = 7'b0010000; // 9
        default: seg = 7'b1111111; // Blank
    endcase
end

  // Paddle and ball graphics
  wire paddle1_gfx = (hpos < PADDLE_WIDTH) && (vpos >= paddle1_pos) && (vpos < paddle1_pos + PADDLE_HEIGHT);
  wire paddle2_gfx = (hpos >= SCREEN_WIDTH - PADDLE_WIDTH) && (vpos >= paddle2_pos) && (vpos < paddle2_pos + PADDLE_HEIGHT);
  wire ball_gfx = (hpos >= ball_x) && (hpos < ball_x + BALL_SIZE) &&
                  (vpos >= ball_y) && (vpos < ball_y + BALL_SIZE);

 // VGA color logic (ball, paddles, background)
  assign rgb = (display_on) ? (
      (hpos >= ball_x && hpos < ball_x + BALL_SIZE && vpos >= ball_y && vpos < ball_y + BALL_SIZE) ? 12'b000000001111 : // Ball
      (hpos <= PADDLE_WIDTH && vpos >= paddle1_pos && vpos < paddle1_pos + PADDLE_HEIGHT) ? 12'b000011110000 : // Paddle 1
      (hpos >= SCREEN_WIDTH - PADDLE_WIDTH && vpos >= paddle2_pos && vpos < paddle2_pos + PADDLE_HEIGHT) ? 12'b111100000000 : // Paddle 2
      12'b000000000000 // Background (black)
  ) : 12'b000000000000;  // No display outside active area
endmodule


