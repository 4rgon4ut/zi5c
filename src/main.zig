const std = @import("std");

const VM = @import("vm.zig").VM;

const traps = @import("traps.zig");
const cli = @import("cli.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const argv = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, argv);

    const args = cli.parseArgs(argv) catch |err| {
        std.log.err("Error parsing command line arguments: {}", .{err});
        return err;
    };

    if (args.help_requested) return;

    var vm = try VM.init(allocator, @as(usize, args.mem_size), args.stack_size);
    defer vm.deinit();

    try vm.loadProgram(args.exe_path);

    try vm.run(args.max_steps);
}
