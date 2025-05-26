const std = @import("std");

const VM = @import("vm.zig").VM;

pub fn main() !void {
    var vm = try VM.init(1048576, 16 * 1024);
    defer vm.deinit();

    try vm.loadProgram("zi5c/program.elf");

    try vm.run(1000); // Run for a maximum of 1000 steps

}
