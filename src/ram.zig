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

    pub fn init(buffer: []u8, ram_base_addr: usize, stack_allocation_size: usize) !RAM {
        if (buffer.len == 0 or stack_allocation_size == 0 or stack_allocation_size > buffer.len) {
            return error.InvalidMemoryConfiguration;
        }

        const effective_ram_end = ram_base_addr + buffer.len;

        return RAM{
            .buffer = buffer,
            .ram_base = ram_base_addr,
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
};
