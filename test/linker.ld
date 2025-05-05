/* test.ld */
OUTPUT_ARCH( "riscv" )
ENTRY(_start)

MEMORY
{
  /* RAM starts at 0x0, size assumed large enough */
  RAM (rwx) : ORIGIN = 0x00000000, LENGTH = 64K
}

SECTIONS
{
  .text :
  {
    *(.text .text.*)   /* Place all text sections */
    . = ALIGN(4);      /* Align before data */
  } > RAM

  .data :
  {
    *(.data .data.*)   /* Place all data sections */
    *(.rodata .rodata.*) /* Place read-only data */
    . = ALIGN(4);
  } > RAM

  /* Note: We don't explicitly handle .bss here for simplicity, */
  /* loadELF usually only copies .text and .data based on program headers */
  /* We'll assume loadELF doesn't need to zero .bss itself */

  /DISCARD/ : { *(.comment) *(.eh_frame*) } /* Discard unnecessary sections */
}