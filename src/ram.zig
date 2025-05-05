const std = @import("std");

// Address
// 0x00000000 +-------------------------+ Low Addresses
//            |       (Reserved?)       |
// CODE_START |-------------------------| <-- PC often starts here
//            |      Code (.text)       |
//            |-------------------------|
// DATA_START | Global/Static Data      |
//            | (.rodata, .data, .bss)  |
//            |-------------------------|
// HEAP_START |       Heap Area         |
//            | (Grows upwards -->)     |
//            .                         .
//            .      (Available)        .  <-- Potential Collision Area
//            .                         .
//            | (<-- Grows downwards)   |
// STACK_INIT |       Stack Area        | <-- SP often starts here
//            |-------------------------| High Addresses
// total_size |      (End of RAM)       |
//            +-------------------------+
pub const RAM_BASE: usize = 0x00000000;

pub const RAM = struct {
    buffer: []u8, // entire usable RAM

    // GLOBAL LAYOUT
    ram_base: usize,
    ram_end: usize, // ram_base + buffer.len

    // STACK
    stack_top: usize, // initial SP value
    stack_limit: usize, // lowest valid stack address

    // HEAP
    heap_start: usize,
    // NOTE: heap_current_break: usize, // Current top of allocated heap data

    pub fn init(buffer: []u8, stack_allocation_size: usize) !RAM {
        if (buffer.len == 0 or stack_allocation_size == 0 or stack_allocation_size > buffer.len) {
            return error.InvalidMemoryConfiguration;
        }

        const effective_ram_end = RAM_BASE + buffer.len;

        return RAM{
            .buffer = buffer,
            .ram_base = RAM_BASE,
            .ram_end = effective_ram_end,
            .stack_top = effective_ram_end,
            .stack_limit = effective_ram_end - stack_allocation_size,
            .heap_start = 0,
        };
    }

    pub fn setHeapStart(self: *RAM, end_of_bss: usize) !void {
        if (end_of_bss < self.ram_base or end_of_bss >= self.stack_limit) {
            return error.InvalidHeapStart;
        }
        self.heap_start = end_of_bss;
    }

    pub fn printLayout(self: *RAM) void {
        const total_size = self.ram_end - self.ram_base;
        const loaded_size = self.heap_start - self.ram_base;
        const stack_size = self.stack_top - self.stack_limit;
        const heap_size = self.stack_limit - self.heap_start;

        // --- CORRECTED FORMAT SPECIFIER ---
        const fmt_addr = "0x{X:0>8}"; // Use uppercase hex, zero-pad, right-align, width 8

        std.debug.print("\n--- RAM Layout Summary ---\n", .{});
        std.debug.print(" Overall RAM : " ++ fmt_addr ++ " - " ++ fmt_addr ++ " (Size: {d} bytes / {d} KB)\n", .{
            self.ram_base, self.ram_end, total_size, total_size / 1024,
        });
        std.debug.print("  -> Loaded  : " ++ fmt_addr ++ " - " ++ fmt_addr ++ " (Size: {d} bytes)\n", .{
            self.ram_base, self.heap_start, loaded_size,
        });
        std.debug.print("  -> Heap    : " ++ fmt_addr ++ " - " ++ fmt_addr ++ " (Available: {d} bytes)\n", .{
            self.heap_start, self.stack_limit, heap_size,
        });
        std.debug.print("  -> Stack   : " ++ fmt_addr ++ " - " ++ fmt_addr ++ " (Allocated: {d} bytes)\n", .{
            self.stack_limit, self.stack_top, stack_size,
        });

        if (self.heap_start >= self.stack_limit) {
            // Use the corrected format specifier here too
            std.debug.print("  !! WARNING: Heap start (" ++ fmt_addr ++ ") overlaps allocated Stack region (limit " ++ fmt_addr ++ ") !!\n", .{
                self.heap_start, self.stack_limit,
            });
        }
        std.debug.print("--- End of Summary ---\n", .{});
    }
};
