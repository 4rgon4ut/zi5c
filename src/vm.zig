const std = @import("std");
const CPU = @import("cpu.zig").CPU;
const RAM = @import("ram.zig").RAM;
const loadELF = @import("loader.zig").loadELF;

const VM = struct {
    cpu: *CPU,
    ram: *RAM,

    pub fn init(ram_size: u32, stack_size: u32) VM {
        return VM{
            .cpu = &CPU.init(),
            .ram = &RAM.init(ram_size, stack_size),
        };
    }

    pub fn start(self: *VM, elf_path: []const u8) !void {
        try loadELF(self.ram, elf_path);

        try self.run();
    }

    fn run(self: *VM) !void {
        while (true) {
            self.cpu.step(self.ram) catch |err| {
                std.log.err("Error during CPU step: {any}", .{err});
                return err;
            };
        }
    }

    pub fn halt() void {}
};
