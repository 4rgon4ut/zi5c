const std = @import("std");

pub const RamConfig = struct {
    stack_size: usize,
    heap_size: usize,
};

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

pub const RAM = struct { main_memory: []u8 };
