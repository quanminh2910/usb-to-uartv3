`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/31/2025 01:03:08 PM
// Design Name: 
// Module Name: project_top
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


/*
 * Module: project_top
 * Description: Top-level module for the Arty Z7 RISC-V system.
 * Connects the clock wizard and the RISC-V system to
 * the board's physical pins.
 */
/*
  * Module: project_top (Corrected Version)
  * Description: Top-level module for the Arty Z7 RISC-V system.
  * Connects the clock wizard and the RISC-V system to
  * the board's physical pins.
  */
 module project_top (
     // --- System Inputs (from Arty Z7 board) ---
     input  wire        clk_125mhz,     // Arty Z7 125MHz oscillator
     input  wire        rst_btn,        // Arty Z7 "SRST" button (active low)
 
     // --- On-board Debug UART (to Arty Z7 Port J14) ---
     output wire        uart_tx,
     input  wire        uart_rx
 );
 
     // --- Internal Wires ---
     wire clk_100mhz; // Clock for the entire RISC-V system
     wire locked;     // From Clock Wizard, signals clock is stable
     
     // Create an active-HIGH reset for our system
     // It's high only if the button is pressed AND the clock is locked
     wire rstn = rst_btn & locked; 
 
 
     // --- 1. Instantiate Clock Wizard ---
     // (This must match the Component Name you gave your IP)
     clk_wiz_0 u_clk_wiz (
        .clk_in1 (clk_125mhz),  // Input 125MHz
        .clk_out1(clk_100mhz), // Output 100MHz for CPU
        .locked  (locked)
        // .reset port is not needed for this simple setup
     );
 
     
     // --- 2. Instantiate the RISC-V System ---
     // This is the module that contains your PicoRV32, BRAM,
     // and simple_uart peripheral.
     riscv_system u_riscv_system (
         .clk            (clk_100mhz),    // Give it the 100MHz clock
         .rstn           (rstn),          // Give it the active-high reset
         
         // Connect its UART ports to the top-level pins
         .debug_uart_tx  (uart_tx),
         .debug_uart_rx  (uart_rx)
     );
 
 endmodule
