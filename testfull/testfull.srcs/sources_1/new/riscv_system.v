/*
 * Module: riscv_system
 * Description: Combines PicoRV32, RAM, Debug UART, and USB Bridge.
 *
 * Memory Map:
 * 0x0000_0000 - 0x0000_FFFF : 64KB Block RAM (for code and data)
 * 0x8000_0000 - 0x8000_000F : simple_uart (for debug printf)
 * 0x8000_0010 - 0x8000_001F : riscv_usb_bridge (for Project 6)
 */
/*
 * Module: riscv_system (Corrected Version)
 * Description: Combines PicoRV32, RAM, and one Debug UART.
 *
 * Memory Map:
 * 0x0000_0000 - 0x0000_FFFF : 64KB Block RAM (for code and data)
 * 0x8000_0000 - 0x8000_000F : simple_uart (for debug printf)
 */
module riscv_system (
    input  wire        clk,    // System clock (e.g., 100MHz)
    input  wire        rstn,   // Active-high reset

    // --- Debug UART Pins (to Arty J14) ---
    output wire        debug_uart_tx,
    input  wire        debug_uart_rx
);

    // --- PicoRV32 Memory Bus ---
    wire        mem_valid;
    wire        mem_ready;
    wire [ 3:0] mem_wstrb;
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [31:0] mem_rdata;

    // --- Peripheral Selection (Address Decoder) ---
    // RAM is at 0x0000_0000
    wire mem_sel_ram  = mem_valid && (mem_addr[31:16] == 16'h0000);
    // UART is at 0x8000_0000
    wire mem_sel_uart = mem_valid && (mem_addr[31:16] == 16'h8000); 

    // --- Peripheral Ready Signals ---
    reg         ram_ready_reg;
    wire        uart_ready;
    
    // --- Peripheral Read Data ---
    wire [31:0] ram_rdata;
    wire [31:0] uart_rdata;

    // --- Instantiate PicoRV32 ---
    picorv32 #(
        .ENABLE_MUL(1),
        .ENABLE_DIV(1),
        .BARREL_SHIFTER(1),
        .COMPRESSED_ISA(1)
    ) u_cpu (
        .clk         (clk),
        .resetn      (rstn),
        .mem_valid   (mem_valid),
        .mem_ready   (mem_ready),
        .mem_wstrb   (mem_wstrb),
        .mem_addr    (mem_addr),
        .mem_wdata   (mem_wdata),
        .mem_rdata   (mem_rdata),
        .trap        () 
        // Connect other IRQ ports to 1'b0
    );

    // --- Bus Multiplexing ---
    
    // 1. mem_ready logic:
    // We add one cycle of wait-state for BRAM reads
    always @(posedge clk or negedge rstn) begin
        if (!rstn)
            ram_ready_reg <= 1'b0;
        else
            ram_ready_reg <= mem_sel_ram && mem_valid;
    end
    
    assign mem_ready = (mem_sel_ram)  ? ram_ready_reg  :
                       (mem_sel_uart) ? uart_ready     :
                       1'b0; // Default to not ready

    // 2. mem_rdata logic:
    assign mem_rdata = mem_sel_ram  ? ram_rdata  :
                       mem_sel_uart ? uart_rdata :
                       32'h0;

    // --- 1. Instantiate Block Memory (blk_mem_gen_0) ---
    // (This is the IP you configured)
    blk_mem_gen_0 u_ram (
        .clka  (clk),
        .ena   (mem_sel_ram && mem_valid), // Enable RAM on valid access
        .wea   (mem_wstrb),                // Connect byte-write strobe
        .addra (mem_addr[15:2]),           // Convert byte-address (32-bit) to word-address (32-bit)
        .dina  (mem_wdata),
        .douta (ram_rdata)
    );

    // --- 2. Instantiate Debug UART (simple_uart) ---
    simple_uart #(
        .CLK_FREQ(100_000_000) // Assuming a 100MHz system clock
    ) u_debug_uart (
        .clk         (clk),
        .rstn        (rstn),
        .mem_valid   (mem_sel_uart),
        .mem_ready   (uart_ready),
        .mem_addr    (mem_addr),
        .mem_wdata   (mem_wdata),
        .mem_wstrb   (mem_wstrb),
        .mem_rdata   (uart_rdata),
        .uart_rx     (debug_uart_rx),
        .uart_tx     (debug_uart_tx)
    );

endmodule