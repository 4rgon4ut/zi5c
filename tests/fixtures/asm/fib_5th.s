.section .text
.global _start

_start:
    addi  t0, zero, 4   # Initialize loop counter for 4 iterations (to get to F(5) from F(1))
    addi  a0, zero, 0   # a0 = F(0) = 0
    addi  a1, zero, 1   # a1 = F(1) = 1

loop:
    beq   t0, zero, end_loop # If counter is zero, we are done

    add   t1, a0, a1    # t1 = F(n-2) + F(n-1)
    addi  a0, a1, 0     # a0 = F(n-1) (current a becomes previous b)
    addi  a1, t1, 0     # a1 = t1 (current b becomes the new sum)

    addi  t0, t0, -1    # Decrement loop counter
    jal   zero, loop    # Unconditional jump back to loop (j loop)

end_loop:
    # The 5th Fibonacci number is now in a1.
    # Standard convention often puts return values in a0.
    addi  a0, a1, 0     # Move result from a1 to a0

_hang:
    jal   zero, _hang   # Infinite loop to halt execution for testing