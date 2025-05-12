const std = @import("std");

const rv_consts = @import("encoding_constants.zig");
const abi = @import("abi_regs.zig");
const RAM = @import("ram.zig").RAM;

const DecodedInstruction = @import("instructions.zig").DecodedInstruction;
const decoder = @import("decoder.zig").Decoder;

pub const CPU = struct {
    pc: u32,
    regs: [32]u32,

    pub fn init() CPU {
        return CPU{
            .pc = 0,
            .regs = [_]u32{0} ** 32,
        };
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
        for (abi.REG_LIST) |reg| {
            const reg_name = abi.getAbiName(reg);
            const reg_val = self.readReg(reg);
            std.debug.print("{s:<5} (x{02}): 0x{X:0>8}", .{ reg_name, reg, reg_val });
            if (reg % 4 == 0) {
                std.debug.print("\n", .{});
            } else {
                std.debug.print("    ", .{});
            }
        }

        std.debug.print("--------------------- End Dump -------------------------\n", .{});
    }

    // --------------------------------------------
    //            FETCH, DECODE, EXECUTE
    // --------------------------------------------
    pub fn fetch(self: *CPU, ram: *const RAM) !u32 {
        return try ram.readWord(self.pc);
    }

    pub fn decode(instruction: u32) !void {
        return try decoder.decode(instruction);
    }

    pub fn execute(self: *CPU, instr: *DecodedInstruction) !void {
        instr.execute(self);
    }

    pub fn step(self: *CPU, ram: *const RAM) !void {
        const start_pc = self.pc;

        const istruction_bits = self.fetch(ram) catch |err| {
            std.log.err("Error fetching instruction: {}\nStart PC: {X:0>8}", .{ err, start_pc });
            self.dumpRegs();
            return err;
        };

        const decoded_instruction = self.decode(istruction_bits) catch |err| {
            std.log.err("Error decoding instruction: {}\nStart PC: {X:0>8}", .{ err, start_pc });
            self.dumpRegs();
            return err;
        };

        std.log.debug("Successfully decoded instruction: 0x{X:0>8} -> {s}", .{ istruction_bits, decoded_instruction });

        switch (decoded_instruction) {
            .Illegal => {
                std.log.err("Illegal instruction: 0x{X:0>8}\nStart PC: {X:0>8}", .{ istruction_bits, start_pc });
                self.dumpRegs();
                return error.IllegalInstruction;
            },
            else => {
                decoded_instruction.display();
                self.execute(&decoded_instruction) catch |err| {
                    std.log.err("Error executing instruction: {}\nStart PC: {X:0>8}", .{ err, start_pc });
                    self.dumpRegs();
                    return err;
                };
            },
        }
    }
};
