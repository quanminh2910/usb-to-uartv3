# --- Makefile for PicoRV32 Firmware (v10 - Uses Python) ---
#
# This Makefile assumes 'riscv64-unknown-elf-gcc' and 'python'
# are in your system's PATH.
#

# 1. Toolchain Configuration
TOOL_PREFIX := riscv64-unknown-elf-
CC = $(TOOL_PREFIX)gcc
OBJCOPY = $(TOOL_PREFIX)objcopy
PYTHON = py

# 2. Project Files
SRC_FILES = main.c
LINKER_SCRIPT = linker.ld
TARGET = firmware

# 3. Compiler Flags
CFLAGS = -march=rv32i -mabi=ilp32 -nostartfiles -T $(LINKER_SCRIPT)

# 4. Build Rules
# Default target
all: $(TARGET).coe

$(TARGET).elf: $(SRC_FILES) $(LINKER_SCRIPT)
	@echo "Compiling..."
	$(CC) $(CFLAGS) -o $@ $(SRC_FILES)

$(TARGET).bin: $(TARGET).elf
	@echo "Copying to binary..."
	$(OBJCOPY) -O binary $< $@

# This rule uses a Python script to create the .coe file
$(TARGET).coe: $(TARGET).bin bin_to_coe.py
	@echo "Converting to COE..."
	$(PYTHON) bin_to_coe.py

# 5. Clean Rule
clean:
	@echo "Cleaning up..."
	-del $(TARGET).elf $(TARGET).bin $(TARGET).coe