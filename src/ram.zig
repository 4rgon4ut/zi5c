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
pub const RAM_BASE: u32 = 0x00000000;

pub const RAM = struct {
    buffer: []u8, // entire usable RAM

    // GLOBAL LAYOUT
    ram_base: u32,
    ram_end: u32, // ram_base + buffer.len

    // STACK
    stack_top: u32, // initial SP value
    stack_limit: u32, // lowest valid stack address

    // HEAP
    heap_start: u32,
    // NOTE: heap_current_break: u32, // Current top of allocated heap data

    pub fn init(buffer: []u8, stack_allocation_size: u32) !RAM {
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

    pub fn setHeapStart(self: *RAM, end_of_bss: u32) !void {
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

    fn validateAccess(self: *RAM, addr: u32, size: u32) !void {
        if (size == 0) {
            return error.InvalidAccessSize;
        }

        // TODO: probably check that size is in [1, 2, 4, 8]
        // (now guaranteed by the provided ram api functions, i.e. writeWord)
        if (size != 1 and addr % size != 0) {
            return error.InvalidAlignment;
        }

        if (size > (self.ram_end - addr)) {
            return error.OutOfBounds;
        }
    }

    pub fn readByte(
        self: *const RAM,
        addr: u32,
    ) !u8 {
        try self.validateAccess(addr, 1);

        return self.buffer[addr];
    }

    pub fn writeByte(self: *RAM, addr: u32, value: u8) !void {
        try self.validateAccess(addr, 1);

        const buff_idx = @as(usize, addr);
        self.buffer[buff_idx] = value;
    }

    pub fn readHalfWord(self: *const RAM, addr: u32) !u16 {
        try self.validateAccess(addr, 2);

        const buff_idx = @as(usize, addr);
        return std.mem.readInt(u16, self.buffer[buff_idx .. buff_idx + 2], .little); // RISC-V is typically little-endian
    }

    pub fn writeHalfWord(self: *RAM, addr: u32, value: u16) !void {
        try self.validateAccess(addr, 2);

        const buff_idx = @as(usize, addr);
        std.mem.writeInt(u16, self.buffer[buff_idx .. buff_idx + 2], value, .little);
    }

    pub fn readWord(self: *const RAM, addr: u32) !u32 {
        try self.validateAccess(addr, 4);

        const buff_idx = @as(usize, addr);
        return std.mem.readInt(u32, self.buffer[buff_idx .. buff_idx + 4], .little); // RISC-V is typically little-endian
    }

    pub fn writeWord(self: *RAM, addr: u32, value: u32) !void {
        try self.validateAccess(addr, 4);

        const buff_idx = @as(usize, addr);
        std.mem.writeInt(u32, self.buffer[buff_idx .. buff_idx + 4], value, .little);
    }
};
