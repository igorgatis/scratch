const std = @import("std");
const builtin = @import("builtin");

const MISE_REPO_URL = "https://github.com/jdx/mise";
// Hardcoded version
const MISE_VERSION = "v2025.12.8";
const CACHE_DIR_NAME = "mise-" ++ MISE_VERSION;

// Cosmo APE unzip binary URL
const COSMO_UNZIP_URL = "https://cosmo.zip/pub/cosmos/bin/unzip";

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const os_tag = builtin.os.tag;
    const cpu_arch = builtin.cpu.arch;

    const cache_dir_path = try getCacheDir(allocator);
    defer allocator.free(cache_dir_path);

    try std.fs.cwd().makePath(cache_dir_path);

    const exe_name = if (os_tag == .windows) "mise.exe" else "mise";
    const exe_path = try std.fs.path.join(allocator, &[_][]const u8{ cache_dir_path, exe_name });
    defer allocator.free(exe_path);

    if (!fileExists(exe_path)) {
        std.debug.print("mise not found at {s}. Downloading {s}...\n", .{ exe_path, MISE_VERSION });
        try downloadMise(allocator, cache_dir_path, exe_path, os_tag, cpu_arch);
    } else {
        std.debug.print("mise found at {s}.\n", .{exe_path});
    }

    var args_iter = try std.process.argsWithAllocator(allocator);
    defer args_iter.deinit();

    // Skip the first arg (executable name)
    _ = args_iter.next();

    var mise_args = std.ArrayList([]const u8).init(allocator);
    defer mise_args.deinit();

    while (args_iter.next()) |arg| {
        try mise_args.append(try allocator.dupe(u8, arg));
    }
    defer {
        for (mise_args.items) |arg| {
            allocator.free(arg);
        }
    }

    // Execute mise
    var argv = std.ArrayList([]const u8).init(allocator);
    defer argv.deinit();
    try argv.append(exe_path);
    try argv.appendSlice(mise_args.items);

    var proc = std.process.Child.init(argv.items, allocator);

    // Inherit stdout/stderr/stdin
    proc.stdin_behavior = .Inherit;
    proc.stdout_behavior = .Inherit;
    proc.stderr_behavior = .Inherit;

    const term = try proc.spawnAndWait();

    switch (term) {
        .Exited => |code| std.process.exit(code),
        .Signal => |sig| {
            std.debug.print("Process terminated by signal: {}\n", .{sig});
            std.process.exit(128 + @as(u8, @intCast(sig)));
        },
        .Stopped => |sig| {
            std.debug.print("Process stopped by signal: {}\n", .{sig});
            std.process.exit(128 + @as(u8, @intCast(sig)));
        },
        .Unknown => |code| {
            std.debug.print("Process terminated unknown: {}\n", .{code});
            std.process.exit(1);
        },
    }
}

fn getCacheDir(allocator: std.mem.Allocator) ![]const u8 {
    var env_map = try std.process.getEnvMap(allocator);
    defer env_map.deinit();

    if (builtin.os.tag == .windows) {
        if (env_map.get("LOCALAPPDATA")) |local_app_data| {
            return std.fs.path.join(allocator, &[_][]const u8{ local_app_data, CACHE_DIR_NAME });
        }
        if (env_map.get("USERPROFILE")) |user_profile| {
            return std.fs.path.join(allocator, &[_][]const u8{ user_profile, "AppData", "Local", CACHE_DIR_NAME });
        }
        if (env_map.get("TEMP")) |temp| {
            return std.fs.path.join(allocator, &[_][]const u8{ temp, CACHE_DIR_NAME });
        }
        if (env_map.get("TMP")) |tmp| {
            return std.fs.path.join(allocator, &[_][]const u8{ tmp, CACHE_DIR_NAME });
        }
    } else {
        if (env_map.get("XDG_CACHE_HOME")) |xdg_cache| {
            return std.fs.path.join(allocator, &[_][]const u8{ xdg_cache, CACHE_DIR_NAME });
        }
        if (env_map.get("HOME")) |home| {
            return std.fs.path.join(allocator, &[_][]const u8{ home, ".cache", CACHE_DIR_NAME });
        }
        // Fallback to /tmp
        return std.fs.path.join(allocator, &[_][]const u8{ "/tmp", CACHE_DIR_NAME });
    }
    return error.CacheDirNotFound;
}

fn fileExists(path: []const u8) bool {
    std.fs.accessAbsolute(path, .{}) catch return false;
    return true;
}

fn downloadMise(allocator: std.mem.Allocator, cache_dir: []const u8, exe_path: []const u8, os_tag: std.Target.Os.Tag, cpu_arch: std.Target.Cpu.Arch) !void {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arena_allocator = arena.allocator();

    // Construct URL directly
    // Linux x64: https://github.com/jdx/mise/releases/download/v2025.12.8/mise-v2025.12.8-linux-x64
    // Windows x64: https://github.com/jdx/mise/releases/download/v2025.12.8/mise-v2025.12.8-windows-x64.zip

    const os_str = switch (os_tag) {
        .linux => "linux",
        .macos => "macos",
        .windows => "windows",
        else => return error.UnsupportedOS,
    };

    const arch_str = switch (cpu_arch) {
        .x86_64 => "x64",
        .aarch64 => "arm64",
        .aarch64_be => "arm64",
        else => return error.UnsupportedArch,
    };

    const asset_name = if (os_tag == .windows)
        try std.fmt.allocPrint(arena_allocator, "mise-{s}-{s}-{s}.zip", .{ MISE_VERSION, os_str, arch_str })
    else
        try std.fmt.allocPrint(arena_allocator, "mise-{s}-{s}-{s}", .{ MISE_VERSION, os_str, arch_str });

    const download_url = try std.fmt.allocPrint(arena_allocator, "{s}/releases/download/{s}/{s}", .{ MISE_REPO_URL, MISE_VERSION, asset_name });

    std.debug.print("Downloading from {s}\n", .{download_url});

    if (os_tag == .windows) {
        const zip_path = try std.fs.path.join(allocator, &[_][]const u8{ cache_dir, asset_name });
        defer allocator.free(zip_path);
        try downloadFile(allocator, download_url, zip_path);

        const unzip_path = try std.fs.path.join(allocator, &[_][]const u8{ cache_dir, "unzip.com" });
        defer allocator.free(unzip_path);

        if (!fileExists(unzip_path)) {
            std.debug.print("Downloading unzip from {s}\n", .{COSMO_UNZIP_URL});
            try downloadFile(allocator, COSMO_UNZIP_URL, unzip_path);
        }

        // Run unzip
        const unzip_args = [_][]const u8{ unzip_path, "-o", zip_path, "-d", cache_dir };

        var child = std.process.Child.init(&unzip_args, allocator);
        child.stdin_behavior = .Ignore;
        child.stdout_behavior = .Inherit;
        child.stderr_behavior = .Inherit;
        _ = try child.spawnAndWait();
    } else {
        try downloadFile(allocator, download_url, exe_path);
        // chmod +x
        const file = try std.fs.openFileAbsolute(exe_path, .{});
        defer file.close();
        const metadata = try file.metadata();
        var permissions = metadata.permissions();
        permissions.inner.mode |= 0o111; // Add execute permission
        try file.setPermissions(permissions);
    }
}

fn downloadFile(allocator: std.mem.Allocator, url: []const u8, output_path: []const u8) !void {
    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();

    // Load CA certs
    try client.ca_bundle.rescan(allocator);

    var current_url = try allocator.dupe(u8, url);
    defer allocator.free(current_url);

    var redirect_count: usize = 0;
    const max_redirects = 5;

    while (redirect_count < max_redirects) {
        const uri = try std.Uri.parse(current_url);
        var header_buffer: [16384]u8 = undefined;
        var request = try client.open(.GET, uri, .{ .server_header_buffer = &header_buffer });
        defer request.deinit();

        try request.send();
        try request.finish();
        try request.wait();

        const status = request.response.status;
        if (status == .ok) {
            // Success, download
            const file = try std.fs.createFileAbsolute(output_path, .{});
            defer file.close();

            var buf: [4096]u8 = undefined;
            var reader = request.reader();
            while (true) {
                const n = try reader.read(&buf);
                if (n == 0) break;
                try file.writeAll(buf[0..n]);
            }
            return;
        } else if (status == .moved_permanently or status == .found or status == .see_other or status == .temporary_redirect or status == .permanent_redirect) {
            // Handle redirect
            if (request.response.location) |loc| {
                allocator.free(current_url);
                current_url = try allocator.dupe(u8, loc);
                redirect_count += 1;
                continue;
            } else {
                return error.RedirectMissingLocation;
            }
        } else {
            std.debug.print("HTTP Error: {}\n", .{status});
            return error.DownloadFailed;
        }
    }
    return error.TooManyRedirects;
}
