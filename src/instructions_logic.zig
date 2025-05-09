const std = @import("std");

const ops = @import("operations.zig");
const CPU = @import("cpu.zig").CPU;

const DecodedInstruction = union(enum) {
    I: InstructionI,
    R: InstructionR,
    S: InstructionS,
    B: InstructionB,
    U: InstructionU,
    J: InstructionJ,
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

const InstructionR = struct {
    name: []const u8,

    rd: u5,
    rs1: u5,
    rs2: u5,

    op: ops.R_OP,

    pub fn display(self: *InstructionR) void {
        std.debug.print("Instruction: {s}\n", .{self.name});
        std.debug.print("rd: {d}\n", .{self.rd});
        std.debug.print("rs1: {d}\n", .{self.rs1});
        std.debug.print("rs2: {d}\n", .{self.rs2});
    }

    pub fn execute(self: *InstructionR, cpu: *CPU) !void {
        try self.op(cpu, self.rs1, self.rs2, self.rd);
    }
};

const InstructionS = struct {
    name: []const u8,

    rs1: u5,
    rs2: u5,
    imm: i32,

    op: ops.S_OP,

    pub fn display(self: *InstructionS) void {
        std.debug.print("Instruction: {s}\n", .{self.name});
        std.debug.print("rs1: {d}\n", .{self.rs1});
        std.debug.print("rs2: {d}\n", .{self.rs2});
        std.debug.print("imm: {d}\n", .{self.imm});
    }
    pub fn execute(self: *InstructionS, cpu: *CPU) !void {
        try self.op(cpu, self.rs1, self.rs2, self.imm);
    }
};

const InstructionB = struct {
    name: []const u8,

    rs1: u5,
    rs2: u5,
    imm: i32,

    op: ops.B_OP,

    pub fn display(self: *InstructionB) void {
        std.debug.print("Instruction: {s}\n", .{self.name});
        std.debug.print("rs1: {d}\n", .{self.rs1});
        std.debug.print("rs2: {d}\n", .{self.rs2});
        std.debug.print("imm: {d}\n", .{self.imm});
    }

    pub fn execute(self: *InstructionB, cpu: *CPU) !void {
        try self.op(cpu, self.rs1, self.rs2, self.imm);
    }
};

const InstructionU = struct {
    name: []const u8,

    rd: u5,
    imm: i32,

    op: ops.U_OP,

    pub fn display(self: *InstructionU) void {
        std.debug.print("Instruction: {s}\n", .{self.name});
        std.debug.print("rd: {d}\n", .{self.rd});
        std.debug.print("imm: {d}\n", .{self.imm});
    }

    pub fn execute(self: *InstructionU, cpu: *CPU) !void {
        try self.op(cpu, self.rd, self.imm);
    }
};

const InstructionJ = struct {
    name: []const u8,

    rd: u5,
    imm: i32,

    op: ops.J_OP,

    pub fn display(self: *InstructionJ) void {
        std.debug.print("Instruction: {s}\n", .{self.name});
        std.debug.print("rd: {d}\n", .{self.rd});
        std.debug.print("imm: {d}\n", .{self.imm});
    }

    pub fn execute(self: *InstructionJ, cpu: *CPU) !void {
        try self.op(cpu, self.rd, self.imm);
    }
};
