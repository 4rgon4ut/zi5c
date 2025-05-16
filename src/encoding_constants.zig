// --- Field Types ---
pub const Opcode = u7;
pub const Funct3 = u3;
pub const Funct7 = u7;

// --- Opcodes (RV32I Base) ---
pub const OPCODE_LUI: Opcode = 0b0110111;
pub const OPCODE_AUIPC: Opcode = 0b0010111;
pub const OPCODE_JAL: Opcode = 0b1101111;
pub const OPCODE_JALR: Opcode = 0b1100111; // I-Type
pub const OPCODE_BRANCH: Opcode = 0b1100011; // B-Type
pub const OPCODE_LOAD: Opcode = 0b0000011; // I-Type
pub const OPCODE_STORE: Opcode = 0b0100011; // S-Type
pub const OPCODE_OP_IMM: Opcode = 0b0010011; // I-Type (Arithmetic/Logical Immediate)
pub const OPCODE_OP: Opcode = 0b0110011; // R-Type (Register-Register)
pub const OPCODE_MISC_MEM: Opcode = 0b0001111; // I-Type (FENCE, FENCE.I)
pub const OPCODE_SYSTEM: Opcode = 0b1110011; // I-Type (ECALL, EBREAK, CSR)

// --- Funct3 Constants (Grouped by Opcode/Use) ---

// For OPCODE_BRANCH (B-Type)
pub const FUNCT3_BEQ: Funct3 = 0b000;
pub const FUNCT3_BNE: Funct3 = 0b001;
pub const FUNCT3_BLT: Funct3 = 0b100;
pub const FUNCT3_BGE: Funct3 = 0b101;
pub const FUNCT3_BLTU: Funct3 = 0b110;
pub const FUNCT3_BGEU: Funct3 = 0b111;

// For OPCODE_LOAD (I-Type)
pub const FUNCT3_LB: Funct3 = 0b000;
pub const FUNCT3_LH: Funct3 = 0b001;
pub const FUNCT3_LW: Funct3 = 0b010;
pub const FUNCT3_LBU: Funct3 = 0b100;
pub const FUNCT3_LHU: Funct3 = 0b101;

// For OPCODE_STORE (S-Type)
pub const FUNCT3_SB: Funct3 = 0b000;
pub const FUNCT3_SH: Funct3 = 0b001;
pub const FUNCT3_SW: Funct3 = 0b010;

// For OPCODE_OP_IMM (I-Type)
pub const FUNCT3_ADDI: Funct3 = 0b000;
pub const FUNCT3_SLTI: Funct3 = 0b010;
pub const FUNCT3_SLTIU: Funct3 = 0b011;
pub const FUNCT3_XORI: Funct3 = 0b100;
pub const FUNCT3_ORI: Funct3 = 0b110;
pub const FUNCT3_ANDI: Funct3 = 0b111;
pub const FUNCT3_SLLI: Funct3 = 0b001; // Requires check on upper bits of imm field
pub const FUNCT3_SRLI_SRAI: Funct3 = 0b101; // Requires check on funct7 bits (in imm field)

// For OPCODE_OP (R-Type)
pub const FUNCT3_ADD_SUB: Funct3 = 0b000; // Differentiated by Funct7
pub const FUNCT3_SLL: Funct3 = 0b001;
pub const FUNCT3_SLT: Funct3 = 0b010;
pub const FUNCT3_SLTU: Funct3 = 0b011;
pub const FUNCT3_XOR: Funct3 = 0b100;
pub const FUNCT3_SRL_SRA: Funct3 = 0b101; // Differentiated by Funct7
pub const FUNCT3_OR: Funct3 = 0b110;
pub const FUNCT3_AND: Funct3 = 0b111;

// For OPCODE_MISC_MEM (I-Type)
pub const FUNCT3_FENCE: Funct3 = 0b000;
pub const FUNCT3_FENCE_I: Funct3 = 0b001;

// For OPCODE_SYSTEM (I-Type)
pub const FUNCT3_PRIV: Funct3 = 0b000; // ECALL, EBREAK, CSRRW/RS/RC etc. Differentiated by imm/rs1/rd fields
pub const FUNCT3_CSRRW: Funct3 = 0b001;
pub const FUNCT3_CSRRS: Funct3 = 0b010;
pub const FUNCT3_CSRRC: Funct3 = 0b011;
pub const FUNCT3_CSRRWI: Funct3 = 0b101;
pub const FUNCT3_CSRRSI: Funct3 = 0b110;
pub const FUNCT3_CSRRCI: Funct3 = 0b111;

// --- Funct7 Constants (Grouped by Opcode/Use) ---

// For OPCODE_OP / FUNCT3_ADD_SUB (R-Type)
pub const FUNCT7_ADD: Funct7 = 0b0000000;
pub const FUNCT7_SUB: Funct7 = 0b0100000;

// For OPCODE_OP / FUNCT3_SRL_SRA (R-Type)
pub const FUNCT7_SRL: Funct7 = 0b0000000;
pub const FUNCT7_SRA: Funct7 = 0b0100000;

// For OPCODE_OP_IMM / FUNCT3_SRLI_SRAI (I-Type)
// Note: These check bits 31:25, which overlap with the immediate field
pub const FUNCT7_IN_IMM_SRLI: Funct7 = 0b0000000; // Check bit 30 == 0
pub const FUNCT7_IN_IMM_SRAI: Funct7 = 0b0100000; // Check bit 30 == 1
