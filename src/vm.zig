const std = @import("std");
const CPU = @import("cpu.zig").CPU;
const RAM = @import("ram.zig").RAM;
const loadELF = @import("loader.zig").loadELF;
const rv_abi = @import("abi_regs.zig");

const RequestedTrap = @import("traps.zig").RequestedTrap;

pub const VM = struct {
    cpu: *CPU,
    ram: *RAM,

    arena: std.heap.ArenaAllocator,

    is_halted: bool,
    steps_executed: u64,

    pub fn init(child_allocator: std.mem.Allocator, ram_size: usize, stack_size: u32) !VM {
        var arena = std.heap.ArenaAllocator.init(child_allocator);
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
                switch (trap) {
                    .Requested => |trap_type| {
                        std.log.info(
                            \\REQUESTED TRAP: {any}
                            \\PC: 0x{X:0>8}
                            \\Instruction:
                        , .{ trap_type, self.cpu.pc });

                        self.cpu.current_instruction.?.display();
                        try self.handleEnvTrap(trap_type);
                    },

                    .Fatal => |err| {
                        std.log.err(
                            \\FATAL TRAP: {any}
                            \\PC: 0x{X:0>8}
                            \\Instruction:
                        , .{ err, self.cpu.pc });

                        self.cpu.current_instruction.?.display();
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

    fn handleEnvTrap(self: *VM, trap: RequestedTrap) !void {
        const current_pc = self.cpu.pc;

        switch (trap) {
            .ECALL => {
                const syscall_num = self.cpu.readReg(rv_abi.REG_A7);
                switch (syscall_num) {
                    93 => { // SYSCALL EXIT
                        const exit_code = self.cpu.readReg(rv_abi.REG_A0);
                        std.log.info("ECALL: exit({d}). Halting...", .{exit_code});
                        return self.halt();
                    },
                    64 => { // SYSCALL WRITE
                        const fd = self.cpu.readReg(rv_abi.REG_A0);
                        const buf_addr = self.cpu.readReg(rv_abi.REG_A1);
                        const count = self.cpu.readReg(rv_abi.REG_A2);

                        std.log.info("ECALL: write(fd={d}, addr=0x{x}, count={d})", .{ fd, buf_addr, count });
                        // only handle stdout (1) and stderr (2)
                        if (fd == 1 or fd == 2) {
                            var i: u32 = 0;
                            while (i < count) : (i += 1) {
                                const byte = try self.ram.readByte(buf_addr + i);
                                _ = try std.io.getStdOut().writer().writeByte(byte);
                            }
                            // success: return number of bytes written
                            self.cpu.writeReg(rv_abi.REG_A0, count);
                        } else {
                            std.log.warn("ECALL: write to unsupported fd {d}", .{fd});
                            self.cpu.writeReg(rv_abi.REG_A0, 0xFFFFFFFF); // -1 in 32-bit two's complement
                        }
                    },
                    else => {
                        std.log.warn("ECALL: Unexpected syscall number {d}", .{syscall_num});
                        // Failure: return -1 (or -ENOSYS)
                        self.cpu.writeReg(rv_abi.REG_A0, 0xFFFFFFFF);
                    },
                }
            },
            .EBREAK => {
                std.log.warn("EBREAK encountered at PC 0x{X:0>8}. Halting.", .{current_pc});
                return self.halt();
            },
        }
        // if we reach here, we just continue execution
        self.cpu.pc = current_pc + 4;
    }

    pub fn halt(self: *VM) void {
        std.debug.print("VM halt requested.\n", .{});
        self.is_halted = true;
    }
};
