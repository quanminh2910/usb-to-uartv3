// Define the memory-mapped addresses for your UART peripheral
// (These must match the address decoder in your Verilog)
#define UART_BASE     0x80000000
#define UART_DATA_REG (*(volatile unsigned int*)(UART_BASE + 0x00))
#define UART_STAT_REG (*(volatile unsigned int*)(UART_BASE + 0x04))

// Define the status bits for your simple_uart
#define UART_STAT_RX_VALID (1 << 0)
#define UART_STAT_TX_READY (1 << 1)

// Function to read a character from the UART (blocking)
char uart_getchar() {
    // Wait until the RX_VALID bit is set
    while (!(UART_STAT_REG & UART_STAT_RX_VALID));
    // Read the data
    return (char)UART_DATA_REG;
}

// Function to write a character to the UART (blocking)
void uart_putchar(char c) {
    // Wait until the TX_READY bit is set
    while (!(UART_STAT_REG & UART_STAT_TX_READY));
    // Write the data
    UART_DATA_REG = c;
}

// The main software program
int main() {
    
    // Send a "Hello" message when the RISC-V boots
    const char *hello = "RISC-V Project 6 Booted! Echo is active.\r\n";
    for (int i = 0; hello[i] != '\0'; i++) {
        uart_putchar(hello[i]);
    }

    // Main loop: echo every character received
    while (1) {
        // Read one character from the PC
        char c = uart_getchar();
        
        // Write that character back to the PC
        uart_putchar(c);
    }
}