// Defines constants for RISC-V Application Binary Interface (ABI)
// register names and their numerical indices, based on the ratified
// integer calling convention.

// Type alias for register numbers, reflecting they are 5-bit values
// in the instruction encoding.
pub const RegNum = u5;

// --- Standard RISC-V Integer Register ABI Names ---

// x0: Zero Register (Hardwired to zero)
pub const REG_ZERO: RegNum = 0; // ABI Mnemonic: zero

// x1: Return Address
// Preserved across calls? No (Caller-saved or managed by call instruction)
pub const REG_RA: RegNum = 1; // ABI Mnemonic: ra

// x2: Stack Pointer
// Preserved across calls? Yes (Callee-saved, must be maintained)
pub const REG_SP: RegNum = 2; // ABI Mnemonic: sp

// x3: Global Pointer
// Preserved across calls? Yes (Callee-saved, though often set up by linker/runtime)
// Note: The table says "Unallocatable" which typically means it has a fixed role
// determined by the linkage model and is not for general compiler allocation
// without specific context. It must be preserved by callees if modified.
pub const REG_GP: RegNum = 3; // ABI Mnemonic: gp

// x4: Thread Pointer
// Preserved across calls? Yes (Callee-saved)
// Note: Similar to GP, often "Unallocatable" by default for general use.
pub const REG_TP: RegNum = 4; // ABI Mnemonic: tp

// x5-x7: Temporary Registers (Caller-saved)
// Preserved across calls? No
pub const REG_T0: RegNum = 5; // ABI Mnemonic: t0
pub const REG_T1: RegNum = 6; // ABI Mnemonic: t1
pub const REG_T2: RegNum = 7; // ABI Mnemonic: t2

// x8: Saved Register 0 / Frame Pointer (Callee-saved)
// Preserved across calls? Yes
pub const REG_S0: RegNum = 8; // ABI Mnemonic: s0
pub const REG_FP: RegNum = 8; // ABI Mnemonic: fp (alias for s0)

// x9: Saved Register 1 (Callee-saved)
// Preserved across calls? Yes
pub const REG_S1: RegNum = 9; // ABI Mnemonic: s1

// x10-x17: Argument Registers / Return Value Registers (Caller-saved)
// Preserved across calls? No
pub const REG_A0: RegNum = 10; // ABI Mnemonic: a0 (also for first return value)
pub const REG_A1: RegNum = 11; // ABI Mnemonic: a1 (also for second return value)
pub const REG_A2: RegNum = 12; // ABI Mnemonic: a2
pub const REG_A3: RegNum = 13; // ABI Mnemonic: a3
pub const REG_A4: RegNum = 14; // ABI Mnemonic: a4
pub const REG_A5: RegNum = 15; // ABI Mnemonic: a5
pub const REG_A6: RegNum = 16; // ABI Mnemonic: a6
pub const REG_A7: RegNum = 17; // ABI Mnemonic: a7 (often used for syscall number)

// x18-x27: Saved Registers (Callee-saved)
// Preserved across calls? Yes
pub const REG_S2: RegNum = 18; // ABI Mnemonic: s2
pub const REG_S3: RegNum = 19; // ABI Mnemonic: s3
pub const REG_S4: RegNum = 20; // ABI Mnemonic: s4
pub const REG_S5: RegNum = 21; // ABI Mnemonic: s5
pub const REG_S6: RegNum = 22; // ABI Mnemonic: s6
pub const REG_S7: RegNum = 23; // ABI Mnemonic: s7
pub const REG_S8: RegNum = 24; // ABI Mnemonic: s8
pub const REG_S9: RegNum = 25; // ABI Mnemonic: s9
pub const REG_S10: RegNum = 26; // ABI Mnemonic: s10
pub const REG_S11: RegNum = 27; // ABI Mnemonic: s11

// x28-x31: Temporary Registers (Caller-saved)
// Preserved across calls? No
pub const REG_T3: RegNum = 28; // ABI Mnemonic: t3
pub const REG_T4: RegNum = 29; // ABI Mnemonic: t4
pub const REG_T5: RegNum = 30; // ABI Mnemonic: t5
pub const REG_T6: RegNum = 31; // ABI Mnemonic: t6

pub const REG_LIST: [32]RegNum = .{ REG_ZERO, REG_RA, REG_SP, REG_GP, REG_TP, REG_T0, REG_T1, REG_T2, REG_S0, REG_S1, REG_A0, REG_A1, REG_A2, REG_A3, REG_A4, REG_A5, REG_A6, REG_A7, REG_S2, REG_S3, REG_S4, REG_S5, REG_S6, REG_S7, REG_S8, REG_S9, REG_S10, REG_S11, REG_T3, REG_T4, REG_T5, REG_T6 };

// Helper function to get ABI name string from register index (for debugging/disassembly)
pub fn getAbiName(reg_idx: RegNum) []const u8 {
    return switch (reg_idx) {
        REG_ZERO => "zero",
        REG_RA => "ra",
        REG_SP => "sp",
        REG_GP => "gp",
        REG_TP => "tp",
        REG_T0 => "t0",
        REG_T1 => "t1",
        REG_T2 => "t2",
        REG_S0 => "s0/fp", // or just "s0" or "fp" depending on preference
        REG_S1 => "s1",
        REG_A0 => "a0",
        REG_A1 => "a1",
        REG_A2 => "a2",
        REG_A3 => "a3",
        REG_A4 => "a4",
        REG_A5 => "a5",
        REG_A6 => "a6",
        REG_A7 => "a7",
        REG_S2 => "s2",
        REG_S3 => "s3",
        REG_S4 => "s4",
        REG_S5 => "s5",
        REG_S6 => "s6",
        REG_S7 => "s7",
        REG_S8 => "s8",
        REG_S9 => "s9",
        REG_S10 => "s10",
        REG_S11 => "s11",
        REG_T3 => "t3",
        REG_T4 => "t4",
        REG_T5 => "t5",
        REG_T6 => "t6",
    };
}
