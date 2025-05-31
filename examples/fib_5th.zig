var volatile_sink: bool = false;

pub export fn main() void {
    const n_value: u32 = 5;
    const result = fib(n_value);

    volatile_sink = (result == 5);
}

fn fib(n: u32) u32 {
    if (n == 0) return 0;
    if (n == 1) return 1;
    return fib(n - 1) + fib(n - 2);
}
