const std = @import("std");
const testing = std.testing;

const zi5c = @import("zi5c");

const getFixturePath = @import("testing_all.zig").getFixturePath;

test "loadELF function test" {
    const test_ram_size: u32 = 64 * 1024;
    const stack_size: u32 = 4 * 1024;
    var test_ram_buffer: [test_ram_size]u8 = undefined;
    @memset(&test_ram_buffer, 0x00);

    var ram = try zi5c.RAM.init(&test_ram_buffer, stack_size);

    const loadResult = try zi5c.loader.loadELF(&ram, "tests/fixtures/elf/test_loader.elf");

    try ram.setHeapStart(loadResult.heap_start);

    const expected_text_bytes = [_]u8{
        // LOADER WRITES IN LITTLE-ENDIAN
        0x13, 0x05, 0x10, 0x00, // => .word 0x00100513
        0x93, 0x05, 0x20, 0x00, // => .word 0x00200593
        0x33, 0x06, 0xb5, 0x00, // => .word 0x00b50633
        0xEF, 0xBE, 0xAD, 0xDE, // => .word 0xDEADBEEF
    };
    const text_offset_in_ram: u32 = 0x00000000 - ram.ram_base; // Should be 0

    // .data section was linked immediately after .text (aligned to 4 bytes)
    const expected_data_bytes = [_]u8{
        0x11, 0x22, 0x33, 0x44, // Individual bytes
        0xBE, 0xBA, 0xFE, 0xCA, // 0xCAFEBABE (little-endian)
    };
    // Calculate where data should start. Text has 4 words = 16 bytes.
    // Linker script aligns, so data starts right after text at offset 16.
    const data_offset_in_ram: u32 = (0x00000000 + 16) - ram.ram_base; // Should be 16

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
}
