# zi5c
Toy RISC-V VM written in zig

## TODO

```bash
zig build-exe examples/fib_5th.zig linker/startup.s  \
  -target riscv32-freestanding-musl \
  -mcpu generic_rv32 \
  --script linker/default.ld \
  -femit-bin zig-out/program.elf \
  -O ReleaseSmall
```
