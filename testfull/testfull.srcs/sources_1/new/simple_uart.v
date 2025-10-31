/*
 * Module: simple_uart
 * Description: A basic memory-mapped UART transmitter and receiver.
 * (This version fixes a parser error by using
 * explicit comparisons instead of reduction operators)
 *
 * Memory Map (relative to this module's base address):
 * 0x00: UART_DATA_REG (R/W)
 * 0x04: UART_STATUS_REG (Read-Only)
 * - bit 0: rx_data_valid (1 = byte in DATA_REG)
 * - bit 1: tx_ready (1 = ready for new byte to send)
 */
module simple_uart #(
    parameter CLK_FREQ = 100_000_000, // 100 MHz
    parameter BAUD_RATE = 115200
) (
    input  wire        clk,
    input  wire        rstn,

    // --- CPU Memory Bus Interface ---
    input  wire        mem_valid,
    output wire        mem_ready,
    input  wire [31:0] mem_addr,
    input  wire [31:0] mem_wdata,
    input  wire [ 3:0] mem_wstrb, // 4-bit byte-write strobe
    output reg  [31:0] mem_rdata,

    // --- Physical Pins ---
    input  wire        uart_rx,
    output wire        uart_tx
);

    localparam CLK_DIV = (CLK_FREQ + BAUD_RATE / 2) / BAUD_RATE;

    // --- Address and Bus decoding ---
    // Check if the CPU is accessing the Data (0x00) or Status (0x04) register
    wire is_data_reg   = mem_valid && (mem_addr[3:2] == 2'b00); // Addr 0x...0
    wire is_status_reg = mem_valid && (mem_addr[3:2] == 2'b01); // Addr 0x...4

    // A "read" is a valid access with NO write strobes set
    wire is_read  = mem_valid && (mem_wstrb == 4'b0000);
    // A "write" is a valid access with ANY write strobe set
    wire is_write = mem_valid && (mem_wstrb != 4'b0000);

    wire rx_read  = is_read  && is_data_reg;
    wire tx_write = is_write && is_data_reg;
    

    // --- Receiver ---
    reg  [9:0] rx_shreg = 10'h3FF;
    reg  [15:0] rx_countdown = 0;
    reg  [3:0]  rx_bit_count = 0;
    reg         rx_data_valid = 1'b0;
    reg  [7:0]  rx_data_reg = 8'h00;
    
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            rx_shreg <= 10'h3FF;
            rx_countdown <= 0;
            rx_bit_count <= 0;
            rx_data_valid <= 1'b0;
            rx_data_reg <= 8'h00;
        end else begin
            // Clear valid flag on CPU read
            if (rx_read && mem_ready) begin
                rx_data_valid <= 1'b0;
            end
            
            if (rx_countdown > 0) begin
                rx_countdown <= rx_countdown - 1;
            end else begin
                // Shift in the RX bit
                rx_shreg <= {uart_rx, rx_shreg[9:1]};
                
                if (rx_bit_count > 0) begin
                    // We are in the middle of a byte
                    if (rx_countdown == 0) begin
                        rx_countdown <= CLK_DIV - 1;
                        rx_bit_count <= rx_bit_count - 1;
                        if (rx_bit_count == 1) begin
                            // This is the last bit (stop bit)
                            rx_data_valid <= 1'b1;
                            rx_data_reg   <= rx_shreg[8:1];
                        end
                    end
                end else begin
                    // Waiting for a start bit
                    if (rx_shreg[0] == 1'b0) begin // Start bit detected
                        rx_countdown <= (CLK_DIV / 2) - 1; // Wait half a bit
                        rx_bit_count <= 9; // 8 data + 1 stop
                    end
                end
            end
        end
    end

    // --- Transmitter ---
    reg  [9:0] tx_shreg = 10'h3FF;
    reg  [15:0] tx_countdown = 0;
    reg  [3:0]  tx_bit_count = 0;
    reg         tx_busy = 1'b0;
    
    wire tx_ready = !tx_busy;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            tx_shreg <= 10'h3FF;
            tx_countdown <= 0;
            tx_bit_count <= 0;
            tx_busy <= 1'b0;
        end else begin
            if (tx_countdown > 0) begin
                tx_countdown <= tx_countdown - 1;
            end else if (tx_bit_count > 0) begin
                tx_shreg <= {1'b1, tx_shreg[9:1]};
                tx_countdown <= CLK_DIV - 1;
                tx_bit_count <= tx_bit_count - 1;
                if (tx_bit_count == 1) begin
                    tx_busy <= 1'b0; // Done
                end
            end else if (tx_write && tx_ready) begin
                // New byte from CPU
                tx_shreg <= {mem_wdata[7:0], 1'b0, 1'b1}; // data + start + idle
                tx_countdown <= CLK_DIV - 1;
                tx_bit_count <= 10; // 1 start + 8 data + 1 stop
                tx_busy <= 1'b1;
            end
        end
    end
    
    assign uart_tx = tx_shreg[0];

    // --- Memory Interface ---
    assign mem_ready = 1'b1; // This simple UART is always ready
    
    always @(*) begin
        if (is_status_reg) begin // Status Register (Addr 0x...4)
            mem_rdata = {30'b0, tx_ready, rx_data_valid};
        end else begin // Data Register (Addr 0x...0)
            mem_rdata = {24'b0, rx_data_reg};
        end
    end

endmodule