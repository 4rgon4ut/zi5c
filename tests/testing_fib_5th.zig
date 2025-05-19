const std = @import("std");
const testing = std.testing;

const CPU = @import("../cpu.zig").CPU;
const RAM = @import("../ram.zig").RAM;
const loadELF = @import("../loader.zig").loadELF;
const abi_regs = @import("../abi_regs.zig");

test "execute Fibonacci(5) program isolated RAM and CPU" {
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
    const entry_point = loadELF(&vm_ram, "./fixtures/elf/fib_5th.elf") catch |err| {
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
    const result_fib5 = cpu.readReg(abi_regs.REG_A0);
    // std.debug.print("Fibonacci(5) result in a0 (x10): {d} (0x{X:0>8})\n", .{ result_fib5, result_fib5 });
    cpu.dumpRegs(); // Dump final state for inspection
    std.debug.print("Fibonacci(5) result is correct: {d} (0x{X:0>8})\n", .{ result_fib5, result_fib5 });
    try testing.expectEqual(@as(u32, 5), result_fib5);
}
