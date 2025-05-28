pub const Trap = union(enum) {
    Requested: RequestedTrap,
    Fatal: FatalError,
};

pub const RequestedTrap = enum {
    ECALL,
    EBREAK,
};

pub const FatalError = error{
    Internal, // TODO: naming?

    MemoryOutOfBounds,
    MemoryUnalignedAccess,
    MemoryInvalidAccessSize,

    InstructionUnexpectedOpcode,
    InstructionInvalidEncoding,
    InstructionUnsupported,
};
