const std = @import("std");
const CPU = @import("cpu.zig").CPU;
const RAM = @import("ram.zig").RAM;
const loadELF = @import("loader.zig").loadELF;
const rv_abi = @import("abi_regs.zig");

pub const VM = struct {
    cpu: *CPU,
    ram: *RAM,

    arena: std.heap.ArenaAllocator,

    is_halted: bool,
    steps_executed: u64,

    pub fn init(ram_size: usize, stack_size: u32) !VM {
        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        errdefer arena.deinit();
        const allocator = arena.allocator();

        const ram = RAM.init(allocator, ram_size, stack_size) catch |err| {
            std.log.err("Failed to initialize RAM: {}", .{err});
            return err;
        };
        const cpu = try CPU.init(allocator, ram);

        return VM{
            .cpu = cpu,
            .ram = ram,
            .arena = arena,
            .is_halted = false,
            .steps_executed = 0,
        };
    }

    pub fn deinit(self: *VM) void {
        self.arena.deinit();
        self.* = undefined;
    }

    pub fn loadProgram(self: *VM, elf_path: []const u8) !void {
        const loadResult = try loadELF(self.ram, elf_path);

        std.log.info("Setting Heap Start address to: 0x{X:0>8}\n", .{loadResult.heap_start});
        try self.ram.setHeapStart(loadResult.heap_start);

        self.cpu.pc = loadResult.entry_point;
        self.cpu.writeReg(rv_abi.REG_SP, self.ram.stack_top);
        std.log.info("Loading complete. EP: 0x{X:0>8}, SP=0x{X:0>8}\n", .{ self.cpu.pc, self.cpu.readReg(rv_abi.REG_SP) });
        self.ram.printLayout();
    }

    pub fn run(self: *VM, max_steps: ?u64) !void {
        std.debug.print("VM run loop starting...\n", .{});

        while (!self.is_halted) {
            if (max_steps) |limit| {
                if (self.steps_executed >= limit) {
                    std.log.warn("VM reached maximum step count ({d}). Halting.", .{limit});
                    self.cpu.dumpRegs();
                    self.halt();
                    return error.MaxStepsReached;
                }
            }

            // CPU.step uses self.cpu.ram internally
            const maybe_trap = self.cpu.step();

            if (maybe_trap) |trap| {

                // A TRAP occurred! 'trap_value' holds the Trap union.
                std.log.debug("TRAP @ 0x{X:0>8}: {any}", .{ self.cpu.pc, trap });

                // Now, switch on the *kind* of trap.
                switch (trap) {
                    .Requested => {},

                    .Debug => {},

                    .Fatal => |fatal_data| {
                        std.log.err("FATAL TRAP @ 0x{X:0>8}: {any}", .{ self.cpu.pc, fatal_data });
                        self.cpu.dumpRegs();
                        self.halt();
                        return error.FatalTrapOccurred;
                    },
                }
            }

            self.steps_executed += 1;
        }

        std.debug.print("VM run loop finished. Total steps: {d}. PC: 0x{X:0>8}\n", .{ self.steps_executed, self.cpu.pc });
    }

    pub fn halt(self: *VM) void {
        std.debug.print("VM halt requested.\n", .{});
        self.is_halted = true;
    }
};
