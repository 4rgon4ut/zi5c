# test.s: Simple RISC-V 32-bit Assembly Example

.section .data
# Section for initialized data
message:
    .string "Hello VM!\n" # A null-terminated string
initialized_value:
    .word 42            # A 32-bit initialized word

.section .bss
# Section for uninitialized data (will be zeroed by loader)
    .global uninitialized_value # Make symbol visible globally (optional)
    .align 4                  # Ensure word alignment
uninitialized_value:
    .space 4                  # Reserve 4 bytes (for a 32-bit word)
bss_buffer:
    .space 100                # Reserve 100 bytes

.section .text
# Section for executable code
    .global _start            # Declare entry point symbol globally

_start:
    # The VM's loader should have initialized the stack pointer (sp)
    # before jumping to _start. We don't do it here.

    # --- Example Code ---

    # Load the address of the message string into a0
    # lui loads upper 20 bits, addi loads lower 12 bits (relative to pc or absolute)
    # Using linker relaxation with %hi/%lo is common, or la pseudo-instruction
    la a0, message          # Load address of 'message' into a0 (pseudo-instruction)

    # Simple loop example: decrement a counter
    li t0, 5                # Load immediate value 5 into t0 (counter)
loop_start:
    addi t0, t0, -1         # Decrement counter (t0 = t0 - 1)
    bnez t0, loop_start     # Branch to loop_start if t0 is not zero

    # Access initialized data
    la t1, initialized_value # Load address of initialized_value
    lw t2, 0(t1)            # Load word from address in t1 into t2 (t2 should be 42)

    # Access and modify BSS data
    la t1, uninitialized_value # Load address of uninitialized_value
    sw t2, 0(t1)            # Store the value from t2 (42) into uninitialized_value

    # --- Halt ---
    # Since there's no OS to exit to, loop infinitely
halt:
    j halt                  # Jump to the 'halt' label (infinite loop)

# End of code
