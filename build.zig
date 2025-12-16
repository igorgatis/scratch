const std = @import("std");

pub fn build(b: *std.Build) void {
    // Define the target: x86_64-freestanding
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .x86_64,
        .os_tag = .freestanding,
        .abi = .none,
    });

    // Optimize for size (ReleaseSmall)
    const optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = .ReleaseSmall });

    // Step 1: Compile hello.zig to an object file
    const obj = b.addObject(.{
        .name = "hello",
        .root_source_file = b.path("hello.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Equivalent to -fno-stack-check
    obj.root_module.stack_check = false;
    // Equivalent to -lc
    obj.root_module.link_libc = true;

    // Define paths to Cosmopolitan tools
    // Allow overriding via -Dcosmocc_dir=/path/to/cosmocc
    const cosmocc_dir = b.option([]const u8, "cosmocc_dir", "Path to cosmocc directory") orelse "/tmp/cosmocc";

    // Normalize path to use forward slashes for shell compatibility
    const cosmocc_dir_fixed = b.allocator.dupe(u8, cosmocc_dir) catch @panic("OOM");
    std.mem.replaceScalar(u8, cosmocc_dir_fixed, '\\', '/');

    // Construct paths manually with forward slashes to avoid Windows backslash issues in 'sh'
    const cc_exe = b.fmt("{s}/bin/x86_64-unknown-cosmo-cc", .{cosmocc_dir_fixed});
    const objcopy_exe = b.fmt("{s}/bin/x86_64-linux-cosmo-objcopy", .{cosmocc_dir_fixed});

    // Step 2: Link the object file using cosmocc
    const install_step = b.getInstallStep();
    _ = b.getInstallPath(.bin, ""); // absolute path to zig-out/bin

    // Output paths - we want these relative to CWD for the command, but we are inside the build runner.
    // 'zig-out/bin' is standard.
    const elf_out = "zig-out/bin/hello.elf";
    const com_out = "zig-out/bin/hello.com";

    // Ensure directory exists.
    // We use a custom step to create the directory to avoid "mkdir" system command issues if possible,
    // but addSystemCommand "mkdir -p" is generally safe in the environments we target (bash available).
    const mkdir_cmd = b.addSystemCommand(&.{ "mkdir", "-p", "zig-out/bin" });

    // Wrapper for shell execution.
    const link_cmd = b.addSystemCommand(&.{ "sh", "-c" });
    // "cc -Os -o zig-out/bin/hello.elf $0"
    const link_script = b.fmt("\"{s}\" -Os -o \"{s}\" \"$0\"", .{ cc_exe, elf_out });
    link_cmd.addArg(link_script);
    link_cmd.addArtifactArg(obj);

    link_cmd.step.dependOn(&mkdir_cmd.step);

    // Step 3: Convert ELF to APE using objcopy
    const objcopy_cmd = b.addSystemCommand(&.{ "sh", "-c" });
    const objcopy_script = b.fmt("\"{s}\" -SO binary \"{s}\" \"{s}\"", .{ objcopy_exe, elf_out, com_out });
    objcopy_cmd.addArg(objcopy_script);

    // Dependency chain
    objcopy_cmd.step.dependOn(&link_cmd.step);

    install_step.dependOn(&objcopy_cmd.step);
}
