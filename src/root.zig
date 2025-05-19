pub const VM = @import("vm.zig").VM;
pub const RAM = @import("ram.zig").RAM;
pub const CPU = @import("cpu.zig").CPU;

pub const loader = @import("loader.zig");
pub const decoder = @import("decoder.zig").Decoder;

pub const isa = struct {
    pub const abi_regs = @import("abi_regs.zig");
    pub const instruction_formats = @import("instruction_formats.zig");
    pub const ops = @import("ops_logic.zig");

    pub const encoding_consts = @import("encoding_constants.zig");
};
