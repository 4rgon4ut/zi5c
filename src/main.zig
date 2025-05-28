const std = @import("std");

const VM = @import("vm.zig").VM;

const traps = @import("traps.zig");

pub fn main() !void {
    var vm = try VM.init(1048576, 16 * 1024);
    defer vm.deinit();

    try vm.loadProgram("zi5c/program.elf");

    try vm.run(1000);
}
