
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
    # Load some initial values into registers
    # s0 (x8) will hold 10
    # s1 (x9) will hold 3
    # s2 (x18) will hold -2 (0xFFFFFFFE)
    # s3 (x19) will hold 0x80000000 (for signed comparisons)
    # s4 (x20) will hold 0x7FFFFFFF (for signed comparisons)

    addi  s0, zero, 10      # s0 = 10
    addi  s1, zero, 3       # s1 = 3
    addi  s2, zero, -2      # s2 = -2 (0xFFFFFFFE)
    lui   s3, %hi(0x80000000) # s3 = 0x80000000 (most negative i32 if lower bits are 0)
    lui   s4, %hi(0x7FFFF000) # s4 = 0x7FFFF000
    addi  s4, s4, 0xFFF     # s4 = 0x7FFFFFFF (most positive i32)


    # --- R-Type Instructions ---
    # Results will be stored in s5-s11, t3-t6
    # s5 = s0 + s1 = 10 + 3 = 13
    add   s5, s0, s1
    # s6 = s0 - s1 = 10 - 3 = 7
    sub   s6, s0, s1
    # s7 = s0 << s1 (10 << 3) = 80 (0x50)
    sll   s7, s0, s1
    # s8 = (s0 < s1 signed) ? 1 : 0  (10 < 3) -> 0
    slt   s8, s0, s1
    # s9 = (s1 < s0 signed) ? 1 : 0  (3 < 10) -> 1
    slt   s9, s1, s0
    # s10 = (s0 < s1 unsigned) ? 1 : 0 (10 < 3) -> 0
    sltu  s10, s0, s1
    # s11 = (s3 < s0 unsigned) ? 1 : 0 (0x80000000 < 10) -> 0
    sltu  s11, s3, s0
    # t3 = s0 ^ s1 = 10 ^ 3 = 0b1010 ^ 0b0011 = 0b1001 = 9
    xor   t3, s0, s1
    # t4 = s0 >> s1 (logical) (10 >> 3) = 0b1010 >> 3 = 0b001 = 1
    srl   t4, s0, s1
    # t5 = s2 >> s1 (arithmetic) (-2 >> 3) = 0xFFFFFFFE >> 3 = 0xFFFFFFFF = -1
    sra   t5, s2, s1
    # t6 = s0 | s1 = 10 | 3 = 0b1010 | 0b0011 = 0b1011 = 11
    or    t6, s0, s1
    # a0 = s0 & s1 = 10 & 3 = 0b1010 & 0b0011 = 0b0010 = 2
    and   a0, s0, s1


    # --- I-Type ALU Instructions ---
    # Results in a1-a7
    # a1 = s0 + 5 = 10 + 5 = 15
    addi  a1, s0, 5
    # a2 = (s0 < 5 signed) ? 1 : 0 (10 < 5) -> 0
    slti  a2, s0, 5
    # a3 = (s0 < 15 signed) ? 1 : 0 (10 < 15) -> 1
    slti  a3, s0, 15
    # a4 = (s0 < 5 unsigned) ? 1 : 0 (10 < 5) -> 0
    sltiu a4, s0, 5
    # a5 = (s0 < 0xFFFFFFFF unsigned) ? 1 : 0 (10 < large_num) -> 1
    sltiu a5, s0, -1 # -1 is 0xFFFFFFFF as unsigned
    # a6 = s0 ^ 0xF0 = 10 ^ 240 = 0xA ^ 0xF0 = 0xFA = 250
    xori  a6, s0, 0xF0
    # a7 = s0 | 0x0F = 10 | 15 = 0xA | 0xF = 0xF = 15
    ori   a7, s0, 0x0F
    # s0 = s0 & 0x5 = 10 & 5 = 0xA & 0x5 = 0x0 = 0
    andi  s0, s0, 0x5 # s0 is now 0 for subsequent tests
    # s1 = s1 << 2 = 3 << 2 = 12 (shamt from immediate)
    slli  s1, s1, 2   # s1 is now 12
    # s2 = 0xFFFFFFFE >> 1 (logical) = 0x7FFFFFFF
    srli  s2, s2, 1   # s2 is now 0x7FFFFFFF
    # s3 = 0x80000000 >> 1 (arithmetic) = 0xC0000000
    srai  s3, s3, 1   # s3 is now 0xC0000000


    # --- Load Instructions ---
    # Results in t0, t1, t2, t3, t4
    la    t5, data_word   # t5 = address of data_word
    lw    t0, 0(t5)       # t0 = 0x12345678 (data_word)
    lh    t1, 2(t5)       # t1 = 0xFFFF5678 (sign-extended data_word[31:16]) (assuming data_word is at addr X, data_half at X+4)
                          # Let's load from data_half directly for clarity
    la    t5, data_half
    lh    t1, 0(t5)       # t1 = 0xFFFFABCD (sign-extended data_half)
    lhu   t2, 0(t5)       # t2 = 0x0000ABCD (zero-extended data_half)
    la    t5, data_byte
    lb    t3, 0(t5)       # t3 = 0xFFFFFFEF (sign-extended data_byte)
    lbu   t4, 0(t5)       # t4 = 0x000000EF (zero-extended data_byte)


    # --- Store Instructions ---
    # Store values from a0, a1, a2 into memory
    # a0 was 2, a1 was 15, a2 was 0 (from SLTI)
    # We'll use s0 (which is 0) as base for simplicity
    addi  s0, zero, 0       # Ensure s0 is 0
    la    t5, store_target_word
    sw    a0, 0(t5)       # store_target_word should become 2
    la    t5, store_target_half
    sh    a1, 0(t5)       # store_target_half should become 0x000F (15)
    la    t5, store_target_byte
    addi  a2, zero, 0x42    # a2 = 0x42
    sb    a2, 0(t5)       # store_target_byte should become 0x42

    # Verify one store by loading it back
    la    t5, store_target_word
    lw    s4, 0(t5)       # s4 should now be 2


    # --- U-Type Instructions ---
    # LUI: t0 = 0xABCDE000
    lui   t0, 0xABCDE
    # AUIPC: t1 = pc + 0x12345000
    # Current PC will be address of AUIPC. Let's assume it's X.
    # t1 = X + 0x12345000
    auipc t1, 0x12345
    # To make AUIPC result predictable for testing, store PC then AUIPC
    # This is a bit tricky without knowing exact PC.
    # For now, t1 will hold pc_of_auipc + 0x12345000.

    # --- Branch Instructions ---
    # We'll use s0 (0) and s1 (12)
    addi  s0, zero, 5
    addi  s1, zero, 5
    beq   s0, s1, label_beq_taken # Should be taken (5 == 5)
    addi  a0, zero, 0xBAD1        # Should NOT execute
label_beq_taken:
    addi  a0, zero, 0x1111        # a0 = 0x1111

    addi  s1, zero, 10
    bne   s0, s1, label_bne_taken # Should be taken (5 != 10)
    addi  a1, zero, 0xBAD2        # Should NOT execute
label_bne_taken:
    addi  a1, zero, 0x2222        # a1 = 0x2222

    # s0=5, s1=10
    blt   s0, s1, label_blt_taken # Should be taken (5 < 10 signed)
    addi  a2, zero, 0xBAD3        # Should NOT execute
label_blt_taken:
    addi  a2, zero, 0x3333        # a2 = 0x3333

    bge   s1, s0, label_bge_taken # Should be taken (10 >= 5 signed)
    addi  a3, zero, 0xBAD4        # Should NOT execute
label_bge_taken:
    addi  a3, zero, 0x4444        # a3 = 0x4444

    # s0=5, s1=10
    bltu  s0, s1, label_bltu_taken # Should be taken (5 < 10 unsigned)
    addi  a4, zero, 0xBAD5         # Should NOT execute
label_bltu_taken:
    addi  a4, zero, 0x5555         # a4 = 0x5555

    bgeu  s1, s0, label_bgeu_taken # Should be taken (10 >= 5 unsigned)
    addi  a5, zero, 0xBAD6         # Should NOT execute
label_bgeu_taken:
    addi  a5, zero, 0x6666         # a5 = 0x6666


    # --- Jump Instructions ---
    # JAL: ra = pc_of_jal+4, pc = label_jal_target
    # We'll store the return address in s6
    jal   s6, label_jal_target
    addi  a6, zero, 0xBAD7        # Should be skipped
label_jal_target:
    addi  a6, zero, 0x7777        # a6 = 0x7777 (s6 should hold addr of this line + 4 if JAL was to here)

    # JALR: t0 = pc_of_jalr+4, pc = (s6 + offset_for_jalr) & ~1
    # Let s6 hold the address of 'label_after_jalr'
    # Calculate offset: label_after_jalr - (address of JALR + some_small_offset_in_s6)
    # For simplicity, let's make s6 point directly to where we want to jump + an offset
    # and use a0 as rd.
    la    s7, label_after_jalr
    addi  s7, s7, 4         # Add a small offset to test immediate
                            # s7 now points to label_after_jalr + 4
    jalr  a7, s7, -4        # rd=a7, rs1=s7, imm=-4. pc = (s7 - 4) & ~1 = (label_after_jalr)
                            # a7 = pc_of_jalr + 4
    addi  s0, zero, 0xBAD8  # Should be skipped
label_after_jalr:
    addi  s0, zero, 0x8888  # s0 = 0x8888

_hang:
    jal   zero, _hang       # Infinite loop
