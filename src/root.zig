const VM = @import("vm.zig").VM;
const RAM = @import("ram.zig").RAM;
const CPU = @import("cpu.zig").CPU;

const loader = @import("loader.zig");
const decoder = @import("decoder.zig").Decoder;

const isa = struct {
    pub const abi_regs = @import("abi_regs.zig");
    pub const instruction_formats = @import("instruction_formats.zig");
    pub const ops = @import("ops_logic.zig");

    pub const encoding_consts = @import("encoding_constants.zig");
};
