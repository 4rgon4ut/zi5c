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

// ELF DUMP:
//
// 00000000 <_start>:
//    0:   00400293                li      t0,4
//    4:   00000513                li      a0,0
//    8:   00100593                li      a1,1

// 0000000c <loop>:
//    c:   00028c63                beqz    t0,24 <end_loop>
//   10:   00b50333                add     t1,a0,a1
//   14:   00058513                mv      a0,a1
//   18:   00030593                mv      a1,t1
//   1c:   fff28293                addi    t0,t0,-1
//   20:   fedff06f                j       c <loop>

// 00000024 <end_loop>:
//   24:   00058513                mv      a0,a1

// 00000028 <_hang>:
//   28:   0000006f                j       28 <_hang>
test "execute Fibonacci(5) program" {
    const fib_hang_address = 0x00000028; // Address where the program hangs
    // 1. Initialize RAM
    // This buffer is owned by the test function.
    var host_ram_array: [64 * 1024]u8 = undefined; // 16KB RAM for the test
    @memset(&host_ram_array, 0x00); // Initialize RAM to a known state (zeros)

    // Assuming RAM.init(buffer_slice, vm_start_addr, stack_size_vm)
    // and vm_start_addr is 0 for this simple case.
    var vm_ram = try RAM.init(&host_ram_array, 1024); // 1KB stack

    // 2. Load ELF
    // This test assumes "fibonacci.elf" is compiled and accessible.
    // The loadELF function should populate vm_ram.buffer and return the entry point.
    const entry_point = loadELF(&vm_ram, "fib_5th.elf") catch |err| {
        // std.log.err("Failed to load fibonacci.elf: {}", .{err});
        // Depending on how loadELF signals errors, you might need to adjust.
        // For a test, we can panic or return the error.
        return err; // Or use try if loadELF returns !u32
    };
    vm_ram.printLayout();
    _ = entry_point; // autofix
    // std.debug.print("ELF loaded. Entry point: 0x{X:0>8}\n", .{entry_point});

    // 3. Initialize CPU
    // CPU.init(entry_point, initial_sp_value, ram_instance_ptr)
    var cpu = CPU.init(&vm_ram);
    // std.debug.print("CPU Initialized. PC=0x{X:0>8}, SP=0x{X:0>8}\n", .{ cpu.pc, cpu.readReg(rv_abi.REG_SP) });

    // 4. Run CPU for a fixed number of steps, or until halt address
    const max_steps: u32 = 50; // Should be enough for Fibonacci(5)
    var steps_taken: u32 = 0;
    while (steps_taken < max_steps) {
        // Optional: Log PC before each step for debugging
        // std.debug.print("Step {d}: PC=0x{X:0>8}\n", .{steps_taken, cpu.pc});

        // Check if CPU has reached the infinite loop (halt point)
        if (cpu.pc == fib_hang_address) {
            // std.debug.print("CPU reached halt address 0x{X:0>8} after {d} steps.\n", .{ cpu.pc, steps_taken });
            break;
        }

        cpu.step(&vm_ram) catch |err| {
            // std.log.err("CPU Error at step {d}, PC=0x{X:0>8}: {}\n", .{ steps_taken, cpu.pc, err });
            cpu.dumpRegs(); // Dump registers on error
            // For this test, we don't expect EcallHalt as ECALLs are ignored.
            // Any other error is a test failure.
            return err;
        };
        steps_taken += 1;
    }

    if (steps_taken >= max_steps and cpu.pc != 0x00000028) {
        // std.debug.print("VM reached maximum step count ({d}) without halting at expected address.\n", .{max_steps});
        cpu.dumpRegs();
        try testing.expect(false); // Force test failure if not halted correctly
    }

    // 5. Assert the result
    // Fibonacci(5) is 5. The assembly stores the result in a0 (x10).
    const result_fib5 = cpu.readReg(rv_abi.REG_A0);
    // std.debug.print("Fibonacci(5) result in a0 (x10): {d} (0x{X:0>8})\n", .{ result_fib5, result_fib5 });
    cpu.dumpRegs(); // Dump final state for inspection
    std.debug.print("Fibonacci(5) result is correct: {d} (0x{X:0>8})\n", .{ result_fib5, result_fib5 });
    try testing.expectEqual(@as(u32, 5), result_fib5);
}
