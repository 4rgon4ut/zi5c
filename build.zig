const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    // This creates a "module", which represents a collection of source files alongside
    // some compilation options, such as optimization mode and linked system libraries.
    // Every executable or library we compile will be based on one or more modules.
    const zi5c_core_mod = b.addModule("zi5c", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    // We will also create a module for our other entry point, 'main.zig'.
    const exe_mod = b.createModule(.{
        // `root_source_file` is the Zig "entry point" of the module. If a module
        // only contains e.g. external object files, you can make this `null`.
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Modules can depend on one another using the `std.Build.Module.addImport` function.
    // This is what allows Zig source code to use `@import("foo")` where 'foo' is not a
    // file path. In this case, we set up `exe_mod` to import `lib_mod`.
    exe_mod.addImport("zi5k", zi5c_core_mod); // Note: You're importing "zi5c_core_mod" as "zi5k" here.

    const exe = b.addExecutable(.{
        .name = "zi5k", // Your executable's output name (was "zi5c" in your original for exe name)
        .root_module = exe_mod, // Use the module defined for the executable's main
        // .link_libc = true, // Uncomment if your executable needs libc
    });
    b.installArtifact(exe);

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_exe = b.addRunArtifact(exe);

    run_exe.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_exe.addArgs(args);
    }

    const run_step = b.step("run", "Run the zi5c VM");
    run_step.dependOn(&run_exe.step);

    const all_tests_runner = b.addTest(.{
        .root_source_file = b.path("tests/testing_all.zig"), // Main entry point for all tests
        .target = target,
        .optimize = optimize,
        // .link_libc = true, // Uncomment if your tests need libc
    });

    // Corrected line: Call addImport on the root_module of the test runner
    all_tests_runner.root_module.addImport("zi5c", zi5c_core_mod);

    const run_all_tests_cmd = b.addRunArtifact(all_tests_runner);
    run_all_tests_cmd.cwd = b.path(".");

    // ... (definition of run_all_tests_cmd.cwd = b.path(".")) should remain if you
    // want tests to primarily access fixtures from their source location.

    // Modify the main "test" step to depend on the fixtures being installed.
    // This ensures the copy happens when 'zig build test' is run.
    const test_step = b.step("test", "Run all unit and integration tests");

    test_step.dependOn(&run_all_tests_cmd.step);
}
