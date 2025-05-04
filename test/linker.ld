/* linker.ld - Simple linker script for RISC-V 32-bit VM */

/* Define the output architecture */
OUTPUT_ARCH(riscv)

/* Define the entry point symbol */
ENTRY(_start)

/* Define the memory layout of the VM */
MEMORY {
  /* RAM starts at address 0x0 (as per user context) */
  /* Define a reasonable length, e.g., 1MB */
  RAM (rwx) : ORIGIN = 0x0, LENGTH = 1M
}

/* Define how sections from input files map to output sections */
SECTIONS {

  /* Place the .text section (code) first in RAM */
  .text : {
    *(.text .text.*)    /* Include all .text sections from input files */
    *(.rodata .rodata.*) /* Include read-only data here too */
    . = ALIGN(4);       /* Align the end of the text section */
  } > RAM /* Specify that this section goes into the RAM region */

  /* Place the .data section (initialized data) after .text */
  .data : {
    *(.data .data.*)    /* Include all .data sections */
    . = ALIGN(4);
  } > RAM

  /* Place the .bss section (uninitialized data) after .data */
  .bss : {
    _bss_start = .;     /* Define a symbol marking the start of .bss */
    *(.bss .bss.*)      /* Include all .bss sections */
    *(COMMON)           /* Include common symbols (also uninitialized) */
    . = ALIGN(4);
    _bss_end = .;       /* Define a symbol marking the end of .bss */
  } > RAM

  /* Define a symbol marking the end of all loaded program data */
  /* This is often used by runtime environments to know where the heap begins */
  _end = .;
  PROVIDE(end = .);

  /* Discard sections we don't need for a simple bare-metal setup */
  /DISCARD/ : {
    *(.eh_frame)
    *(.comment)
  }
}
