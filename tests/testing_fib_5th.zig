const std = @import("std");
const testing = std.testing;

const zi5c = @import("zi5c");

const getFixturePath = @import("testing_all.zig").getFixturePath;

test "execute Fibonacci(5) program isolated RAM and CPU" {
    const fib_hang_address = 0x00000028;

    var host_ram_array: [64 * 1024]u8 = undefined;
    @memset(&host_ram_array, 0x00);

    var vm_ram = try zi5c.RAM.init(&host_ram_array, 1024);

    // const path = try getFixturePath(std.testing.allocator, "elf/fib_5th.elf");
    const entry_point = zi5c.loader.loadELF(&vm_ram, "tests/fixtures/elf/fib_5th.elf") catch |err| {
        // std.log.err("Failed to load fibonacci.elf: {}", .{err});
        // Depending on how loadELF signals errors, you might need to adjust.
        // For a test, we can panic or return the error.
        return err; // Or use try if loadELF returns !u32
    };

    _ = entry_point; // autofix
    // std.debug.print("ELF loaded. Entry point: 0x{X:0>8}\n", .{entry_point});

    // 3. Initialize CPU
    // CPU.init(entry_point, initial_sp_value, ram_instance_ptr)
    var cpu = zi5c.CPU.init(&vm_ram);
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

        cpu.step() catch |err| {
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
    const result_fib5 = cpu.readReg(zi5c.isa.abi_regs.REG_A0);
    // std.debug.print("Fibonacci(5) result in a0 (x10): {d} (0x{X:0>8})\n", .{ result_fib5, result_fib5 });

    std.debug.print("Fibonacci(5) result is correct: {d} (0x{X:0>8})\n", .{ result_fib5, result_fib5 });
    try testing.expectEqual(@as(u32, 5), result_fib5);
}
