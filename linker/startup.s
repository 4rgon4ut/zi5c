.section .rodata
    msg_pre_main: .string "Hello from zi5c!\n"

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
    la   a1, msg_pre_main # a1 = address of "Hello from zi5c!\n"
    li   a2, 19           # a2 = length of "Hello from zi5c!\n" (18 chars + newline)
    li   a0, 1            # a0 = 1 (stdout file descriptor)
    li   a7, 64           # a7 = 64 (syscall_write)
    ecall

    call main

.L_exit:
    li   a0, 0     # Set exit code to 0 (success)
    li   a7, 93    # Set syscall number for exit (93)
    ecall          # Trigger the exit syscall

.L_halt:
    j    .L_halt