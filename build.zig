const std = @import("std");

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    // freestanding x86 no abi
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .x86,
        .os_tag = .freestanding,
        .abi = .none,
        //disable sse and avx
        .cpu_features_sub = std.Target.x86.featureSet(&.{
            .sse,
            .sse2,
        }),
    });

    const kernel_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        //disable redzone
        .red_zone = false,
    });

    const kernel = b.addExecutable(.{
        .name = "kernel",
        .root_module = kernel_mod,
    });

    kernel.setLinkerScript(b.path("linker.ld"));

    b.installArtifact(kernel);

    //zig build run will open qemu
    const run_cmd = b.addSystemCommand(&.{
        "qemu-system-i386",
        "-kernel",
    });
    run_cmd.addArtifactArg(kernel);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Boot the kernel in QEMU");
    run_step.dependOn(&run_cmd.step);
}
