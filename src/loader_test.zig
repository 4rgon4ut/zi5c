const std = @import("std");
const RAM = @import("ram.zig").RAM;
const loadELF = @import("loader.zig").loadELF;

test "loadELF function test" {
    const testing = std.testing;

    // 1. Setup RAM
    const test_ram_size: usize = 64 * 1024; // 64K, should be enough for test.elf
    const stack_size: usize = 4 * 1024; // 4K stack
    var test_ram_buffer: [test_ram_size]u8 = undefined;
    // Initialize RAM to a known state (e.g., zeros) to ensure loading works correctly
    @memset(&test_ram_buffer, 0x00);

    var ram = try RAM.init(&test_ram_buffer, stack_size);

    // 2. Execute the function under test
    // Make sure "test_executable.elf" exists in the CWD when running tests
    try loadELF(&ram, "./test_executable.elf");

    // 3. Verify the results
    // Define expected byte patterns based on test.S and test.ld

    // .text section was linked at ORIGIN = 0x0 (RAM_BASE)
    const expected_text_bytes = [_]u8{
        // LOADER WRITES IN LITTLE-ENDIAN
        0x13, 0x05, 0x10, 0x00, // => .word 0x00100513
        0x93, 0x05, 0x20, 0x00, // => .word 0x00200593
        0x33, 0x06, 0xb5, 0x00, // => .word 0x00b50633
        0xEF, 0xBE, 0xAD, 0xDE, // => .word 0xDEADBEEF
    };
    const text_offset_in_ram: usize = 0x00000000 - ram.ram_base; // Should be 0

    // .data section was linked immediately after .text (aligned to 4 bytes)
    const expected_data_bytes = [_]u8{
        0x11, 0x22, 0x33, 0x44, // Individual bytes
        0xBE, 0xBA, 0xFE, 0xCA, // 0xCAFEBABE (little-endian)
    };
    // Calculate where data should start. Text has 4 words = 16 bytes.
    // Linker script aligns, so data starts right after text at offset 16.
    const data_offset_in_ram: usize = (0x00000000 + 16) - ram.ram_base; // Should be 16

    // Perform checks
    try testing.expectEqualSlices(u8, &expected_text_bytes, ram.buffer[text_offset_in_ram .. text_offset_in_ram + expected_text_bytes.len]);
    std.debug.print("Text section loaded correctly.\n", .{});

    try testing.expectEqualSlices(u8, &expected_data_bytes, ram.buffer[data_offset_in_ram .. data_offset_in_ram + expected_data_bytes.len]);
    std.debug.print("Data section loaded correctly.\n", .{});

    // Optional: Check that memory *after* the loaded data wasn't touched (still 0x00)
    const check_offset = data_offset_in_ram + expected_data_bytes.len;
    if (check_offset + 4 <= ram.buffer.len) { // Ensure check is within bounds
        try testing.expectEqualSlices(u8, &[_]u8{ 0x00, 0x00, 0x00, 0x00 }, ram.buffer[check_offset .. check_offset + 4]);
        std.debug.print("Memory after loaded data seems untouched.\n", .{});
    }

    // Optional: Check if heap_start was updated correctly if loadELF modifies it.
    // If loadELF doesn't modify it, you might call ram.setHeapStart() here and test that separately.
    // const expected_heap_start = (data_offset_in_ram + expected_data_bytes.len + ram.ram_base);
    // try testing.expectEqual(expected_heap_start, ram.heap_start);

}
