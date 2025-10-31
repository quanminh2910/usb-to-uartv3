# System Clock (125MHz)
set_property -dict { PACKAGE_PIN H16   IOSTANDARD LVCMOS33 } [get_ports clk_125mhz];
create_clock -period 8.000 -name sys_clk_pin -waveform {0.000 4.000} [get_ports clk_125mhz];

# System Reset (Active Low "SRST" button)
set_property -dict { PACKAGE_PIN C19   IOSTANDARD LVCMOS33 } [get_ports rst_btn];

# Connect your RISC-V's UART to the on-board USB-UART Bridge (Port J14)
set_property -dict { PACKAGE_PIN B18   IOSTANDARD LVCMOS33 } [get_ports uart_rx];
set_property -dict { PACKAGE_PIN A18   IOSTANDARD LVCMOS33 } [get_ports uart_tx];