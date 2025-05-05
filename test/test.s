# test.S
.section .text
.global _start

_start:
    # Some identifiable instructions (e.g., ADDI)
    .word 0x00100513  # addi a0, zero, 1
    .word 0x00200593  # addi a1, zero, 2
    .word 0x00b50633  # add a2, a0, a1 (Result should be 3 in a2 if run)
    .word 0xDEADBEEF  # Easily recognizable placeholder data in text

.section .data
    # Some identifiable data
data_start:
    .byte 0x11
    .byte 0x22
    .byte 0x33
    .byte 0x44
    .word 0xCAFEBABE
