OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY {
  RAM (rwx) : ORIGIN = 0x0, LENGTH = __RAM_LENGTH__
}

SECTIONS {
  .text : ALIGN(4) {
    *(.text.init)
    *(.text .text.*)
  } > RAM

  .rodata : ALIGN(4) {
    *(.rodata .rodata.*)
  } > RAM

  .data : ALIGN(4) {
    *(.data .data.*)
  } > RAM

  .bss : ALIGN(4) {
    __bss_start = .;
    *(.bss .bss.*)
    *(COMMON)
    . = ALIGN(4);
    __bss_end = .;
  } > RAM

  _end = .;

  /DISCARD/ : { *(.comment) *(.eh_frame*) }
}