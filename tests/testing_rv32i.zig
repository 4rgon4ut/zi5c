const std = @import("std");
const testing = std.testing;
const zi5c = @import("zi5c");

const VM = zi5c.VM;
const CPU = zi5c.CPU;
const RAM = zi5c.RAM;
const VmError = zi5c.VmError;
const loadELF = zi5c.loadELF;
const rv_abi = zi5c.isa.abi_regs;

// --- UPDATE THESE ADDRESSES FROM YOUR OBJDUMP OUTPUT ---
const SUITE_HANG_ADDRESS: u32 = 0x00000000; // Placeholder for _hang label
const DATA_WORD_ADDR: u32 = 0x00000000; // Placeholder for data_word label
const DATA_HALF_ADDR: u32 = 0x00000000; // Placeholder for data_half label
const DATA_BYTE_ADDR: u32 = 0x00000000; // Placeholder for data_byte label
const STORE_TARGET_WORD_ADDR: u32 = 0x00000000; // Placeholder for store_target_word
const STORE_TARGET_HALF_ADDR: u32 = 0x00000000; // Placeholder for store_target_half
const STORE_TARGET_BYTE_ADDR: u32 = 0x00000000; // Placeholder for store_target_byte
// --- END OF ADDRESSES TO UPDATE ---

test "execute rv32i instruction test suite" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var vm = try VM.init(allocator, 256 * 1024, 4 * 1024);
    defer vm.deinit();

    try vm.loadProgram("tests/fixtures/elf/rv32i_suite.elf");

    try vm.run(1000); // Run for a maximum of 1000 steps

    try testing.expect(vm.cpu.pc == SUITE_HANG_ADDRESS);

    // --- Register Assertions (Expected values from rv32i_test_suite.s comments) ---
    // R-Type results
    try testing.expectEqual(@as(u32, 13), vm.cpu.readReg(rv_abi.REG_S5));
    try testing.expectEqual(@as(u32, 7), vm.cpu.readReg(rv_abi.REG_S6));
    try testing.expectEqual(@as(u32, 80), vm.cpu.readReg(rv_abi.REG_S7));
    try testing.expectEqual(@as(u32, 0), vm.cpu.readReg(rv_abi.REG_S8));
    try testing.expectEqual(@as(u32, 1), vm.cpu.readReg(rv_abi.REG_S9));
    try testing.expectEqual(@as(u32, 0), vm.cpu.readReg(rv_abi.REG_S10));
    try testing.expectEqual(@as(u32, 0), vm.cpu.readReg(rv_abi.REG_S11));
    try testing.expectEqual(@as(u32, 9), vm.cpu.readReg(rv_abi.REG_T3));
    try testing.expectEqual(@as(u32, 1), vm.cpu.readReg(rv_abi.REG_T4));
    try testing.expectEqual(@as(u32, 0xFFFFFFFF), vm.cpu.readReg(rv_abi.REG_T5));
    try testing.expectEqual(@as(u32, 11), vm.cpu.readReg(rv_abi.REG_T6));

    // I-Type ALU results (check registers that aren't heavily overwritten by later stages)
    // Values of a0-a7 are modified by branch tests later.
    // s0 = 0 (after andi s0, s0, 0x5 where s0 was 10)
    // s1 = 12 (after slli s1, s1, 2 where s1 was 3)
    // s2 = 0x7FFFFFFF (after srli s2, s2, 1 where s2 was 0xFFFFFFFE)
    // s3 = 0xC0000000 (after srai s3, s3, 1 where s3 was 0x80000000)
    try testing.expectEqual(@as(u32, 0), vm.cpu.readReg(rv_abi.REG_S0)); // s0 after andi
    try testing.expectEqual(@as(u32, 12), vm.cpu.readReg(rv_abi.REG_S1)); // s1 after slli
    try testing.expectEqual(@as(u32, 0x7FFFFFFF), vm.cpu.readReg(rv_abi.REG_S2)); // s2 after srli
    try testing.expectEqual(@as(u32, 0xC0000000), vm.cpu.readReg(rv_abi.REG_S3)); // s3 after srai

    // Load results
    try testing.expectEqual(@as(u32, 0x12345678), vm.cpu.readReg(rv_abi.REG_T0)); // lw t0
    try testing.expectEqual(@as(u32, 0xFFFFABCD), vm.cpu.readReg(rv_abi.REG_T1)); // lh t1 (t1 was overwritten by AUIPC later)
    try testing.expectEqual(@as(u32, 0x0000ABCD), vm.cpu.readReg(rv_abi.REG_T2)); // lhu t2
    // t3 and t4 get overwritten by R-type ops earlier, then by loads. Final load values:
    try testing.expectEqual(@as(u32, 0xFFFFFFEF), vm.cpu.readReg(rv_abi.REG_T3)); // lb t3
    try testing.expectEqual(@as(u32, 0x000000EF), vm.cpu.readReg(rv_abi.REG_T4)); // lbu t4

    // Store checks (verify memory content)
    // Ensure STORE_TARGET_XXX_ADDR are valid before reading from vm.ram
    if (STORE_TARGET_WORD_ADDR != 0) {
        try testing.expectEqual(@as(u32, 2), try vm.ram.readWord(STORE_TARGET_WORD_ADDR));
    }
    if (STORE_TARGET_HALF_ADDR != 0) {
        try testing.expectEqual(@as(u16, 15), try vm.ram.readHalfWord(STORE_TARGET_HALF_ADDR));
    }
    if (STORE_TARGET_BYTE_ADDR != 0) {
        try testing.expectEqual(@as(u8, 0x42), try vm.ram.readByte(STORE_TARGET_BYTE_ADDR));
    }
    try testing.expectEqual(@as(u32, 2), vm.cpu.readReg(rv_abi.REG_S4)); // s4 after lw from store_target_word

    // U-Type (LUI overwrites t0)
    try testing.expectEqual(@as(u32, 0xABCDE000), vm.cpu.readReg(rv_abi.REG_T0));
    // AUIPC result in t1 depends on PC of AUIPC, harder to make a fixed check without knowing that.
    // Can check if t1 is non-zero if it was zero before, or roughly in an expected range.

    // Branch outcome checks (final values of a0-a5)
    try testing.expectEqual(@as(u32, 0x1111), vm.cpu.readReg(rv_abi.REG_A0));
    try testing.expectEqual(@as(u32, 0x2222), vm.cpu.readReg(rv_abi.REG_A1));
    try testing.expectEqual(@as(u32, 0x3333), vm.cpu.readReg(rv_abi.REG_A2));
    try testing.expectEqual(@as(u32, 0x4444), vm.cpu.readReg(rv_abi.REG_A3));
    try testing.expectEqual(@as(u32, 0x5555), vm.cpu.readReg(rv_abi.REG_A4));
    try testing.expectEqual(@as(u32, 0x6666), vm.cpu.readReg(rv_abi.REG_A5));

    // J-Type & JALR outcome check (final value of s0, and a6/a7 if you want to check link registers)
    try testing.expectEqual(@as(u32, 0x8888), vm.cpu.readReg(rv_abi.REG_S0)); // s0 set after JALR sequence
    try testing.expectEqual(@as(u32, 0x7777), vm.cpu.readReg(rv_abi.REG_A6)); // a6 set in JAL target
    // a7 (JALR's rd) will hold pc_of_jalr + 4. This is PC-dependent.
}
