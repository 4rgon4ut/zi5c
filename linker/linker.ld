OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY
{
  RAM (rwx) : ORIGIN = 0x0, LENGTH = 0x100000
}


__stack_top_linker = 0x0 + 0x100000;

SECTIONS
{
  .text :
  {
    *(.text .text.*)
    . = ALIGN(4);
  } > RAM

  .rodata : ALIGN(4)
  {
    *(.rodata .rodata.*)
     . = ALIGN(4);
  } > RAM

  .data : ALIGN(4)
  {
    *(.data .data.*)
    . = ALIGN(4);
  } > RAM

  .bss : ALIGN(4)
  {
    *(.bss .bss.*)
    *(COMMON)
    . = ALIGN(4);
  } > RAM


  _end = .;
  PROVIDE(heap_start_from_linker = _end);

  /DISCARD/ : { *(.comment) *(.eh_frame*) }
}