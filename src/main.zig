const std = @import("std");

const VM = @import("vm.zig").VM;

pub fn main() !void {
    var vm = try VM.init(256 * 1024, 4 * 1024);
    defer vm.deinit();

    try vm.loadProgram("zi5c/tests/fixtures/elf/rv32i_suite.elf");

    try vm.run(1000); // Run for a maximum of 1000 steps
}
