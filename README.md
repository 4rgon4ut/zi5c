# zi5c
Toy RISC-V VM written in zig

## TODO

```bash
zig build-exe tests/fixtures/zig/fib_5th.zig linker/startup.s  \
  -target riscv32-freestanding-musl \
  -mcpu=generic_rv32 \
  --script linker/linker_min.ld \
  --name program.elf \
  -O ReleaseSmall
```

- [ ] cli
- [ ] cleanup
- [ ] ecalls
