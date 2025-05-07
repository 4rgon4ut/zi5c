const std = @import("std");

const ops = @import("operations.zig");
const CPU = @import("cpu.zig").CPU;

const DecodedInstruction = union(enum) {
    I: InstructionI,
    Illegal: u32,
};

const InstructionI = struct {
    name: []const u8,

    rd: u5,
    rs1: u5,
    imm: i32,

    op: ops.I_OP,

    pub fn display(self: *InstructionI) void {
        std.debug.print("Instruction: {s}\n", .{self.name});
        std.debug.print("rd: {d}\n", .{self.rd});
        std.debug.print("rs1: {d}\n", .{self.rs1});
        std.debug.print("imm: {d}\n", .{self.imm});
    }

    pub fn execute(self: *InstructionI, cpu: *CPU) !void {
        try self.op(cpu, self.rs1, self.rd, self.imm);
    }
};
