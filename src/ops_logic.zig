const std = @import("std");
const CPU = @import("cpu.zig").CPU;

// --- I-Type Execution Functions ---

pub const I_OP = *const fn (
    cpu: *CPU,
    rd: u5,
    rs1: u5,
    imm: i32,
) anyerror!void;

// --- OP-IMM Instructions (Opcode 0x13) ---

/// Executes ADDI (Add Immediate) instruction: rd = rs1 + sign_extend(imm)
pub fn ADDI(cpu: *CPU, rd: u5, rs1: u5, imm: i32) !void {
    const val = cpu.readReg(rs1);
    const imm_u32 = @as(u32, @bitCast(imm));
    cpu.writeReg(rd, val +% imm_u32);
    cpu.pc +%= 4;
}

/// Executes SLTI (Set Less Than Immediate) instruction: rd = (rs1 < imm) ? 1 : 0 (signed comparison)
pub fn SLTI(cpu: *CPU, rd: u5, rs1: u5, imm: i32) !void {
    const val = cpu.readReg(rs1);
    const val_signed = @as(i32, @bitCast(val));
    const result: u32 = if (val_signed < imm) 1 else 0;
    cpu.writeReg(rd, result);
    cpu.pc +%= 4;
}

/// Executes SLTIU (Set Less Than Immediate Unsigned) instruction: rd = (rs1 < imm) ? 1 : 0 (unsigned comparison)
pub fn SLTIU(cpu: *CPU, rd: u5, rs1: u5, imm: i32) !void {
    const val = cpu.readReg(rs1);
    const imm_u32 = @as(u32, @bitCast(imm));
    cpu.writeReg(rd, if (val < imm_u32) 1 else 0);
    cpu.pc +%= 4;
}

/// Executes XORI (XOR Immediate) instruction: rd = rs1 ^ sign_extend(imm)
pub fn XORI(cpu: *CPU, rd: u5, rs1: u5, imm: i32) !void {
    const val = cpu.readReg(rs1);
    const imm_u32 = @as(u32, @bitCast(imm));
    cpu.writeReg(rd, val ^ imm_u32);
    cpu.pc +%= 4;
}

/// Executes ORI (OR Immediate) instruction: rd = rs1 | sign_extend(imm)
pub fn ORI(cpu: *CPU, rd: u5, rs1: u5, imm: i32) !void {
    const val = cpu.readReg(rs1);
    const imm_u32 = @as(u32, @bitCast(imm));
    cpu.writeReg(rd, val | imm_u32);
    cpu.pc +%= 4;
}

/// Executes ANDI (AND Immediate) instruction: rd = rs1 & sign_extend(imm)
pub fn ANDI(cpu: *CPU, rd: u5, rs1: u5, imm: i32) !void {
    const val = cpu.readReg(rs1);
    const imm_u32 = @as(u32, @bitCast(imm));
    cpu.writeReg(rd, val & imm_u32);
    cpu.pc +%= 4;
}

/// Executes SLLI (Shift Left Logical Immediate) instruction: rd = rs1 << shamt
/// Note: shamt is the lower 5 bits of imm.
pub fn SLLI(cpu: *CPU, rd: u5, rs1: u5, imm: i32) !void {
    const val = cpu.readReg(rs1);
    const shamt = @as(u5, @intCast(imm & 0x1F)); // lower 5 bits
    cpu.writeReg(rd, val << shamt);
    cpu.pc +%= 4;
}

/// Executes SRLI (Shift Right Logical Immediate) instruction: rd = rs1 >> shamt (logical shift)
/// Note: shamt is the lower 5 bits of imm. Requires funct7 check in dispatcher.
pub fn SRLI(cpu: *CPU, rd: u5, rs1: u5, imm: i32) !void {
    const val = cpu.readReg(rs1);
    const shamt = @as(u5, @intCast(imm & 0x1F));
    cpu.writeReg(rd, val >> shamt);
    cpu.pc +%= 4;
}

/// Executes SRAI (Shift Right Arithmetic Immediate) instruction: rd = rs1 >> shamt (arithmetic shift)
/// Note: shamt is the lower 5 bits of imm. Requires funct7 check in dispatcher.
pub fn SRAI(cpu: *CPU, rd: u5, rs1: u5, imm: i32) !void {
    const val = cpu.readReg(rs1);
    const shamt = @as(u5, @intCast(imm & 0x1F));
    cpu.writeReg(rd, @as(u32, @bitCast(@as(i32, @bitCast(val)) >> shamt)));
    cpu.pc +%= 4;
}

// --- LOAD Instructions (Opcode 0x03) ---

/// Executes LB (Load Byte) instruction: rd = sign_extend(memory[rs1 + offset])
pub fn LB(cpu: *CPU, rd: u5, rs1: u5, imm: i32) !void {
    const base_addr = cpu.readReg(rs1);
    const offset = @as(u32, @bitCast(imm));
    const mem_addr = base_addr +% offset;
    const byte_val = try cpu.ram.readByte(mem_addr);

    const signed_byte = @as(i8, @bitCast(byte_val)); // Reinterpret u8 bits as i8
    const result = @as(u32, @bitCast(@as(i32, signed_byte))); // Sign-extend i8 to i32, then bitcast to u32

    cpu.writeReg(rd, result);
    cpu.pc +%= 4;
}

/// Executes LH (Load Half-word) instruction: rd = sign_extend(memory[rs1 + offset])
pub fn LH(cpu: *CPU, rd: u5, rs1: u5, imm: i32) !void {
    const base_addr = cpu.readReg(rs1);
    const offset = @as(u32, @bitCast(imm));
    const mem_addr = base_addr +% offset;
    const half_val = try cpu.ram.readHalfWord(mem_addr);

    const signed_half = @as(i16, @bitCast(half_val)); // Reinterpret u16 bits as i16
    const result = @as(u32, @bitCast(@as(i32, signed_half))); // Sign-extend i16 to i32, then bitcast to u32

    cpu.writeReg(rd, result);
    cpu.pc +%= 4;
}

/// Executes LW (Load Word) instruction: rd = memory[rs1 + offset]
pub fn LW(cpu: *CPU, rd: u5, rs1: u5, imm: i32) !void {
    const base_addr = cpu.readReg(rs1);
    const offset = @as(u32, @bitCast(imm));
    const mem_addr = base_addr +% offset;
    const word_val = try cpu.ram.readWord(mem_addr);
    cpu.writeReg(rd, word_val);
    cpu.pc +%= 4;
}

/// Executes LBU (Load Byte Unsigned) instruction: rd = zero_extend(memory[rs1 + offset])
pub fn LBU(cpu: *CPU, rd: u5, rs1: u5, imm: i32) !void {
    const base_addr = cpu.readReg(rs1);
    const offset = @as(u32, @bitCast(imm));
    const mem_addr = base_addr +% offset;
    const byte_val = try cpu.ram.readByte(mem_addr);
    const result = @as(u32, byte_val);
    cpu.writeReg(rd, result);
    cpu.pc +%= 4;
}

/// Executes LHU (Load Half-word Unsigned) instruction: rd = zero_extend(memory[rs1 + offset])
pub fn LHU(cpu: *CPU, rd: u5, rs1: u5, imm: i32) !void {
    const base_addr = cpu.readReg(rs1);
    const offset = @as(u32, @bitCast(imm));
    const mem_addr = base_addr +% offset;
    const half_val = try cpu.ram.readHalfWord(mem_addr);
    const result = @as(u32, half_val);
    cpu.writeReg(rd, result);
    cpu.pc +%= 4;
}

/// Executes JALR (Jump and Link Register) instruction: rd = pc + 4; pc = (rs1 + imm) & ~1
pub fn JALR(cpu: *CPU, rd: u5, rs1: u5, imm: i32) !void {
    const val = cpu.readReg(rs1);
    const imm_u32 = @as(u32, @bitCast(imm));
    const target_addr = (val +% imm_u32) & (~@as(u32, 1));
    const return_addr = cpu.pc +% 4;
    cpu.writeReg(rd, return_addr);
    cpu.pc = target_addr;
}

// SYSTEM Instructions (Opcode 0x73)

pub fn ECALL(cpu: *CPU, rd: u5, rs1: u5, imm: i32) !void {
    _ = rd; // autofix
    _ = rs1; // autofix
    _ = imm; // autofix

    cpu.pc +%= 4; // Move to next instruction
}

pub fn EBREAK(cpu: *CPU, rd: u5, rs1: u5, imm: i32) !void {
    _ = cpu; // autofix
    _ = rd; // autofix
    _ = rs1; // autofix
    _ = imm; // autofix

}

// --- R-Type Execution Functions (Opcode 0x33) ---

pub const R_OP = *const fn (
    cpu: *CPU,
    rd: u5,
    rs1: u5,
    rs2: u5,
) anyerror!void;

/// Executes ADD instruction: rd = rs1 + rs2
pub fn ADD(cpu: *CPU, rd: u5, rs1: u5, rs2: u5) !void {
    const val_rs1 = cpu.readReg(rs1);
    const val_rs2 = cpu.readReg(rs2);
    cpu.writeReg(rd, val_rs1 +% val_rs2);
    cpu.pc +%= 4;
}

/// Executes SUB instruction: rd = rs1 - rs2
pub fn SUB(cpu: *CPU, rd: u5, rs1: u5, rs2: u5) !void {
    const val_rs1 = cpu.readReg(rs1);
    const val_rs2 = cpu.readReg(rs2);
    cpu.writeReg(rd, val_rs1 -% val_rs2); // Wrapping sub
    cpu.pc +%= 4;
}

/// Executes SLL (Shift Left Logical) instruction: rd = rs1 << (rs2[4:0])
pub fn SLL(cpu: *CPU, rd: u5, rs1: u5, rs2: u5) !void {
    const val_rs1 = cpu.readReg(rs1);
    const val_rs2 = cpu.readReg(rs2);
    const shamt = @as(u5, @truncate(val_rs2)); // Shift amount is lower 5 bits of rs2
    cpu.writeReg(rd, val_rs1 << shamt);
    cpu.pc +%= 4;
}

/// Executes SLT (Set Less Than) instruction: rd = (rs1 < rs2) ? 1 : 0 (signed)
pub fn SLT(cpu: *CPU, rd: u5, rs1: u5, rs2: u5) !void {
    const val_rs1 = @as(i32, @bitCast(cpu.readReg(rs1))); // Signed comparison
    const val_rs2 = @as(i32, @bitCast(cpu.readReg(rs2)));
    cpu.writeReg(rd, if (val_rs1 < val_rs2) 1 else 0);
    cpu.pc +%= 4;
}

/// Executes SLTU (Set Less Than Unsigned) instruction: rd = (rs1 < rs2) ? 1 : 0 (unsigned)
pub fn SLTU(cpu: *CPU, rd: u5, rs1: u5, rs2: u5) !void {
    const val_rs1 = cpu.readReg(rs1); // Unsigned comparison
    const val_rs2 = cpu.readReg(rs2);
    cpu.writeReg(rd, if (val_rs1 < val_rs2) 1 else 0);
    cpu.pc +%= 4;
}

/// Executes XOR instruction: rd = rs1 ^ rs2
pub fn XOR(cpu: *CPU, rd: u5, rs1: u5, rs2: u5) !void {
    const val_rs1 = cpu.readReg(rs1);
    const val_rs2 = cpu.readReg(rs2);
    cpu.writeReg(rd, val_rs1 ^ val_rs2);
    cpu.pc +%= 4;
}

/// Executes SRL (Shift Right Logical) instruction: rd = rs1 >> (rs2[4:0]) (logical)
pub fn SRL(cpu: *CPU, rd: u5, rs1: u5, rs2: u5) !void {
    const val_rs1 = cpu.readReg(rs1);
    const val_rs2 = cpu.readReg(rs2);
    const shamt = @as(u5, @truncate(val_rs2)); // Shift amount is lower 5 bits of rs2
    cpu.writeReg(rd, val_rs1 >> shamt); // Logical shift right
    cpu.pc +%= 4;
}

/// Executes SRA (Shift Right Arithmetic) instruction: rd = rs1 >> (rs2[4:0]) (arithmetic)
pub fn SRA(cpu: *CPU, rd: u5, rs1: u5, rs2: u5) !void {
    const val_rs1 = cpu.readReg(rs1);
    const val_rs2 = cpu.readReg(rs2);
    const shamt = @as(u5, @truncate(val_rs2)); // Shift amount is lower 5 bits of rs2
    // Arithmetic shift right preserves sign bit
    cpu.writeReg(rd, @as(u32, @bitCast(@as(i32, @bitCast(val_rs1)) >> shamt)));
    cpu.pc +%= 4;
}

/// Executes OR instruction: rd = rs1 | rs2
pub fn OR(cpu: *CPU, rd: u5, rs1: u5, rs2: u5) !void {
    const val_rs1 = cpu.readReg(rs1);
    const val_rs2 = cpu.readReg(rs2);
    cpu.writeReg(rd, val_rs1 | val_rs2);
    cpu.pc +%= 4;
}

/// Executes AND instruction: rd = rs1 & rs2
pub fn AND(cpu: *CPU, rd: u5, rs1: u5, rs2: u5) !void {
    const val_rs1 = cpu.readReg(rs1);
    const val_rs2 = cpu.readReg(rs2);
    cpu.writeReg(rd, val_rs1 & val_rs2);
    cpu.pc +%= 4;
}

// --- S-Type Execution Functions (Opcode 0x23) ---

pub const S_OP = *const fn (cpu: *CPU, rs1: u5, rs2: u5, imm: i32) anyerror!void;

/// Executes SB (Store Byte) instruction: memory[rs1 + offset] = rs2[7:0]
pub fn SB(cpu: *CPU, rs1: u5, rs2: u5, imm: i32) !void {
    const base_addr = cpu.readReg(rs1);
    const offset = @as(u32, @bitCast(imm)); // sign-extended offset
    const mem_addr = base_addr +% offset;
    const value_to_store = @as(u8, @truncate(cpu.readReg(rs2))); // Lower 8 bits
    try cpu.ram.writeByte(mem_addr, value_to_store); // Propagates RamError
    cpu.pc +%= 4;
}

/// Executes SH (Store Half-word) instruction: memory[rs1 + offset] = rs2[15:0]
pub fn SH(cpu: *CPU, rs1: u5, rs2: u5, imm: i32) !void {
    const base_addr = cpu.readReg(rs1);
    const offset = @as(u32, @bitCast(imm)); // sign-extended offset
    const mem_addr = base_addr +% offset;
    const value_to_store = @as(u16, @truncate(cpu.readReg(rs2))); // Lower 16 bits
    try cpu.ram.writeHalfWord(mem_addr, value_to_store); // Propagates RamError
    cpu.pc +%= 4;
}

/// Executes SW (Store Word) instruction: memory[rs1 + offset] = rs2
pub fn SW(cpu: *CPU, rs1: u5, rs2: u5, imm: i32) !void {
    const base_addr = cpu.readReg(rs1);
    const offset = @as(u32, @bitCast(imm)); // sign-extended offset
    const mem_addr = base_addr +% offset;
    const value_to_store = cpu.readReg(rs2); // Full 32 bits
    try cpu.ram.writeWord(mem_addr, value_to_store); // Propagates RamError
    cpu.pc +%= 4;
}

// --- B-Type Execution Functions (Opcode 0x63) ---

pub const B_OP = *const fn (cpu: *CPU, rs1: u5, rs2: u5, imm: i32) anyerror!void;

/// Executes BEQ (Branch if Equal) instruction: if (rs1 == rs2) pc += offset
pub fn BEQ(cpu: *CPU, rs1: u5, rs2: u5, imm: i32) !void {
    const val_rs1 = cpu.readReg(rs1);
    const val_rs2 = cpu.readReg(rs2);
    const offset = @as(u32, @bitCast(imm)); // Branch offset is multiple of 2
    if (val_rs1 == val_rs2) {
        cpu.pc +%= offset; // Add branch offset
    } else {
        cpu.pc +%= 4; // Go to next instruction
    }
}

/// Executes BNE (Branch if Not Equal) instruction: if (rs1 != rs2) pc += offset
pub fn BNE(cpu: *CPU, rs1: u5, rs2: u5, imm: i32) !void {
    const val_rs1 = cpu.readReg(rs1);
    const val_rs2 = cpu.readReg(rs2);
    const offset = @as(u32, @bitCast(imm));
    if (val_rs1 != val_rs2) {
        cpu.pc +%= offset;
    } else {
        cpu.pc +%= 4;
    }
}

/// Executes BLT (Branch if Less Than) instruction: if (rs1 < rs2) pc += offset (signed)
pub fn BLT(cpu: *CPU, rs1: u5, rs2: u5, imm: i32) !void {
    const val_rs1 = @as(i32, @bitCast(cpu.readReg(rs1))); // Signed comparison
    const val_rs2 = @as(i32, @bitCast(cpu.readReg(rs2)));
    const offset = @as(u32, @bitCast(imm));
    if (val_rs1 < val_rs2) {
        cpu.pc +%= offset;
    } else {
        cpu.pc +%= 4;
    }
}

/// Executes BGE (Branch if Greater Than or Equal) instruction: if (rs1 >= rs2) pc += offset (signed)
pub fn BGE(cpu: *CPU, rs1: u5, rs2: u5, imm: i32) !void {
    const val_rs1 = @as(i32, @bitCast(cpu.readReg(rs1))); // Signed comparison
    const val_rs2 = @as(i32, @bitCast(cpu.readReg(rs2)));
    const offset = @as(u32, @bitCast(imm));
    if (val_rs1 >= val_rs2) {
        cpu.pc +%= offset;
    } else {
        cpu.pc +%= 4;
    }
}

/// Executes BLTU (Branch if Less Than Unsigned) instruction: if (rs1 < rs2) pc += offset (unsigned)
pub fn BLTU(cpu: *CPU, rs1: u5, rs2: u5, imm: i32) !void {
    const val_rs1 = cpu.readReg(rs1); // Unsigned comparison
    const val_rs2 = cpu.readReg(rs2);
    const offset = @as(u32, @bitCast(imm));
    if (val_rs1 < val_rs2) {
        cpu.pc +%= offset;
    } else {
        cpu.pc +%= 4;
    }
}

/// Executes BGEU (Branch if Greater Than or Equal Unsigned) instruction: if (rs1 >= rs2) pc += offset (unsigned)
pub fn BGEU(cpu: *CPU, rs1: u5, rs2: u5, imm: i32) !void {
    const val_rs1 = cpu.readReg(rs1); // Unsigned comparison
    const val_rs2 = cpu.readReg(rs2);
    const offset = @as(u32, @bitCast(imm));
    if (val_rs1 >= val_rs2) {
        cpu.pc +%= offset;
    } else {
        cpu.pc +%= 4;
    }
}

// --- U-Type Execution Functions (Opcodes 0x37, 0x17) ---

pub const U_OP = *const fn (cpu: *CPU, rd: u5, imm: i32) anyerror!void;

/// Executes LUI (Load Upper Immediate) instruction: rd = imm << 12
pub fn LUI(cpu: *CPU, rd: u5, imm: i32) !void {
    // The immediate 'imm' extracted by the decoder for U-type
    // already represents the value with the lower 12 bits as zero.
    cpu.writeReg(rd, @as(u32, @bitCast(imm)));
    cpu.pc +%= 4;
}

/// Executes AUIPC (Add Upper Immediate to PC) instruction: rd = pc + (imm << 12)
pub fn AUIPC(cpu: *CPU, rd: u5, imm: i32) !void {
    // The immediate 'imm' extracted by the decoder for U-type
    // already represents the value with the lower 12 bits as zero.
    const upper_imm = @as(u32, @bitCast(imm));
    cpu.writeReg(rd, cpu.pc +% upper_imm);
    cpu.pc +%= 4;
}

// --- J-Type Execution Functions (Opcode 0x6F) ---

pub const J_OP = *const fn (cpu: *CPU, rd: u5, imm: i32) anyerror!void;

/// Executes JAL (Jump and Link) instruction: rd = pc + 4; pc += offset
pub fn JAL(cpu: *CPU, rd: u5, imm: i32) !void {
    const return_addr = cpu.pc +% 4; // Address of instruction after JAL
    const offset = @as(u32, @bitCast(imm)); // Jump offset is multiple of 2

    cpu.writeReg(rd, return_addr); // Write return address (if rd != x0)
    cpu.pc +%= offset; // Perform jump by adding offset to current PC
}
