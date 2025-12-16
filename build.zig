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
    const cosmocc_dir = "/tmp/cosmocc/bin";
    const cc_exe = b.pathJoin(&.{ cosmocc_dir, "x86_64-unknown-cosmo-cc" });
    const objcopy_exe = b.pathJoin(&.{ cosmocc_dir, "x86_64-linux-cosmo-objcopy" });

    // Step 2: Link the object file using cosmocc
    // We'll output to zig-out/bin via the install step mechanics or manually.
    // For 'addSystemCommand', we can specify outputs if we want to track them.

    // We use a custom installation directory 'zig-out/bin' relative to prefix.
    const install_step = b.getInstallStep();
    _ = b.getInstallPath(.bin, ""); // absolute path to zig-out/bin

    // Since we can't easily get the absolute path of 'bin_path' at configuration time
    // without some side effects, and system commands run at build time,
    // we will chain the commands to output to a specific location or rely on cwd.

    // Let's use 'zig-out/bin/hello.elf' and 'zig-out/bin/hello.com'.
    // Note: Zig runs commands from the project root.

    const elf_out = b.pathJoin(&.{ "zig-out", "bin", "hello.elf" });
    const com_out = b.pathJoin(&.{ "zig-out", "bin", "hello.com" });

    // Ensure directory exists
    const mkdir_cmd = b.addSystemCommand(&.{ "mkdir", "-p", "zig-out/bin" });

    const link_cmd = b.addSystemCommand(&.{ "sh", "-c" });
    // "cc -Os -o zig-out/bin/hello.elf $0"
    const link_script = b.fmt("\"{s}\" -Os -o \"{s}\" \"$0\"", .{ cc_exe, elf_out });
    link_cmd.addArg(link_script);
    link_cmd.addArtifactArg(obj);

    link_cmd.step.dependOn(&mkdir_cmd.step);

    // Step 3: Convert ELF to APE using objcopy
    const objcopy_cmd = b.addSystemCommand(&.{ "sh", "-c" });
    // "objcopy -SO binary zig-out/bin/hello.elf zig-out/bin/hello.com"
    const objcopy_script = b.fmt("\"{s}\" -SO binary \"{s}\" \"{s}\"", .{ objcopy_exe, elf_out, com_out });
    objcopy_cmd.addArg(objcopy_script);

    // Dependency chain
    objcopy_cmd.step.dependOn(&link_cmd.step);

    install_step.dependOn(&objcopy_cmd.step);
}
