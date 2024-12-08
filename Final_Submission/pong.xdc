################################################################################
# Clock Signal
################################################################################
set_property -dict {PACKAGE_PIN W5 IOSTANDARD LVCMOS33} [get_ports clk];  # 100 MHz clock input

################################################################################
# Reset Button
################################################################################
set_property -dict {PACKAGE_PIN U18 IOSTANDARD LVCMOS33} [get_ports reset];  # Reset button (center button)

################################################################################
# Paddle Control Buttons
################################################################################
set_property -dict {PACKAGE_PIN T18 IOSTANDARD LVCMOS33} [get_ports p1_up];    # Player 1 up button (BTN_UP)
set_property -dict {PACKAGE_PIN W19 IOSTANDARD LVCMOS33} [get_ports p1_down];  # Player 1 down button (BTN_DOWN)
set_property -dict {PACKAGE_PIN T17 IOSTANDARD LVCMOS33} [get_ports p2_up];    # Player 2 up button (BTN_LEFT)
set_property -dict {PACKAGE_PIN U17 IOSTANDARD LVCMOS33} [get_ports p2_down];  # Player 2 down button (BTN_RIGHT)


set_property -dict {PACKAGE_PIN V16 IOSTANDARD LVCMOS33} [get_ports pause ]; 
set_property -dict {PACKAGE_PIN R2 IOSTANDARD LVCMOS33} [get_ports start ]; 

################################################################################
# VGA Output Signals
################################################################################
# Red Channel (4 Bits)
set_property -dict {PACKAGE_PIN G19 IOSTANDARD LVCMOS33} [get_ports {rgb[11]}];  # VGA Red MSB
set_property -dict {PACKAGE_PIN H19 IOSTANDARD LVCMOS33} [get_ports {rgb[10]}];
set_property -dict {PACKAGE_PIN J19 IOSTANDARD LVCMOS33} [get_ports {rgb[9]}];
set_property -dict {PACKAGE_PIN K19 IOSTANDARD LVCMOS33} [get_ports {rgb[8]}];

# Green Channel (4 Bits)
set_property -dict {PACKAGE_PIN J17 IOSTANDARD LVCMOS33} [get_ports {rgb[7]}];   # VGA Green MSB
set_property -dict {PACKAGE_PIN H17 IOSTANDARD LVCMOS33} [get_ports {rgb[6]}];
set_property -dict {PACKAGE_PIN G17 IOSTANDARD LVCMOS33} [get_ports {rgb[5]}];
set_property -dict {PACKAGE_PIN D17 IOSTANDARD LVCMOS33} [get_ports {rgb[4]}];

# Blue Channel (4 Bits)
set_property -dict {PACKAGE_PIN N18 IOSTANDARD LVCMOS33} [get_ports {rgb[3]}];   # VGA Blue MSB
set_property -dict {PACKAGE_PIN L18 IOSTANDARD LVCMOS33} [get_ports {rgb[2]}];
set_property -dict {PACKAGE_PIN K18 IOSTANDARD LVCMOS33} [get_ports {rgb[1]}];
set_property -dict {PACKAGE_PIN J18 IOSTANDARD LVCMOS33} [get_ports {rgb[0]}];   # VGA Blue LSB

# VGA Synchronization Signals
set_property -dict {PACKAGE_PIN P19 IOSTANDARD LVCMOS33} [get_ports hsync];      # VGA HSync
set_property -dict {PACKAGE_PIN R19 IOSTANDARD LVCMOS33} [get_ports vsync];      # VGA VSync

set_property -dict {PACKAGE_PIN W7 IOSTANDARD LVCMOS33} [get_ports {seg[0]}]
set_property -dict {PACKAGE_PIN W6 IOSTANDARD LVCMOS33} [get_ports {seg[1]}]
set_property -dict {PACKAGE_PIN U8 IOSTANDARD LVCMOS33} [get_ports {seg[2]}]
set_property -dict {PACKAGE_PIN V8 IOSTANDARD LVCMOS33} [get_ports {seg[3]}]
set_property -dict {PACKAGE_PIN U5 IOSTANDARD LVCMOS33} [get_ports {seg[4]}]
set_property -dict {PACKAGE_PIN V5 IOSTANDARD LVCMOS33} [get_ports {seg[5]}]
set_property -dict {PACKAGE_PIN U7 IOSTANDARD LVCMOS33} [get_ports {seg[6]}]


set_property -dict {PACKAGE_PIN U2 IOSTANDARD LVCMOS33} [get_ports {an[0]}]
set_property -dict {PACKAGE_PIN U4 IOSTANDARD LVCMOS33} [get_ports {an[1]}]
set_property -dict {PACKAGE_PIN V4 IOSTANDARD LVCMOS33} [get_ports {an[2]}]
set_property -dict {PACKAGE_PIN W4 IOSTANDARD LVCMOS33} [get_ports {an[3]}]
