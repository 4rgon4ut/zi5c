const std = @import("std");
const RAM = @import("ram.zig").RAM;

test "RAM init: valid configuration" {
    var buffer_mem: [1024 * 1024]u8 = undefined; // 1MB
    const ram_buffer = buffer_mem[0..];
    const base_addr: usize = 0x1000;
    const stack_size: usize = 256 * 1024; // 256KB

    // expected offsets
    const expected_ram_end = base_addr + ram_buffer.len;
    const expected_stack_top = expected_ram_end;
    const expected_stack_limit = expected_stack_top - stack_size;

    const ram = try RAM.init(ram_buffer, base_addr, stack_size);

    try std.testing.expectEqual(ram_buffer.len, ram.buffer.len);
    try std.testing.expectEqual(ram_buffer.ptr, ram.buffer.ptr);
    try std.testing.expectEqual(base_addr, ram.ram_base);
    try std.testing.expectEqual(expected_ram_end, ram.ram_end);
    try std.testing.expectEqual(expected_stack_top, ram.stack_top);
    try std.testing.expectEqual(expected_stack_limit, ram.stack_limit);
}
