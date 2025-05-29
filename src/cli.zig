const std = @import("std");

// defaults
var PROGRAM_NAME: []const u8 = "zi5c";
const DEFAULT_MEM_SIZE_BYTES: u32 = 1 * 1024 * 1024; // 1MB
const DEFAULT_STACK_SIZE_BYTES: u32 = 128 * 1024; // 128KB

const USAGE_FMT =
    \\Usage: {s} [OPTIONS] --exe <ELF_FILE>
    \\
    \\  --exe, -e <ELF_FILE>     Path to the RISC-V ELF executable (mandatory)
    \\
    \\Options:
    \\  --mem, -m <SIZE_BYTES>   Total memory size for VM (default: {d} bytes)
    \\  --stack, -s <SIZE_BYTES> Stack size for VM (default: {d} bytes, part of total memory)
    \\  --steps <COUNT>          Maximum execution steps (default: 0, unlimited)
    \\  --help, -h               Display this help message and exit
    \\
;

pub const Args = struct {
    exe_path: []const u8,
    mem_size: u32 = DEFAULT_MEM_SIZE_BYTES,
    stack_size: u32 = DEFAULT_STACK_SIZE_BYTES,
    max_steps: ?u64 = null,
    help_requested: bool = false,
};

fn displayHelp() void {
    std.debug.print(USAGE_FMT, .{ PROGRAM_NAME, DEFAULT_MEM_SIZE_BYTES, DEFAULT_STACK_SIZE_BYTES });
}

// Function to parse command-line arguments
pub fn parseArgs(argv: [][:0]u8) !Args {
    var args = Args{ .exe_path = undefined };
    var idx: usize = 1;
    var arg_exe_path: ?[]const u8 = null;

    while (idx < argv.len) {
        const current_arg = argv[idx];

        if (current_arg[0] != '-') {
            // No more options, break to handle positional arguments (if any)
            // For this CLI, all arguments are options.
            std.debug.print("Error: Unexpected positional argument: {s}\n", .{current_arg});
            displayHelp();
            return error.UnknownOption;
        }

        if (std.mem.eql(u8, current_arg, "-h") or std.mem.eql(u8, current_arg, "--help")) {
            idx += 1;
            displayHelp();
            args.help_requested = true;
            return args;
        } else if (std.mem.eql(u8, current_arg, "-m") or std.mem.eql(u8, current_arg, "--mem")) {
            idx += 1;
            if (idx >= argv.len) {
                std.debug.print("Error: Missing argument for {s}\n", .{current_arg});
                displayHelp();
                return error.MissingArgumentForOption;
            }
            args.mem_size = std.fmt.parseUnsigned(u32, argv[idx], 10) catch |err| {
                std.debug.print("Error: Invalid value for memory size '{s}': {any}\n", .{ argv[idx], err });
                displayHelp();
                return error.InvalidArgumentValue;
            };
            idx += 1;
        } else if (std.mem.eql(u8, current_arg, "-s") or std.mem.eql(u8, current_arg, "--stack")) {
            idx += 1;
            if (idx >= argv.len) {
                std.debug.print("Error: Missing argument for {s}\n", .{current_arg});
                displayHelp();
                return error.MissingArgumentForOption;
            }
            args.stack_size = std.fmt.parseUnsigned(u32, argv[idx], 10) catch |err| {
                std.debug.print("Error: Invalid value for stack size '{s}': {any}\n", .{ argv[idx], err });
                displayHelp();
                return error.InvalidArgumentValue;
            };
            idx += 1;
        } else if (std.mem.eql(u8, current_arg, "-e") or std.mem.eql(u8, current_arg, "--exe")) {
            idx += 1;
            if (idx >= argv.len) {
                std.debug.print("Error: Missing argument for {s}\n", .{current_arg});
                displayHelp();
                return error.MissingArgumentForOption;
            }
            arg_exe_path = argv[idx];

            idx += 1;
        } else if (std.mem.eql(u8, current_arg, "--steps")) {
            idx += 1;
            if (idx >= argv.len) {
                std.debug.print("Error: Missing argument for {s}\n", .{current_arg});
                displayHelp();
                return error.MissingArgumentForOption;
            }
            args.max_steps = std.fmt.parseUnsigned(u64, argv[idx], 10) catch |err| {
                std.debug.print("Error: Invalid value for steps '{s}': {any}\n", .{ argv[idx], err });
                displayHelp();
                return error.InvalidArgumentValue;
            };
            idx += 1;
        } else {
            std.debug.print("Error: Unknown option: {s}\n", .{current_arg});
            displayHelp();
            return error.UnknownOption;
        }
    }

    // After parsing all options, validate mandatory options and constraints

    if (arg_exe_path == null) {
        std.debug.print("Error: --exe <ELF_FILE> option is mandatory.\n", .{});
        displayHelp();
        return error.MissingRequiredOption;
    } else {
        args.exe_path = arg_exe_path.?;
    }
    if (args.stack_size == 0) {
        std.debug.print("Error: Stack size cannot be zero.\n", .{});
        return error.InvalidArgumentValue;
    }
    if (args.mem_size < args.stack_size) {
        std.debug.print("Error: Total memory size ({d}) cannot be less than stack size ({d}).\n", .{ args.mem_size, args.stack_size });
        return error.InvalidArgumentValue;
    }
    if (args.mem_size == 0 and args.stack_size > 0) {
        std.debug.print("Error: Total memory size cannot be zero if stack size is non-zero.\n", .{});
        return error.InvalidArgumentValue;
    }

    return args;
}
