/*
 * Linker Script for a simple RISC-V system
 * Running from 64KB of BRAM at address 0x00000000
 */
OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY
{
  /* * RAM starts at 0x00000000 and is 64KB (0x10000) bytes long.
   * (Matches your blk_mem_gen_0 settings) 
   */
  ram (rwx) : ORIGIN = 0x00000000, LENGTH = 64K
}

SECTIONS
{
  .text : {
    *(.text.init)
    *(.text .text.*)
  } > ram

  .data : {
    *(.data .data.*)
    *(.rodata .rodata.*)
  } > ram

  .bss : {
    *(.bss .bss.*)
    *(COMMON)
  } > ram
}