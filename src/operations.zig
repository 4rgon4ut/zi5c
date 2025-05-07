const std = @import("std");
const CPU = @import("cpu.zig").CPU;

const I_OP = fn (
    cpu: *CPU,
    rs1: u32,
    rd: u32,
    imm: u32,
) anyerror!void;

pub fn ADDI(cpu: *CPU, rs1: u5, rd: u5, imm: i32) !void {
    const val = cpu.readReg(rs1);
    const imm_u32 = @as(u32, @bitCast(imm));
    cpu.writeReg(rd, val +% imm_u32);
    cpu.pc +%= 4;
}
