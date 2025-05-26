.section .text.init
.global _start
.type _start, @function
.align 2

_start:
    la   a0, __bss_start
    la   a1, __bss_end

.L_bss_zero_loop: // its a good practice to explicitly zero the bss section
    beq  a0, a1, .L_bss_zero_done
    sw   zero, 0(a0)
    addi a0, a0, 4
    j    .L_bss_zero_loop

.L_bss_zero_done:
    call main

.L_halt:
    j    .L_halt