`timescale 1ns / 1ps


module pong(
    input clk,        // 100 MHz clock 
    input reset,      // Reset button
    input p1_up,      // Player 1 up button
    input p1_down,    // Player 1 down button
    input p2_up,      // Player 2 up button
    input p2_down,    // Player 2 down button
    input pause,      // Switch to pause the game
    input start,       // Switch to start the game
    output hsync,     // VGA horizontal sync
    output vsync,       // VGA vertical sync
    output [6:0] seg,    // Segment outputs for the 7-segment display
    output reg [3:0] an,      // Anode signals for the 7-segment display 
    output [11:0] rgb // 12-bit RGB color signals 
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
  assign slow_clk = slow_clk_div[18]; 
  

  // VGA clock divider for 25 MHz VGA pixel clock
  reg [1:0] vga_clk_div;
  always @(posedge clk) vga_clk_div <= vga_clk_div + 1;
  wire vga_clk = vga_clk_div[1];  
  
  // 7 Segment clock divider 
  reg [16:0] refresh_counter;  
always @(posedge clk or posedge reset) begin
    if (reset)
        refresh_counter <= 0;
    else
        refresh_counter <= refresh_counter + 1;
end
wire refresh_clk = refresh_counter[16]; 


  wire display_on;
  wire [9:0] hpos;
  wire [9:0] vpos;
  
  reg [9:0] paddle1_pos;  // Player 1 paddle vertical position
  reg [9:0] paddle2_pos;  // Player 2 paddle vertical position

  reg [9:0] ball_x;       // Ball X position
  reg [9:0] ball_y;       // Ball Y position
  reg ball_dir_x;         // Ball X direction 
  reg ball_dir_y;         // Ball Y direction 
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
      else if(!game_over && start && !pause)begin 
      if (p1_up_stable && paddle1_pos > TOP_BOUNDARY)
          paddle1_pos <= paddle1_pos - 1;
      else if (p1_down_stable && paddle1_pos < SCREEN_HEIGHT - PADDLE_HEIGHT)
          paddle1_pos <= paddle1_pos + 1;
  end
end
  // Paddle control logic for Player 2
  always @(posedge slow_clk or posedge reset) begin
      if (reset)
          paddle2_pos <= (SCREEN_HEIGHT / 2) - (PADDLE_HEIGHT / 2);
      else if (!game_over && start && !pause)begin
      if(p2_up_stable && paddle2_pos > TOP_BOUNDARY)
          paddle2_pos <= paddle2_pos - 1;
      else if (p2_down_stable && paddle2_pos < SCREEN_HEIGHT - PADDLE_HEIGHT)
          paddle2_pos <= paddle2_pos + 1;
  end
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
      end else if (!game_over && start && !pause)begin
          // Ball position update
          ball_x <= ball_x + (ball_dir_x ? ball_vel_x : -ball_vel_x);
          ball_y <= ball_y + (ball_dir_y ? ball_vel_y : -ball_vel_y);

          // Ball collision with boundaries
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

// Game Over signal
wire game_over;
assign game_over = (p1_score == 4'd15 || p2_score == 4'd15);



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
        2'b00: current_digit = p2_score % 10;  // Player 2 ones digit 
        2'b01: current_digit = p2_score / 10;  // Player 2 tens digit 
        2'b10: current_digit = p1_score % 10;  // Player 1 ones digit
        2'b11: current_digit = p1_score / 10;  // Player 1 tens digit
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
        default: seg = 7'b1111111; 
    endcase
end

  // Paddle and ball graphics
  wire paddle1_gfx = (hpos < PADDLE_WIDTH) && (vpos >= paddle1_pos) && (vpos < paddle1_pos + PADDLE_HEIGHT);
  wire paddle2_gfx = (hpos >= SCREEN_WIDTH - PADDLE_WIDTH) && (vpos >= paddle2_pos) && (vpos < paddle2_pos + PADDLE_HEIGHT);
  wire ball_gfx = (hpos >= ball_x) && (hpos < ball_x + BALL_SIZE) &&
                  (vpos >= ball_y) && (vpos < ball_y + BALL_SIZE);
                  
                  
wire [7:0] rom_data;         // ROM output for the current row
wire [2:0] rom_addr = vpos - ball_y; // Row offset within the ball
wire [2:0] col_offset = hpos - ball_x; // Column offset within the ball
wire circle_pixel_on;        // Indicates if a pixel is part of the circle


wire [7:0] rom_data;      
wire [2:0] rom_row;        
wire circle_pixel_on;      


wire [5:0] rom_data;     
wire [2:0] rom_row;      
wire circle_pixel_on;      


assign rom_row = vpos - ball_y; 
assign circle_pixel_on = (hpos >= ball_x && hpos < ball_x + BALL_SIZE &&
                          vpos >= ball_y && vpos < ball_y + BALL_SIZE) ?
                          rom_data[5 - (hpos - ball_x)] : 1'b0;

//  circular ROM
circle_rom ball_shape_rom(
    .rom_addr(rom_row),
    .rom_data(rom_data)
);


// Constants for PONG text display
parameter pongTextXStart = 230;  
parameter pongTextXEnd = 383;  
parameter pongTextYStart = 200;
parameter pongTextYEnd = 298; 

// 5x5 bitmap for "PONG" text
reg [4:0] pongTextBitmap [0:19];
initial begin
    pongTextBitmap[0]  = 5'b11110; // P
    pongTextBitmap[1]  = 5'b10010; 
    pongTextBitmap[2]  = 5'b11110; 
    pongTextBitmap[3]  = 5'b10000; 
    pongTextBitmap[4]  = 5'b10000; 
    pongTextBitmap[5]  = 5'b11110; // O
    pongTextBitmap[6]  = 5'b10010; 
    pongTextBitmap[7]  = 5'b10010; 
    pongTextBitmap[8]  = 5'b10010; 
    pongTextBitmap[9]  = 5'b11110; 
    pongTextBitmap[10] = 5'b11110; // N
    pongTextBitmap[11] = 5'b10010; 
    pongTextBitmap[12] = 5'b10010; 
    pongTextBitmap[13] = 5'b10010; 
    pongTextBitmap[14] = 5'b10010; 
    pongTextBitmap[15] = 5'b11110; // G
    pongTextBitmap[16] = 5'b10000; 
    pongTextBitmap[17] = 5'b10110; 
    pongTextBitmap[18] = 5'b10010; 
    pongTextBitmap[19] = 5'b11110;
end

// Text scaling factors
parameter letterWidth = 40;  
parameter letterHeight = 20; 

// Calculating row and column indices
wire [3:0] currentLetterRowIndex = (vpos - pongTextYStart) / letterHeight; 
wire [3:0] currentLetterColumnIndex = (hpos - pongTextXStart) / letterWidth;

// Corrected row data selection for each letter
wire [4:0] currentLetterRowData;
assign currentLetterRowData = pongTextBitmap[
    (currentLetterColumnIndex) * 5 + currentLetterRowIndex  // This directly maps columns 0-3 to the correct letter
];

// Logic for enabling the text display
assign isPongTextOn = (pongTextXStart <= hpos) && (hpos <= pongTextXEnd) &&
                      (pongTextYStart <= vpos) && (vpos <= pongTextYEnd) &&
                      currentLetterRowData[4 - ((hpos - pongTextXStart) % letterWidth) / (letterWidth / 5)];


// Constants for text display
parameter startTextXStart = 230;  
parameter startTextXEnd = 430;   
parameter startTextYStart = 200;
parameter startTextYEnd = 298;   

// 5x5 bitmap for "START" text
reg [4:0] startTextBitmap [0:24];  // Bitmap for 5 letters (S, T, A, R, T), 5 rows each
initial begin
    // S
    startTextBitmap[0]  = 5'b11110; 
    startTextBitmap[1]  = 5'b10000; 
    startTextBitmap[2]  = 5'b11110; 
    startTextBitmap[3]  = 5'b00010; 
    startTextBitmap[4]  = 5'b11110; 

    // T
    startTextBitmap[5]  = 5'b11110; 
    startTextBitmap[6]  = 5'b00100; 
    startTextBitmap[7]  = 5'b00100; 
    startTextBitmap[8]  = 5'b00100; 
    startTextBitmap[9]  = 5'b00100; 

    // A
    startTextBitmap[10] = 5'b11110; 
    startTextBitmap[11] = 5'b10010; 
    startTextBitmap[12] = 5'b11110; 
    startTextBitmap[13] = 5'b10010; 
    startTextBitmap[14] = 5'b10010; 

    // R
    startTextBitmap[15] = 5'b11110; 
    startTextBitmap[16] = 5'b10001; 
    startTextBitmap[17] = 5'b11110; 
    startTextBitmap[18] = 5'b10010; 
    startTextBitmap[19] = 5'b10001; 

    // T
    startTextBitmap[20] = 5'b11111; 
    startTextBitmap[21] = 5'b00100; 
    startTextBitmap[22] = 5'b00100; 
    startTextBitmap[23] = 5'b00100; 
    startTextBitmap[24] = 5'b00100;
end

// Text scaling factors
parameter startLetterWidth = 40;  
parameter startLetterHeight = 20; 

// Calculating row and column indices
wire [3:0] startCurrentLetterRowIndex = (vpos - startTextYStart) / startLetterHeight; 
wire [3:0] startCurrentLetterColumnIndex = (hpos - startTextXStart) / startLetterWidth;

// Corrected row data selection for each letter
wire [4:0] startCurrentLetterRowData;
assign startCurrentLetterRowData = startTextBitmap[
    (startCurrentLetterColumnIndex) * 5 + startCurrentLetterRowIndex  
];

// Logic for enabling the text display
assign isStartTextOn = (startTextXStart <= hpos) && (hpos <= startTextXEnd) &&
                       (startTextYStart <= vpos) && (vpos <= startTextYEnd) &&
                       startCurrentLetterRowData[4 - ((hpos - startTextXStart) % startLetterWidth) / (startLetterWidth / 5)];


// Constants for text display
parameter P1TextXStart = 230;  
parameter P1TextXEnd = 430;   
parameter P1TextYStart = 200;
parameter P1TextYEnd = 298;  


reg [4:0] P1TextBitmap [0:24];  
initial begin
    // P
    P1TextBitmap[0]  = 5'b11110; 
    P1TextBitmap[1]  = 5'b10010; 
    P1TextBitmap[2]  = 5'b11110; 
    P1TextBitmap[3]  = 5'b10000; 
    P1TextBitmap[4]  = 5'b10000; 

    // 1
    P1TextBitmap[5]  = 5'b01100; 
    P1TextBitmap[6]  = 5'b01100; 
    P1TextBitmap[7]  = 5'b00100; 
    P1TextBitmap[8]  = 5'b00100; 
    P1TextBitmap[9]  = 5'b00100; 

    // W
    P1TextBitmap[10] = 5'b10010; 
    P1TextBitmap[11] = 5'b11010; 
    P1TextBitmap[12] = 5'b11110; 
    P1TextBitmap[13] = 5'b10010; 
    P1TextBitmap[14] = 5'b10010; 

    // O
    P1TextBitmap[15] = 5'b11110; 
    P1TextBitmap[16] = 5'b10010; 
    P1TextBitmap[17] = 5'b10010; 
    P1TextBitmap[18] = 5'b10010; 
    P1TextBitmap[19] = 5'b11110; 

    // N
    P1TextBitmap[20] = 5'b10001; 
    P1TextBitmap[21] = 5'b11001; 
    P1TextBitmap[22] = 5'b10101; 
    P1TextBitmap[23] = 5'b10011; 
    P1TextBitmap[24] = 5'b10001;
end

// Text scaling factors
parameter P1LetterWidth = 40;  
parameter P1LetterHeight = 20; 

// Calculating row and column indices
wire [3:0] P1CurrentLetterRowIndex = (vpos - P1TextYStart) / P1LetterHeight; 
wire [3:0] P1CurrentLetterColumnIndex = (hpos - P1TextXStart) / P1LetterWidth;

// Corrected row data selection for each letter
wire [4:0] P1CurrentLetterRowData;
assign P1CurrentLetterRowData = P1TextBitmap[
    (P1CurrentLetterColumnIndex) * 5 + P1CurrentLetterRowIndex 
];

// Logic for enabling the text display
assign isP1TextOn = (p1_score == 4'd15) && (P1TextXStart <= hpos) && (hpos <= P1TextXEnd) &&
                       (P1TextYStart <= vpos) && (vpos <= P1TextYEnd) &&
                       P1CurrentLetterRowData[4 - ((hpos - P1TextXStart) % P1LetterWidth) / (P1LetterWidth / 5)];
                       
                       
// Constants for ext display
parameter P2TextXStart = 230;  
parameter P2TextXEnd = 430;   
parameter P2TextYStart = 200;
parameter P2TextYEnd = 298;   

// 5x5 bitmap for text
reg [4:0] P2TextBitmap [0:24];  
initial begin
    // P
    P2TextBitmap[0]  = 5'b11110; 
    P2TextBitmap[1]  = 5'b10010; 
    P2TextBitmap[2]  = 5'b11110; 
    P2TextBitmap[3]  = 5'b10000; 
    P2TextBitmap[4]  = 5'b10000; 

    // 2
    P2TextBitmap[5]  = 5'b11110; 
    P2TextBitmap[6]  = 5'b00010; 
    P2TextBitmap[7]  = 5'b11100; 
    P2TextBitmap[8]  = 5'b10000; 
    P2TextBitmap[9]  = 5'b11110; 

    // W
    P2TextBitmap[10] = 5'b10010; 
    P2TextBitmap[11] = 5'b11010; 
    P2TextBitmap[12] = 5'b11110; 
    P2TextBitmap[13] = 5'b10010; 
    P2TextBitmap[14] = 5'b10010;  

    // O
    P2TextBitmap[15] = 5'b11110; 
    P2TextBitmap[16] = 5'b10010; 
    P2TextBitmap[17] = 5'b10010; 
    P2TextBitmap[18] = 5'b10010; 
    P2TextBitmap[19] = 5'b11110; 

    // N
    P2TextBitmap[20] = 5'b10001; 
    P2TextBitmap[21] = 5'b11001; 
    P2TextBitmap[22] = 5'b10101; 
    P2TextBitmap[23] = 5'b10011; 
    P2TextBitmap[24] = 5'b10001;
end





// Corrected row data selection for each letter
wire [4:0] P2CurrentLetterRowData;
assign P2CurrentLetterRowData = P2TextBitmap[
    (P1CurrentLetterColumnIndex) * 5 + P1CurrentLetterRowIndex  
];

// Logic for enabling the text display
assign isP2TextOn = (p2_score == 4'd15) &&(P2TextXStart <= hpos) && (hpos <= P2TextXEnd) &&
                       (P2TextYStart <= vpos) && (vpos <= P2TextYEnd) &&
                       P2CurrentLetterRowData[4 - ((hpos - P2TextXStart) % P1LetterWidth) / (P1LetterWidth / 5)];


// Constants for SCORE text display
parameter scoreTextXStart = 270;  
parameter scoreTextXEnd = 370;  
parameter scoreTextYStart = 20;
parameter scoreTextYEnd = 58;  

// 5x5 bitmap for "START" text
reg [4:0] scoreTextBitmap [0:24];  
initial begin
    // S
    scoreTextBitmap[0]  = 5'b11110; 
    scoreTextBitmap[1]  = 5'b10000; 
    scoreTextBitmap[2]  = 5'b11110; 
    scoreTextBitmap[3]  = 5'b00010; 
    scoreTextBitmap[4]  = 5'b11110; 

    // C
    scoreTextBitmap[5]  = 5'b01110; 
    scoreTextBitmap[6]  = 5'b10000; 
    scoreTextBitmap[7]  = 5'b10000; 
    scoreTextBitmap[8]  = 5'b10000; 
    scoreTextBitmap[9]  = 5'b01110; 

    // O
    scoreTextBitmap[10] = 5'b11110; 
    scoreTextBitmap[11] = 5'b10010; 
    scoreTextBitmap[12] = 5'b10010; 
    scoreTextBitmap[13] = 5'b10010; 
    scoreTextBitmap[14] = 5'b11110; 

    // R
    scoreTextBitmap[15] = 5'b11110; 
    scoreTextBitmap[16] = 5'b10010; 
    scoreTextBitmap[17] = 5'b11110; 
    scoreTextBitmap[18] = 5'b10010; 
    scoreTextBitmap[19] = 5'b10010; 

    // E
    scoreTextBitmap[20] = 5'b11110; 
    scoreTextBitmap[21] = 5'b10000; 
    scoreTextBitmap[22] = 5'b11110; 
    scoreTextBitmap[23] = 5'b10000; 
    scoreTextBitmap[24] = 5'b11110;
end

// Text scaling factors
parameter scoreLetterWidth = 20;  
parameter scoreLetterHeight = 8;

// Calculating row and column indices
wire [3:0] scoreCurrentLetterRowIndex = (vpos - scoreTextYStart) / scoreLetterHeight; 
wire [3:0] scoreCurrentLetterColumnIndex = (hpos - scoreTextXStart) / scoreLetterWidth;

//row data selection for each letter
wire [4:0] scoreCurrentLetterRowData;
assign scoreCurrentLetterRowData = scoreTextBitmap[
    (scoreCurrentLetterColumnIndex) * 5 + scoreCurrentLetterRowIndex
];

// Logic for enabling the text display
assign isScoreTextOn = (scoreTextXStart <= hpos) && (hpos <= scoreTextXEnd) &&
                       (scoreTextYStart <= vpos) && (vpos <= scoreTextYEnd) &&
                       scoreCurrentLetterRowData[4 - ((hpos - scoreTextXStart) % scoreLetterWidth) / (scoreLetterWidth / 5)];
                       
wire [11:0] text_rgb;
wire text_on;
  pong_text score_display (
        .clk(clk),
        .dig0(p1_score/10), 
         .dig1(p1_score%10),    // Ones digit of Player 1 score
        .dig2(p2_score/10),   
         .dig3(p2_score%10),   // Tens digit of Player 1 score
        .x(hpos),
        .y(vpos),
        .text_on(text_on),
        .text_rgb(text_rgb)
    );


            
// VGA color logic
assign rgb = (display_on) ? (
    (game_over) ? (isP1TextOn ? 12'b111100001111 : 
                   isP2TextOn ? 12'b111100001111 : 12'b111100000000) : // Game Over
    (!start) ? (isStartTextOn ? 12'b111100000000 : 12'b000000000000) : // Start text
    (text_on) ? text_rgb : // Text RGB or black if no text
    (circle_pixel_on) ? 12'b101011000000 : // Circular ball
    (isPongTextOn) ? 12'b000011110000 : // Green text for "PONG"
    (hpos <= PADDLE_WIDTH && vpos >= paddle1_pos && vpos < paddle1_pos + PADDLE_HEIGHT) ? 12'b010010001010 : // Paddle 1
    (hpos >= SCREEN_WIDTH - PADDLE_WIDTH && vpos >= paddle2_pos && vpos < paddle2_pos + PADDLE_HEIGHT) ? 12'b010010001010 : // Paddle 2
    12'b111111111111 // Background
) : 12'b000000000000; // No display outside active area


endmodule

