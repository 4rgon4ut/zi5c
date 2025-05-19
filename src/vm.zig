const std = @import("std");
const CPU = @import("cpu.zig").CPU;
const RAM = @import("ram.zig").RAM;
const loadELF = @import("loader.zig").loadELF;
const rv_abi = @import("abi_regs.zig");
const testing = @import("std").testing;

const VM = struct {
    cpu: *CPU,
    ram: *RAM,

    ram_buffer: []u8,
    allocator: std.mem.Allocator,

    is_halted: bool,
    steps_executed: u64,

    pub fn init(gpa: std.mem.Allocator, ram_size: usize, stack_size: u32) VM {
        const ram_buf = gpa.alloc(u8, ram_size) catch |err| {
            std.log.err("Failed to allocate RAM buffer (size: {d} bytes): {}", .{ ram_size, err });
            return error.RamAllocationFailed;
        };
        @memset(ram_buf, 0x00);

        return VM{
            .ram = try RAM.init(ram_buf, stack_size),
            .cpu = try CPU.init(),

            .ram_buffer = ram_buf,
            .allocator = gpa,

            .is_halted = false,
            .steps_executed = 0,
        };
    }

    pub fn deinit(self: *VM) void {
        self.allocator.free(self.ram_buffer_slice);
        self.* = undefined;
    }

    pub fn load(self: *VM, elf_path: []const u8) !void {
        const loadResult = try loadELF(self.ram, elf_path);

        std.log.info("Setting Heap Start address to: 0x{X:0>8}\n", .{loadResult.heap_start});
        self.ram.setHeapStart(loadResult.heap_start);

        self.cpu.pc = loadResult.entry_point;
        self.cpu.writeReg(rv_abi.REG_SP, self.ram.stack_top);
        std.log.info("Loading complete. EP: 0x{X:0>8}, SP=0x{X:0>8}\n", .{ self.cpu.pc, self.cpu.readReg(rv_abi.REG_SP) });
        self.ram.printLayout();
    }

    fn run(self: *VM, max_steps: ?u64) !void {
        std.debug.print("VM run loop starting...\n", .{});
        while (!self.is_halted) {
            if (max_steps) |limit| {
                if (self.steps_executed >= limit) {
                    std.log.warn("VM reached maximum step count ({d}). Halting.", .{limit});
                    self.halt();
                    return error.MaxStepsReached;
                }
            }

            // CPU.step uses self.cpu.ram internally
            self.cpu.step() catch |err| {
                std.log.err("VM Error during CPU step {d} at PC 0x{X:0>8}: {}\n", .{
                    self.steps_executed,
                    self.cpu.pc,
                    err,
                });
                self.cpu.dumpRegs();
                self.is_halted = true;
                return err;
            };

            self.steps_executed += 1;
        }

        std.debug.print("VM run loop finished. Total steps: {d}. PC: 0x{X:0>8}\n", .{ self.steps_executed, self.cpu.pc });
    }

    pub fn halt(self: *VM) void {
        std.debug.print("VM halt requested.\n", .{});
        self.is_halted = true;
    }
};
