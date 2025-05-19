const std = @import("std");

const abi = @import("abi_regs.zig");
const rv_consts = @import("encoding_constants.zig");

const instr = @import("instruction_formats.zig");

pub const Decoder = struct {
    fn extractOpcode(instruction: u32) rv_consts.Opcode {
        return @as(rv_consts.Opcode, @truncate(instruction & 0x7F));
    }
    fn extractRd(instruction: u32) abi.RegNum {
        return @as(abi.RegNum, @truncate((instruction >> 7) & 0x1F));
    }
    fn extractFunct3(instruction: u32) rv_consts.Funct3 {
        return @as(rv_consts.Funct3, @truncate((instruction >> 12) & 0x07));
    }
    fn extractRs1(instruction: u32) abi.RegNum {
        return @as(abi.RegNum, @truncate((instruction >> 15) & 0x1F));
    }
    fn extractRs2(instruction: u32) abi.RegNum {
        return @as(abi.RegNum, @truncate((instruction >> 20) & 0x1F));
    }
    fn extractFunct7(instruction: u32) rv_consts.Funct7 {
        return @as(rv_consts.Funct7, @truncate((instruction >> 25) & 0x7F));
    }
    fn extractImmediateI(instruction: u32) i32 {
        const imm_raw = instruction >> 20;

        return asI32(imm_raw, 12);
    }
    fn extractImmediateS(instruction: u32) i32 {
        const imm_11_5 = (instruction >> 25) & 0x7F;
        const imm_4_0 = (instruction >> 7) & 0x1F;
        const imm_raw = (imm_11_5 << 5) | imm_4_0;

        return asI32(imm_raw, 13);
    }
    fn extractImmediateB(instruction: u32) i32 {
        const imm_12 = (instruction >> 31) & 1;
        const imm_10_5 = (instruction >> 25) & 0x3F;
        const imm_4_1 = (instruction >> 8) & 0xF;
        const imm_11 = (instruction >> 7) & 1;
        const imm_raw = (imm_12 << 12) | (imm_11 << 11) | (imm_10_5 << 5) | (imm_4_1 << 1);

        return asI32(imm_raw, 13);
    }
    fn extractImmediateU(instruction: u32) i32 {
        return @as(i32, @bitCast(instruction & 0xFFFFF000));
    }
    fn extractImmediateJ(instruction: u32) i32 {
        const imm_20 = (instruction >> 31) & 1;
        const imm_10_1 = (instruction >> 21) & 0x3FF;
        const imm_11 = (instruction >> 20) & 1;
        const imm_19_12 = (instruction >> 12) & 0xFF;

        const imm_raw = (imm_20 << 20) | (imm_19_12 << 12) | (imm_11 << 11) | (imm_10_1 << 1);

        return asI32(imm_raw, 21);
    }

    fn asI32(imm_raw: u32, comptime original_bit_width: comptime_int) i32 {
        comptime std.debug.assert(original_bit_width > 0 and original_bit_width <= 32);
        // types
        const UnsignedN = std.meta.Int(.unsigned, original_bit_width);
        const SignedN = std.meta.Int(.signed, original_bit_width);

        const imm_unsigned_n = @as(UnsignedN, @truncate(imm_raw));
        const imm_signed_n = @as(SignedN, @bitCast(imm_unsigned_n));

        return @as(i32, imm_signed_n);
    }

    pub fn decode(instruction_bits: u32) !instr.DecodedInstruction {
        const opcode = Decoder.extractOpcode(instruction_bits);

        switch (opcode) {
            rv_consts.OPCODE_LUI, rv_consts.OPCODE_AUIPC => {
                return .{ .U = try instr.InstructionU.init(
                    opcode,
                    Decoder.extractRd(instruction_bits),
                    Decoder.extractImmediateU(instruction_bits),
                ) };
            },
            rv_consts.OPCODE_JAL => {
                return .{ .J = try instr.InstructionJ.init(
                    opcode,
                    Decoder.extractRd(instruction_bits),
                    Decoder.extractImmediateJ(instruction_bits),
                ) };
            },
            rv_consts.OPCODE_JALR, rv_consts.OPCODE_LOAD, rv_consts.OPCODE_OP_IMM, rv_consts.OPCODE_MISC_MEM, rv_consts.OPCODE_SYSTEM => {
                return .{ .I = try instr.InstructionI.init(
                    opcode,
                    Decoder.extractRd(instruction_bits),
                    Decoder.extractRs1(instruction_bits),
                    Decoder.extractFunct3(instruction_bits),
                    Decoder.extractImmediateI(instruction_bits),
                ) };
            },
            rv_consts.OPCODE_BRANCH => {
                return .{ .B = try instr.InstructionB.init(
                    opcode,
                    Decoder.extractRs1(instruction_bits),
                    Decoder.extractRs2(instruction_bits),
                    Decoder.extractFunct3(instruction_bits),
                    Decoder.extractImmediateB(instruction_bits),
                ) };
            },
            rv_consts.OPCODE_STORE => {
                return .{ .S = try instr.InstructionS.init(
                    opcode,
                    Decoder.extractRs1(instruction_bits),
                    Decoder.extractRs2(instruction_bits),
                    Decoder.extractFunct3(instruction_bits),
                    Decoder.extractImmediateS(instruction_bits),
                ) };
            },
            rv_consts.OPCODE_OP => {
                return .{ .R = try instr.InstructionR.init(
                    opcode,
                    Decoder.extractRd(instruction_bits),
                    Decoder.extractRs1(instruction_bits),
                    Decoder.extractRs2(instruction_bits),
                    Decoder.extractFunct3(instruction_bits),
                    Decoder.extractFunct7(instruction_bits),
                ) };
            },
            else => {
                // std.log.err("Decoder: Unknown opcode: 0b{b:0>7} (0x{x:02X}) in instruction 0x{X:0>8}", .{ opcode, opcode, instruction_bits });
                return .{ .Illegal = instruction_bits };
            },
        }
    }
};
