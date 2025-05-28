const std = @import("std");

const Trap = @import("traps.zig").Trap;
const FatalError = @import("traps.zig").FatalError;

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

    pub fn init(allocator: std.mem.Allocator, total_size: usize, stack_size: u32) !*RAM {
        if (total_size == 0 or stack_size == 0 or stack_size > total_size) {
            return error.InvalidMemoryConfiguration;
        }

        const buffer = allocator.alloc(u8, total_size) catch |err| {
            std.log.err("Failed to allocate RAM buffer (size: {d} bytes): {}", .{ total_size, err });
            return error.RamAllocationFailed;
        };
        @memset(buffer, 0x00);
        errdefer allocator.free(buffer);

        const buffer_len_u32: u32 = @intCast(total_size);
        const effective_ram_end: u32 = RAM_BASE + buffer_len_u32;
        std.debug.print("effective_ram_end: {d}\n", .{effective_ram_end});

        const ram = try allocator.create(RAM);
        ram.* = .{
            .buffer = buffer,
            .ram_base = RAM_BASE,
            .ram_end = effective_ram_end,
            .stack_top = effective_ram_end,
            .stack_limit = effective_ram_end - stack_size,
            .heap_start = 0,
        };

        std.debug.print("ram end: {d}; ram base: {d}\n", .{ ram.ram_end, ram.ram_base });
        return ram;
    }

    pub fn setHeapStart(self: *RAM, end_of_bss: u32) !void {
        if (end_of_bss < self.ram_base or end_of_bss >= self.stack_limit) {
            return error.InvalidHeapStart;
        }
        self.heap_start = end_of_bss;
    }

    pub fn printLayout(self: *RAM) void {
        std.debug.print("ram end: {d}; ram base: {d}", .{ self.ram_end, self.ram_base });
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

    fn validateAccess(self: *const RAM, addr: u32, size: u32) FatalError!void {
        if ((size == 0) or (size != 1 and size != 2 and size != 4 and size != 8)) {
            return FatalError.MemoryInvalidAccessSize;
        }

        if (size != 1 and addr % size != 0) {
            return FatalError.MemoryUnalignedAccess;
        }

        if (size > (self.ram_end - addr)) {
            return FatalError.MemoryOutOfBounds;
        }
    }

    pub fn readByte(self: *const RAM, addr: u32) FatalError!u8 {
        try self.validateAccess(addr, 1);

        return self.buffer[addr];
    }

    pub fn writeByte(self: *RAM, addr: u32, value: u8) FatalError!void {
        try self.validateAccess(addr, 1);

        const buff_idx = @as(usize, addr);
        self.buffer[buff_idx] = value;
    }

    pub fn readHalfWord(self: *const RAM, addr: u32) FatalError!u16 {
        try self.validateAccess(addr, 2);

        const buff_idx = @as(usize, addr);
        const ptr: *const [2]u8 = @ptrCast(&self.buffer[buff_idx]);

        return std.mem.readInt(u16, ptr, .little);
    }

    pub fn writeHalfWord(self: *RAM, addr: u32, value: u16) FatalError!void {
        try self.validateAccess(addr, 2);

        const buff_idx = @as(usize, addr);
        const ptr: *[2]u8 = @ptrCast(&self.buffer[buff_idx]);

        std.mem.writeInt(u16, ptr, value, .little);
    }

    pub fn readWord(self: *const RAM, addr: u32) FatalError!u32 {
        try self.validateAccess(addr, 4);

        const buff_idx = @as(usize, addr);
        const ptr: *const [4]u8 = @ptrCast(&self.buffer[buff_idx]);

        return std.mem.readInt(u32, ptr, .little); // RISC-V is typically little-endian
    }

    pub fn writeWord(self: *RAM, addr: u32, value: u32) FatalError!void {
        try self.validateAccess(addr, 4);

        const buff_idx = @as(usize, addr);
        const ptr: *[4]u8 = @ptrCast(&self.buffer[buff_idx]);

        std.mem.writeInt(u32, ptr, value, .little);
    }
};
