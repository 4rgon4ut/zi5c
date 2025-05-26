var volatile_sink: bool = false;

// The Fibonacci function (unchanged).
fn fib(n: u32) u32 {
    if (n == 0) return 0;
    if (n == 1) return 1;
    return fib(n - 1) + fib(n - 2);
}

// Your main logic, now as a regular 'pub' function.
// It can return 'void' because _start will handle the infinite loop.
pub fn main() void {
    const n_value: u32 = 5;
    const result = fib(n_value);

    // Write to volatile_sink. fib(5) is 5, so (5 == 1) is false.
    // This assignment IS the side effect we need.
    volatile_sink = (result == 1);
}

// The ACTUAL entry point. It's exported so the linker finds it.
// It's 'noreturn' because it never returns; it ends in a loop.
export fn _start() noreturn {
    // 1. We assume your VM sets the Stack Pointer (sp) before jumping here.

    // 2. Call your main application code.
    main();

    while (true) {}
}
