const std = @import("std");

const abi = @import("abi_regs.zig");

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

};
