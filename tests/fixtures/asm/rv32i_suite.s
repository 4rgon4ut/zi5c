# rv32i_test_suite.s
#
# A collection of RV32I instructions for testing a CPU simulator.
# After execution, specific registers and memory locations should hold expected values.

.section .data
# Data for load/store tests
data_word:      .word   0x12345678
data_half:      .half   0xABCD
data_byte:      .byte   0xEF
store_target_word: .space 4  # 0x00000000 initially
store_target_half: .space 2  # 0x0000 initially
store_target_byte: .space 1  # 0x00 initially
another_word:   .word   0xAABBCCDD

.section .text
.global _start

_start:
    # --- Initialization ---
    addi  s0, zero, 10      # s0 = 10
    addi  s1, zero, 3       # s1 = 3
    addi  s2, zero, -2      # s2 = -2 (0xFFFFFFFE)
    lui   s3, %hi(0x80000000) # s3 = 0x80000000
    # To load s4 = 0x7FFFFFFF:
    lui   s4, %hi(0x7FFFFFFF) # s4 = 0x80000000 (due to sign ext of lower 12 bits)
    addi  s4, s4, %lo(0x7FFFFFFF) # s4 = 0x80000000 + (-1) = 0x7FFFFFFF
                                  # %lo(0x7FFFFFFF) is -1 (0xFFF sign-extended from 12 bits)

    # --- R-Type Instructions ---
    add   s5, s0, s1
    sub   s6, s0, s1
    sll   s7, s0, s1
    slt   s8, s0, s1
    slt   s9, s1, s0
    sltu  s10, s0, s1
    sltu  s11, s3, s0 # s3 is 0x80000000, s0 is 10. (0x80000000 < 10 unsigned) -> 0
    xor   t3, s0, s1
    srl   t4, s0, s1
    sra   t5, s2, s1
    or    t6, s0, s1
    and   a0, s0, s1


    # --- I-Type ALU Instructions ---
    addi  a1, s0, 5
    slti  a2, s0, 5
    slti  a3, s0, 15
    sltiu a4, s0, 5
    sltiu a5, s0, -1
    xori  a6, s0, 0xF0 # 0xF0 is 240, fits in 12-bit signed
    ori   a7, s0, 0x0F # 0x0F is 15, fits
    andi  s0, s0, 0x5  # s0 is now 0
    slli  s1, s1, 2    # s1 (was 3) is now 12
    srli  s2, s2, 1    # s2 (was -2 / 0xFFFFFFFE) is now 0x7FFFFFFF
    srai  s3, s3, 1    # s3 (was 0x80000000) is now 0xC0000000


    # --- Load Instructions ---
    la    t5, data_word
    lw    t0, 0(t5)
    la    t5, data_half
    lh    t1, 0(t5)
    lhu   t2, 0(t5)
    la    t5, data_byte
    lb    t3, 0(t5)
    lbu   t4, 0(t5)


    # --- Store Instructions ---
    # a0 was 2, a1 was 15 (from ori a7,s0,0x0F then later branch tests overwrite a1)
    # Let's use fixed values for store tests for clarity
    addi  s0, zero, 0       # Ensure s0 is 0 for base address
    addi  a0, zero, 2       # Value to store for word
    addi  a1, zero, 15      # Value to store for half
    addi  a2, zero, 0x42    # Value to store for byte

    la    t5, store_target_word
    sw    a0, 0(t5)
    la    t5, store_target_half
    sh    a1, 0(t5)
    la    t5, store_target_byte
    sb    a2, 0(t5)

    la    t5, store_target_word
    lw    s4, 0(t5)       # s4 should now be 2


    # --- U-Type Instructions ---
    lui   t0, 0xABCDE
    auipc t1, 0x12345


    # --- Branch Instructions ---
    # s0=0, s1=12
    # For branch tests, let's set specific values for clarity
    addi  s0, zero, 5
    addi  s1, zero, 5
    # Expected a0 = 0x1111
    beq   s0, s1, label_beq_taken
    lui   a0, %hi(0xBAD1)         # Should NOT execute
    addi  a0, a0, %lo(0xBAD1)     # Should NOT execute
label_beq_taken:
    lui   a0, %hi(0x1111)
    addi  a0, a0, %lo(0x1111)

    addi  s1, zero, 10
    # Expected a1 = 0x2222
    bne   s0, s1, label_bne_taken
    lui   a1, %hi(0xBAD2)         # Should NOT execute
    addi  a1, a1, %lo(0xBAD2)     # Should NOT execute
label_bne_taken:
    lui   a1, %hi(0x2222)
    addi  a1, a1, %lo(0x2222)

    # s0=5, s1=10
    # Expected a2 = 0x3333
    blt   s0, s1, label_blt_taken
    lui   a2, %hi(0xBAD3)         # Should NOT execute
    addi  a2, a2, %lo(0xBAD3)     # Should NOT execute
label_blt_taken:
    lui   a2, %hi(0x3333)
    addi  a2, a2, %lo(0x3333)

    # Expected a3 = 0x4444
    bge   s1, s0, label_bge_taken
    lui   a3, %hi(0xBAD4)         # Should NOT execute
    addi  a3, a3, %lo(0xBAD4)     # Should NOT execute
label_bge_taken:
    lui   a3, %hi(0x4444)
    addi  a3, a3, %lo(0x4444)

    # Expected a4 = 0x5555
    bltu  s0, s1, label_bltu_taken
    lui   a4, %hi(0xBAD5)         # Should NOT execute
    addi  a4, a4, %lo(0xBAD5)     # Should NOT execute
label_bltu_taken:
    lui   a4, %hi(0x5555)
    addi  a4, a4, %lo(0x5555)

    # Expected a5 = 0x6666
    bgeu  s1, s0, label_bgeu_taken
    lui   a5, %hi(0xBAD6)         # Should NOT execute
    addi  a5, a5, %lo(0xBAD6)     # Should NOT execute
label_bgeu_taken:
    lui   a5, %hi(0x6666)
    addi  a5, a5, %lo(0x6666)


    # --- Jump Instructions ---
    # Expected a6 = 0x7777
    jal   s6, label_jal_target
    lui   a6, %hi(0xBAD7)         # Should be skipped
    addi  a6, a6, %lo(0xBAD7)     # Should be skipped
label_jal_target:
    lui   a6, %hi(0x7777)
    addi  a6, a6, %lo(0x7777)

    # Expected s0 = 0x8888
    la    s7, label_after_jalr
    addi  s7, s7, 4
    jalr  a7, s7, -4        # rd=a7, rs1=s7, imm=-4. pc = (s7 - 4) & ~1 = (label_after_jalr)
    lui   s0, %hi(0xBAD8)   # Should be skipped
    addi  s0, s0, %lo(0xBAD8) # Should be skipped
label_after_jalr:
    lui   s0, %hi(0x8888)
    addi  s0, s0, %lo(0x8888)

_hang:
    jal   zero, _hang       # Infinite loop
