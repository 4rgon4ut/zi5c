const std = @import("std");

const rv_consts = @import("encoding_constants.zig");
const ops = @import("ops_logic.zig");
const CPU = @import("cpu.zig").CPU;

const FatalError = @import("traps.zig").FatalError;
const Trap = @import("traps.zig").Trap;

pub const DecodedInstruction = union(enum) {
    I: InstructionI,
    R: InstructionR,
    S: InstructionS,
    B: InstructionB,
    U: InstructionU,
    J: InstructionJ,

    pub fn execute(self: *const DecodedInstruction, cpu: *CPU) ?Trap {
        switch (self.*) {
            .R => |r_payload| return r_payload.execute(cpu),
            .I => |i_payload| return i_payload.execute(cpu),
            .S => |s_payload| return s_payload.execute(cpu),
            .B => |b_payload| return b_payload.execute(cpu),
            .U => |u_payload| return u_payload.execute(cpu),
            .J => |j_payload| return j_payload.execute(cpu),
        }
    }

    pub fn display(self: *const DecodedInstruction) void {
        switch (self.*) {
            .R => |r_payload| r_payload.display(),
            .I => |i_payload| i_payload.display(),
            .S => |s_payload| s_payload.display(),
            .B => |b_payload| b_payload.display(),
            .U => |u_payload| u_payload.display(),
            .J => |j_payload| j_payload.display(),
        }
    }
};

pub const InstructionI = struct {
    name: []const u8,

    rd: u5,
    rs1: u5,
    imm: i32,

    op: ops.I_OP,

    pub fn init(
        opcode: u7,
        rd: u5,
        rs1: u5,
        funct3: u3,
        imm: i32,
    ) FatalError!InstructionI {
        var name: []const u8 = "UNDEFINED_I";
        var op: ops.I_OP = undefined;

        switch (opcode) {
            rv_consts.OPCODE_OP_IMM => {
                switch (funct3) {
                    rv_consts.FUNCT3_ADDI => {
                        op = &ops.ADDI;
                        name = "ADDI";
                    },
                    rv_consts.FUNCT3_SLTI => {
                        op = &ops.SLTI;
                        name = "SLTI";
                    },
                    rv_consts.FUNCT3_SLTIU => {
                        op = &ops.SLTIU;
                        name = "SLTIU";
                    },
                    rv_consts.FUNCT3_XORI => {
                        op = &ops.XORI;
                        name = "XORI";
                    },
                    rv_consts.FUNCT3_ORI => {
                        op = &ops.ORI;
                        name = "ORI";
                    },
                    rv_consts.FUNCT3_ANDI => {
                        op = &ops.ANDI;
                        name = "ANDI";
                    },
                    rv_consts.FUNCT3_SLLI => {
                        // upper 7 bits of immediate field must be 0
                        if ((imm >> 5) & 0x7F == 0) {
                            op = &ops.SLLI;
                            name = "SLLI";
                        } else {
                            std.log.err("Invalid encoding for SLLI (upper imm bits not zero)", .{});
                            return FatalError.InstructionInvalidEncoding;
                        }
                    },
                    rv_consts.FUNCT3_SRLI_SRAI => {
                        // SRLI/SRAI differentiated by bit 30 (funct7[5]) in immediate field
                        const funct7_like_bits = (@as(u32, @bitCast(imm)) >> 5) & 0x7F;
                        if (funct7_like_bits == rv_consts.FUNCT7_IN_IMM_SRLI) {
                            op = &ops.SRLI;
                            name = "SRLI";
                        } else if (funct7_like_bits == rv_consts.FUNCT7_IN_IMM_SRAI) {
                            op = &ops.SRAI;
                            name = "SRAI";
                        } else {
                            std.log.err("Invalid encoding for SRLI/SRAI (upper imm bits mismatch)", .{});
                            return FatalError.InstructionInvalidEncoding;
                        }
                    },
                }
            },
            rv_consts.OPCODE_LOAD => {
                switch (funct3) {
                    rv_consts.FUNCT3_LB => {
                        op = &ops.LB;
                        name = "LB";
                    },
                    rv_consts.FUNCT3_LH => {
                        op = &ops.LH;
                        name = "LH";
                    },
                    rv_consts.FUNCT3_LW => {
                        op = &ops.LW;
                        name = "LW";
                    },
                    rv_consts.FUNCT3_LBU => {
                        op = &ops.LBU;
                        name = "LBU";
                    },
                    rv_consts.FUNCT3_LHU => {
                        op = &ops.LHU;
                        name = "LHU";
                    },

                    else => {
                        // std.log.err("Invalid funct3 for LOAD instruction: {b}", .{funct3});
                        return FatalError.InstructionInvalidEncoding;
                    },
                }
            },
            rv_consts.OPCODE_JALR => {
                if (funct3 == 0b000) { // JALR has funct3=0
                    op = &ops.JALR;
                    name = "JALR";
                } else {
                    // std.log.err("Invalid funct3 for JALR: {b}", .{funct3});
                    return FatalError.InstructionInvalidEncoding;
                }
            },
            rv_consts.OPCODE_SYSTEM => {
                switch (funct3) {
                    rv_consts.FUNCT3_PRIV => {
                        switch (imm) {
                            0 => {
                                op = &ops.ECALL;
                                name = "ECALL";
                            },
                            1 => {
                                op = &ops.EBREAK;
                                name = "EBREAK";
                            },
                            else => {
                                std.log.err("Unsupported SYSTEM/PRIV instruction (imm={d})", .{imm});
                                return FatalError.InstructionUnsupported;
                            },
                        }
                    },
                    else => {
                        std.log.err("Unsupported funct3 for SYSTEM instruction: {b}", .{funct3});
                        return FatalError.InstructionUnsupported;
                    },
                }
            },
            rv_consts.OPCODE_MISC_MEM => {
                // TODO: Implement MISC_MEM instructions
                return FatalError.InstructionUnsupported;
            },
            else => {
                // std.log.err("Invalid/Unexpected opcode (0x{x:02X}) passed to InstructionI.init", .{opcode});
                return FatalError.InstructionUnsupported;
            },
        }

        return InstructionI{
            .name = name,
            .rd = rd,
            .rs1 = rs1,
            .imm = imm,
            .op = op,
        };
    }

    // TODO: rename
    pub fn display(self: *const InstructionI) void {
        std.log.debug("INSTRUCTION: <{s}> rd: {d} (0x{X:0>8}), rs1: {d} (0x{X:0>8}), imm: {d} (0x{X:0>8})\n", .{
            self.name,
            self.rd,
            self.rd,
            self.rs1,
            self.rs1,
            self.imm,
            self.imm,
        });
    }

    pub fn execute(self: *const InstructionI, cpu: *CPU) ?Trap {
        return self.op(cpu, self.rd, self.rs1, self.imm);
    }
};

pub const InstructionR = struct {
    name: []const u8,

    rd: u5,
    rs1: u5,
    rs2: u5,

    op: ops.R_OP,

    pub fn init(
        opcode: u7,
        rd: u5,
        rs1: u5,
        rs2: u5,
        funct3: u3,
        funct7: u7,
    ) FatalError!InstructionR {
        var name: []const u8 = "UNDEFINED_R";
        var op: ops.R_OP = undefined;

        switch (opcode) {
            rv_consts.OPCODE_OP => {
                switch (funct3) {
                    rv_consts.FUNCT3_ADD_SUB => {
                        switch (funct7) {
                            rv_consts.FUNCT7_ADD => {
                                op = &ops.ADD;
                                name = "ADD";
                            },
                            rv_consts.FUNCT7_SUB => {
                                op = &ops.SUB;
                                name = "SUB";
                            },
                            else => {
                                // std.log.err("Invalid funct7 for ADD/SUB: {b}", .{funct7});
                                return FatalError.InstructionInvalidEncoding;
                            },
                        }
                    },
                    rv_consts.FUNCT3_SLL => {
                        op = &ops.SLL;
                        name = "SLL";
                    },
                    rv_consts.FUNCT3_SLT => {
                        op = &ops.SLT;
                        name = "SLT";
                    },
                    rv_consts.FUNCT3_SLTU => {
                        op = &ops.SLTU;
                        name = "SLTU";
                    },
                    rv_consts.FUNCT3_XOR => {
                        op = &ops.XOR;
                        name = "XOR";
                    },
                    rv_consts.FUNCT3_SRL_SRA => {
                        if (funct7 == rv_consts.FUNCT7_SRL) {
                            op = &ops.SRL;
                            name = "SRL";
                        } else if (funct7 == rv_consts.FUNCT7_SRA) {
                            op = &ops.SRA;
                            name = "SRA";
                        }
                    },
                    rv_consts.FUNCT3_OR => {
                        op = &ops.OR;
                        name = "OR";
                    },
                    rv_consts.FUNCT3_AND => {
                        op = &ops.AND;
                        name = "AND";
                    },
                }
            },
            else => {
                // std.log.err("Invalid/Unexpected opcode (0x{x:02X}) passed to InstructionR.init", .{opcode});
                return FatalError.InstructionUnexpectedOpcode;
            },
        }

        return InstructionR{
            .name = name,
            .rd = rd,
            .rs1 = rs1,
            .rs2 = rs2,
            .op = op,
        };
    }

    pub fn display(self: *const InstructionR) void {
        std.log.debug("INSTRUCTION: <{s}> rd: {d} (0x{X:0>8}), rs1: {d} (0x{X:0>8}), rs2: {d} (0x{X:0>8})\n", .{
            self.name,
            self.rd,
            self.rd,
            self.rs1,
            self.rs1,
            self.rs2,
            self.rs2,
        });
    }

    pub fn execute(self: *const InstructionR, cpu: *CPU) ?Trap {
        return self.op(cpu, self.rd, self.rs1, self.rs2);
    }
};

pub const InstructionS = struct {
    name: []const u8,

    rs1: u5,
    rs2: u5,
    imm: i32,

    op: ops.S_OP,

    pub fn init(opcode: u7, rs1: u5, rs2: u5, funct3: u3, imm: i32) FatalError!InstructionS {
        var name: []const u8 = "UNDEFINED_S";
        var op: ops.S_OP = undefined;

        switch (opcode) {
            rv_consts.OPCODE_STORE => {
                switch (funct3) {
                    rv_consts.FUNCT3_SB => {
                        op = &ops.SB;
                        name = "SB";
                    },
                    rv_consts.FUNCT3_SH => {
                        op = &ops.SH;
                        name = "SH";
                    },
                    rv_consts.FUNCT3_SW => {
                        op = &ops.SW;
                        name = "SW";
                    },
                    else => {
                        // std.log.err("Invalid funct3 for S-type instruction: {b}", .{funct3});
                        return FatalError.InstructionInvalidEncoding;
                    },
                }
            },
            else => {
                // std.log.err("Invalid/Unexpected opcode (0x{x:02X}) passed to InstructionS.init", .{opcode});
                return FatalError.InstructionUnexpectedOpcode;
            },
        }

        return InstructionS{
            .name = name,
            .rs1 = rs1,
            .rs2 = rs2,
            .imm = imm,
            .op = op,
        };
    }

    pub fn display(self: *const InstructionS) void {
        std.log.debug("INSTRUCTION: <{s}> rs1: {d} (0x{X:0>8}), rs2: {d} (0x{X:0>8}), imm: {d} (0x{X:0>8})\n", .{
            self.name,
            self.rs1,
            self.rs1,
            self.rs2,
            self.rs2,
            self.imm,
            self.imm,
        });
    }
    pub fn execute(self: *const InstructionS, cpu: *CPU) ?Trap {
        // cpu: *CPU, rs1: u5, rs2: u5, imm: i32
        return self.op(cpu, self.rs1, self.rs2, self.imm);
    }
};

pub const InstructionB = struct {
    name: []const u8,

    rs1: u5,
    rs2: u5,
    imm: i32,

    op: ops.B_OP,

    pub fn init(opcode: u7, rs1: u5, rs2: u5, funct3: u3, imm: i32) FatalError!InstructionB {
        var name: []const u8 = "UNDEFINED_B";
        var op: ops.B_OP = undefined;

        switch (opcode) {
            rv_consts.OPCODE_BRANCH => {
                switch (funct3) {
                    rv_consts.FUNCT3_BEQ => {
                        op = &ops.BEQ;
                        name = "BEQ";
                    },
                    rv_consts.FUNCT3_BNE => {
                        op = &ops.BNE;
                        name = "BNE";
                    },
                    rv_consts.FUNCT3_BLT => {
                        op = &ops.BLT;
                        name = "BLT";
                    },
                    rv_consts.FUNCT3_BGE => {
                        op = &ops.BGE;
                        name = "BGE";
                    },
                    rv_consts.FUNCT3_BLTU => {
                        op = &ops.BLTU;
                        name = "BLTU";
                    },
                    rv_consts.FUNCT3_BGEU => {
                        op = &ops.BGEU;
                        name = "BGEU";
                    },
                    else => {
                        // std.log.err("Invalid funct3 for B-type instruction: {b}", .{funct3});
                        return FatalError.InstructionInvalidEncoding;
                    },
                }
            },
            else => {
                // std.log.err("Invalid/Unexpected opcode (0x{x:02X}) passed to InstructionB.init", .{opcode});
                return FatalError.InstructionUnexpectedOpcode;
            },
        }

        return InstructionB{
            .name = name,
            .rs1 = rs1,
            .rs2 = rs2,
            .imm = imm,
            .op = op,
        };
    }

    pub fn display(self: *const InstructionB) void {
        std.log.debug("INSTRUCTION: <{s}> rs1: {d} (0x{X:0>8}), rs2: {d} (0x{X:0>8}), imm: {d} (0x{X:0>8})\n", .{
            self.name,
            self.rs1,
            self.rs1,
            self.rs2,
            self.rs2,
            self.imm,
            self.imm,
        });
    }

    pub fn execute(self: *const InstructionB, cpu: *CPU) ?Trap {
        // cpu: *CPU, rs1: u5, rs2: u5, imm: i32
        return self.op(cpu, self.rs1, self.rs2, self.imm);
    }
};

pub const InstructionU = struct {
    name: []const u8,

    rd: u5,
    imm: i32,

    op: ops.U_OP,

    pub fn init(opcode: u7, rd: u5, imm: i32) FatalError!InstructionU {
        var name: []const u8 = "UNDEFINED_U";
        var op: ops.U_OP = undefined;

        switch (opcode) {
            rv_consts.OPCODE_LUI => {
                op = &ops.LUI;
                name = "LUI";
            },
            rv_consts.OPCODE_AUIPC => {
                op = &ops.AUIPC;
                name = "AUIPC";
            },
            else => {
                // std.log.err("Invalid/Unexpected opcode (0x{x:02X}) passed to InstructionU.init", .{opcode});
                return FatalError.InstructionUnexpectedOpcode;
            },
        }

        return InstructionU{
            .name = name,
            .rd = rd,
            .imm = imm,
            .op = op,
        };
    }

    pub fn display(self: *const InstructionU) void {
        std.log.debug("INSTRUCTION: <{s}> rd: {d} (0x{X:0>8}), imm: {d} (0x{X:0>8})\n", .{
            self.name,
            self.rd,
            self.rd,
            self.imm,
            self.imm,
        });
    }

    pub fn execute(self: *const InstructionU, cpu: *CPU) ?Trap {
        // cpu: *CPU, rd: u5, imm: i32
        return self.op(cpu, self.rd, self.imm);
    }
};

pub const InstructionJ = struct {
    name: []const u8,

    rd: u5,
    imm: i32,

    op: ops.J_OP,

    pub fn init(opcode: u7, rd: u5, imm: i32) FatalError!InstructionJ {
        var name: []const u8 = "UNDEFINED_J";
        var op: ops.J_OP = undefined;

        switch (opcode) {
            rv_consts.OPCODE_JAL => {
                op = &ops.JAL;
                name = "JAL";
            },
            else => {
                // std.log.err("Invalid/Unexpected opcode (0x{x:02X}) passed to InstructionJ.init", .{opcode});
                return FatalError.InstructionUnexpectedOpcode;
            },
        }

        return InstructionJ{
            .name = name,
            .rd = rd,
            .imm = imm,
            .op = op,
        };
    }

    pub fn display(self: *const InstructionJ) void {
        std.log.debug("INSTRUCTION: <{s}> rd: {d} (0x{X:0>8}), imm: {d} (0x{X:0>8})\n", .{
            self.name,
            self.rd,
            self.rd,
            self.imm,
            self.imm,
        });
    }

    pub fn execute(self: *const InstructionJ, cpu: *CPU) ?Trap {
        // cpu: *CPU, rd: u5, imm: i32
        return self.op(cpu, self.rd, self.imm);
    }
};
