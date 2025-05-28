const std = @import("std");

const rv_consts = @import("encoding_constants.zig");
const abi = @import("abi_regs.zig");
const RAM = @import("ram.zig").RAM;

const DecodedInstruction = @import("instruction_formats.zig").DecodedInstruction;
const decoder = @import("decoder.zig").Decoder;

const Trap = @import("traps.zig").Trap;
const FatalError = @import("traps.zig").FatalError;

pub const CPU = struct {
    pc: u32,
    regs: [32]u32,
    ram: *RAM,

    pub fn init(allocator: std.mem.Allocator, ram: *RAM) !*CPU {
        const cpu = try allocator.create(CPU);

        cpu.* = CPU{
            .pc = 0,
            .regs = [_]u32{0} ** 32,
            .ram = ram,
        };

        return cpu;
    }

    // --------------------------------------------
    //            REGISTERS FUNCTIONS
    // --------------------------------------------

    pub fn writeReg(self: *CPU, reg_num: abi.RegNum, value: u32) void {
        if (reg_num != abi.REG_ZERO) {
            self.regs[reg_num] = value;
        }
    }

    pub fn readReg(self: *CPU, reg_idx: abi.RegNum) u32 {
        if (reg_idx == abi.REG_ZERO) {
            return 0;
        }
        return self.regs[reg_idx];
    }

    pub fn dumpRegs(self: *CPU) void {
        std.debug.print("-------------------- CPU State Dump --------------------\n", .{});
        std.debug.print("PC : 0x{X:0>8}\n", .{self.pc}); // e.g., PC : 0x00001000
        std.debug.print("-------------------- GPRs (x0-x31) ---------------------\n", .{});

        std.debug.print("ABI_NAME (xNN): 0xVALUE\n\n", .{});
        for (self.regs, 0..) |reg, i| {
            const reg_name = abi.getAbiName(abi.REG_LIST[i]);

            std.debug.print("{s:<5} (x{any}): {any}", .{ reg_name, i, reg });
            if (i % 4 == 0) {
                std.debug.print("\n", .{});
            } else {
                std.debug.print("    ", .{});
            }
        }
        std.debug.print("\n", .{});
        std.debug.print("--------------------- End Dump -------------------------\n", .{});
    }

    // --------------------------------------------
    //            FETCH, DECODE, EXECUTE
    // --------------------------------------------
    pub fn fetch(self: *CPU) FatalError!u32 {
        return try self.ram.readWord(self.pc);
    }

    pub fn decode(instruction: u32) FatalError!void {
        return try decoder.decode(instruction);
    }

    pub fn execute(self: *CPU, instr: DecodedInstruction) !void {
        instr.execute(self) catch |err| {
            switch (err) {
                error.IllegalInstruction => {
                    return err;
                },
                else => {
                    std.debug.print("Error executing instruction:\n", .{});
                    instr.display();
                    std.debug.print("Error: {}\n", .{err});
                    return err;
                },
            }
        };
    }

    pub fn step(self: *CPU) ?Trap {
        const istruction_bits = self.fetch() catch |err| {
            std.log.err(
                \\Error fetching instruction: {any}
                \\PC: {X:0>8}
            , .{ err, self.pc });
            return Trap{ .Fatal = err };
        };

        const decoded_instruction = decoder.decode(istruction_bits) catch |err| {
            std.log.err(
                \\Error decoding instruction: {any}
                \\PC: 0x{X:0>8}
                \\Instruction bits: {b:0>32}
            , .{ err, self.pc, istruction_bits });
            return Trap{ .Fatal = err };
        };

        self.execute(decoded_instruction) catch |err| {
            std.log.err(
                \\Error executing instruction: {any}
                \\PC: 0x{X:0>8}
                \\Instruction: {any}
            , .{ err, self.pc, decoded_instruction });
            decoded_instruction.display();
            return Trap{ .Fatal = FatalError.Internal };
        };
        return null;
    }
};
