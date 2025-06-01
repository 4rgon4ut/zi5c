# zi5c


## What

__Toy__ RISC-V VM supporting RV32I base set.

- no deps
- single threaded
- guest RAM is a single buffer
- guest programs are mapped directly into RAM from ELFs
- for zig programs, assembly `_start` routine initializes environment and calls `main` (`./linker/startup.s`)
- guest programs are intended for a freestanding env
- static linking
- *SYSTEM/SYNC calls mostly WIP (`CSR/FENCE`)

  Only two `ECALL` supported: 
  - `exit (93)`
  - `write (64)`
  
  `EBREAK` works as a halt request

## Why

For learning and fun

## How to use
__Build the vm binary, it will be put under `./zig-out/bin/zi5c`:__
```bash
zig build
```

Then we need to create proper elf (the program vm intended to run). Note that bash script generates linker script in `zig-out/generated.ld` from `linker/template.ld`. Its necessary to specify total ram size that matches the vm configuration size (via `-r=<hex_size>`, `default = 0x1000000 (1mb)` for both linker and vm). VM accepts arbitrary ram sizes and the one used should be equal for this step to match and properly link elf.

*This probably can be tailored together via `build.zig` or other clever way but meh. (LLD in `zig-build exe` does not support passing variables via flags)

__Build and link elf:__
```bash
sh ./build_elf.sh -f examples/fib_5th.zig -r 0x100000
```

ELF file after this command will be `zig-out/program.elf`.

Script usage:
```log
Usage: ./build_elf.sh -f <zig_source_file> [-r <ram_size_hex>] [-a <startup_s_file>] [-o <output_elf_file>]
  -f <zig_source_file> : Path to the main Zig source file (required).
  -r <ram_size_hex>    : RAM size in hexadecimal (e.g., 0x80000). Default: 0x100000.
  -a <startup_s_file>  : Path to the assembly startup file. Default: linker/startup.s.
  -o <output_elf_file> : Path for the output ELF file. Default: zig-out/program.elf.
```

__Start execution:__
```bash
./zig-out/bin/zi5k -e ./program.elf 
```
Default ram size is `0x1000000 (1mb)`

VM cli:
```log
Usage: zi5c [OPTIONS] --exe <ELF_FILE>

  --exe, -e <ELF_FILE>     Path to the RISC-V ELF executable (mandatory)

Options:
  --mem, -m <SIZE_BYTES>   Total memory size for VM (default: 1048576 bytes)
  --stack, -s <SIZE_BYTES> Stack size for VM (default: 131072 bytes, part of total memory)
  --steps <COUNT>          Maximum execution steps (default: 0, unlimited)
  --help, -h               Display this help message and exit                   
```

### Your own zig program

Make sure to make your `main` function exported to use it as an entry point:
```zig
pub export fn main() void {}
```
