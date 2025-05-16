const std = @import("std");
const elf = std.elf;
const fs = std.fs;
const io = std.io;
const mem = std.mem;

const RAM = @import("ram.zig").RAM;
const RAM_BASE = @import("ram.zig").RAM_BASE;

const LoadResult = struct {
    entry_point: u32,
    heap_start: u32,
};

pub fn loadELF(ram: *RAM, path: []const u8) !LoadResult {
    var file = try fs.cwd().openFile(path, .{ .mode = .read_only });
    defer file.close();

    // 1. Use elf.Header.read to parse the header
    // This handles reading the first 64 bytes, magic check, class, endianness etc.
    const header = elf.Header.read(file) catch |err| {
        std.log.err("Failed to parse ELF header: {any}", .{err});
        return error.InvalidElfHeader;
    };

    // 2. Validate the parsed header based on our requirements
    // Check Class (We require 32-bit)
    if (header.is_64) { // header.is_64 is true if CLASS64 was detected
        std.log.err("Unsupported ELF class: Expected 32-bit (CLASS32), but file is 64-bit.", .{});
        return error.UnsupportedElfClass;
    }

    // TODO: check version?

    // Check Type (Executable)
    if (header.type != .EXEC) {
        std.log.err("Unsupported ELF type: Expected executable (ET_EXEC), got {any}", .{header.type});
        // Allow warning or return error based on strictness
        return error.InvalidElfClass; // Reusing error, consider a more specific one
    }

    // Check Machine (RISC-V)
    if (header.machine != .RISCV) {
        std.log.err("Unsupported architecture: Expected RISC-V (EM_RISCV), got {any}", .{header.machine});
        return error.UnsupportedArchitecture;
    }

    // Check if program headers exist
    if (header.phnum == 0) {
        std.log.err("No program headers found in ELF file.", .{});
        return error.NoProgramHeaders;
    }

    var highest_addr_used: u32 = RAM_BASE;
    var ph_iter = header.program_header_iterator(file);

    while (try ph_iter.next()) |phdr| {
        // pub const Elf64_Phdr = extern struct {
        //     p_type: Word,
        //     p_flags: Word,
        //     p_offset: Elf64_Off,
        //     p_vaddr: Elf64_Addr,
        //     p_paddr: Elf64_Addr,
        //     p_filesz: Elf64_Xword,
        //     p_memsz: Elf64_Xword,
        //     p_align: Elf64_Xword,
        // };
        if (phdr.p_type == elf.PT_LOAD) {
            // we need to cast to 32b types here since iterator returns only 64b types
            // its design choice by the lib author;
            // vm accepts only 32b elfs so we can cast it safely
            const vaddr = @as(elf.Elf32_Addr, @intCast(phdr.p_vaddr));
            const offset = @as(elf.Elf32_Off, @intCast(phdr.p_offset));
            const filesz = @as(elf.Word, @intCast(phdr.p_filesz));
            const memsz = @as(elf.Word, @intCast(phdr.p_memsz));

            // Basic sanity checks
            if (memsz < filesz) {
                std.log.err("Memory size (memsz) is less than file size (filesz): memsz = {}, filesz = {}", .{ memsz, filesz });
                return error.InvalidSegmentSizes; // Define this error
            }
            if (memsz == 0) {
                continue; // Go to the next program header
            }

            // BOUNDS CHECKS
            const segment_end: u32 = @intCast(vaddr + memsz);

            if (segment_end > ram.ram_end) {
                std.log.err("Segment end address 0x{x} exceeds RAM limit 0x{x}", .{ segment_end, ram.ram_end });
                return error.SegmentOutOfBounds;
            }

            if (segment_end > ram.stack_limit) {
                std.log.err("Segment end address 0x{x} exceeds stack limit 0x{x}", .{ segment_end, ram.stack_limit });
                return error.SegmentOutOfBounds;
            }

            if (filesz > 0) {
                std.log.debug("  Copying {} bytes from file offset {} to RAM address 0x{x}", .{
                    filesz, offset, vaddr,
                });

                // Get the destination slice in the RAM buffer
                // Since RAM_BASE is 0, vaddr is the direct start index
                const dest_slice = ram.buffer[vaddr .. vaddr + filesz];

                // Seek the ELF file to the segment's data offset
                try file.seekTo(offset);

                // Read exactly 'filesz' bytes from the file into the RAM slice
                file.reader().readNoEof(dest_slice) catch |err| {
                    std.log.err("Failed to read segment data from file: {any}", .{err});
                    // Distinguish EOF error (truncated file) from other errors
                    if (err == error.EndOfStream) {
                        return error.UnexpectedEOF; // Define this error
                    } else {
                        return error.ReadError;
                    }
                };
            } else {
                std.log.debug("  Segment has no data in file (filesz = 0)", .{});
            }

            if (memsz > filesz) {
                const bss_start_addr = vaddr + filesz;
                const bss_size = memsz - filesz;
                std.log.debug("  Zeroing BSS section: {} bytes starting at address 0x{x}", .{
                    bss_size, bss_start_addr,
                });

                // Calculate the slice in the RAM buffer for the BSS section
                // Since RAM_BASE is 0, addresses are direct indices
                const bss_slice = ram.buffer[bss_start_addr .. bss_start_addr + bss_size];

                // Fill the BSS slice with zeroes
                @memset(bss_slice, 0);
            }
            highest_addr_used = @max(highest_addr_used, segment_end);
            std.log.debug("  Segment processing complete. Highest address used so far: 0x{x}", .{highest_addr_used});
        }
    }

    std.log.info("Finished processing all program headers.", .{});

    const entry: u32 = @intCast(header.entry);

    return LoadResult{
        .entry_point = entry,
        .heap_start = highest_addr_used,
    };
}
