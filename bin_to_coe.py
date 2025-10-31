import sys
import os

# 1. Check if firmware.bin exists
if not os.path.exists('firmware.bin'):
    print("Error: 'firmware.bin' not found. Run 'make' to compile first.")
    sys.exit(1)

# 2. Read the binary file
with open('firmware.bin', 'rb') as f:
    bindata = f.read()

# 3. Write the .coe file
try:
    with open('firmware.coe', 'w') as f:
        f.write('memory_initialization_radix=16;\n')
        f.write('memory_initialization_vector=\n')
        
        # Process one byte (8-bits) at a time
        for i in range(0, len(bindata)):
            byte = bindata[i]
            hex_byte = f'{byte:02x}' # Format as 2-digit hex (e.g., "0a", "ff")
            
            # Write the hex byte, with a comma or semicolon
            if i + 1 >= len(bindata):
                f.write(hex_byte + ';\n') # Last byte
            else:
                f.write(hex_byte + ',\n') # Not the last byte
                
    print("Successfully created firmware.coe (8-bit entries)")
    sys.exit(0)

except Exception as e:
    print(f"An error occurred: {e}")
    sys.exit(1)