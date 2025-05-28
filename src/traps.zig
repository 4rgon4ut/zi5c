pub const Trap = union(enum) { Requested, Debug, Fatal: FatalError };

pub const FatalError = error{
    Internal, // TODO: naming?

    MemoryOutOfBounds,
    MemoryUnalignedAccess,
    MemoryInvalidAccessSize,

    InstructionUnexpectedOpcode,
    InstructionInvalidEncoding,
    InstructionUnsupported,
};
