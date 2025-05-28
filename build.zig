const std = @import("std");

pub fn build(b: *std.Build) void {
    // 1) Standard target & optimization flags for -Dtarget and -Doptimize
    const target = b.standardTargetOptions(.{}); // :contentReference[oaicite:0]{index=0}
    const optimize = b.standardOptimizeOption(.{}); // :contentReference[oaicite:1]{index=1}

    // Create a module for zlite that can be imported
    const zlite_module = b.createModule(.{
        .root_source_file = b.path("src/lib.zig"),
    });

    // 2) Build a static library from src/lib.zig
    const lib = b.addStaticLibrary(.{
        .name = "zlite",
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });
    lib.linkLibC();
    lib.linkSystemLibrary("sqlite3");

    // 3) Build an example executable from src/main.zig
    const exe = b.addExecutable(.{
        .name = "example",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe.linkLibC();
    exe.linkLibrary(lib);
    exe.linkSystemLibrary("sqlite3");
    
    // Add the zlite module to the executable so it can be imported
    exe.root_module.addImport("zlite", zlite_module);

    // 4) Install both artifacts so `zig build` actually does something useful
    b.installArtifact(lib);
    b.installArtifact(exe);

    // 5) Add a “run” step so `zig build run` will run your example
    //
    //    This creates a Run artifact and wires up a named step "run" that
    //    depends on it. Now:
    //
    //      zig build run
    //
    //    will build & then execute `./zig-out/bin/example`.
    //
    const run_cmd = b.addRunArtifact(exe); // :contentReference[oaicite:2]{index=2}
    run_cmd.step.dependOn(b.getInstallStep());
    const run_step = b.step("run", "Run the example executable");
    run_step.dependOn(&run_cmd.step);
}
