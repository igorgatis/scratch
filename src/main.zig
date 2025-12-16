const std = @import("std");
const builtin = @import("builtin");

const MISE_REPO_URL = "https://github.com/jdx/mise";
// Hardcoded version
const MISE_VERSION = "v2025.12.7";
const CACHE_DIR_NAME = "mise.ape";

// Embedded Root CA Certificates
// Includes:
// - ISRG Root X1 (Let's Encrypt / cosmo.zip)
// - USERTrust RSA/ECC (Sectigo / github.com)
// - DigiCert Global/High Assurance (GitHub legacy/backup)
const EMBEDDED_CERTS =
    \\-----BEGIN CERTIFICATE-----
    \\MIIFazCCA1OgAwIBAgIRAIIQz7DSQONZRGPgu2OCiwAwDQYJKoZIhvcNAQELBQAwTzELMAkGA1UE
    \\BhMCVVMxKTAnBgNVBAoTIEludGVybmV0IFNlY3VyaXR5IFJlc2VhcmNoIEdyb3VwMRUwEwYDVQQD
    \\EwxJU1JHIFJvb3QgWDEwHhcNMTUwNjA0MTEwNDM4WhcNMzUwNjA0MTEwNDM4WjBPMQswCQYDVQQG
    \\EwJVUzEpMCcGA1UEChMgSW50ZXJuZXQgU2VjdXJpdHkgUmVzZWFyY2ggR3JvdXAxFTATBgNVBAMT
    \\DElTUkcgUm9vdCBYMTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAK3oJHP0FDfzm54r
    \\Vygch77ct984kIxuPOZXoHj3dcKi/vVqbvYATyjb3miGbESTtrFj/RQSa78f0uoxmyF+0TM8ukj1
    \\3Xnfs7j/EvEhmkvBioZxaUpmZmyPfjxwv60pIgbz5MDmgK7iS4+3mX6UA5/TR5d8mUgjU+g4rk8K
    \\b4Mu0UlXjIB0ttov0DiNewNwIRt18jA8+o+u3dpjq+sWT8KOEUt+zwvo/7V3LvSye0rgTBIlDHCN
    \\Aymg4VMk7BPZ7hm/ELNKjD+Jo2FR3qyHB5T0Y3HsLuJvW5iB4YlcNHlsdu87kGJ55tukmi8mxdAQ
    \\4Q7e2RCOFvu396j3x+UCB5iPNgiV5+I3lg02dZ77DnKxHZu8A/lJBdiB3QW0KtZB6awBdpUKD9jf
    \\1b0SHzUvKBds0pjBqAlkd25HN7rOrFleaJ1/ctaJxQZBKT5ZPt0m9STJEadao0xAH0ahmbWnOlFu
    \\hjuefXKnEgV4We0+UXgVCwOPjdAvBbI+e0ocS3MFEvzG6uBQE3xDk3SzynTnjh8BCNAw1FtxNrQH
    \\usEwMFxIt4I7mKZ9YIqioymCzLq9gwQbooMDQaHWBfEbwrbwqHyGO0aoSCqI3Haadr8faqU9GY/r
    \\OPNk3sgrDQoo//fb4hVC1CLQJ13hef4Y53CIrU7m2Ys6xt0nUW7/vGT1M0NPAgMBAAGjQjBAMA4G
    \\A1UdDwEB/wQEAwIBBjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBR5tFnme7bl5AFzgAiIyBpY
    \\9umbbjANBgkqhkiG9w0BAQsFAAOCAgEAVR9YqbyyqFDQDLHYGmkgJykIrGF1XIpu+ILlaS/V9lZL
    \\ubhzEFnTIZd+50xx+7LSYK05qAvqFyFWhfFQDlnrzuBZ6brJFe+GnY+EgPbk6ZGQ3BebYhtF8GaV
    \\0nxvwuo77x/Py9auJ/GpsMiu/X1+mvoiBOv/2X/qkSsisRcOj/KKNFtY2PwByVS5uCbMiogziUwt
    \\hDyC3+6WVwW6LLv3xLfHTjuCvjHIInNzktHCgKQ5ORAzI4JMPJ+GslWYHb4phowim57iaztXOoJw
    \\TdwJx4nLCgdNbOhdjsnvzqvHu7UrTkXWStAmzOVyyghqpZXjFaH3pO3JLF+l+/+sKAIuvtd7u+Nx
    \\e5AW0wdeRlN8NwdCjNPElpzVmbUq4JUagEiuTDkHzsxHpFKVK7q4+63SM1N95R1NbdWhscdCb+ZA
    \\JzVcoyi3B43njTOQ5yOf+1CceWxG1bQVs5ZufpsMljq4Ui0/1lvh+wjChP4kqKOJ2qxq4RgqsahD
    \\YVvTH9w7jXbyLeiNdd8XM2w9U/t7y0Ff/9yi0GE44Za4rF2LN9d11TPAmRGunUHBcnWEvgJBQl9n
    \\JEiU0Zsnvgc/ubhPgXRR4Xq37Z0j4r7g1SgEEzwxA57demyPxgcYxn/eR44/KJ4EBs+lVDR3veyJ
    \\m+kXQ99b21/+jh5Xos1AnX5iItreGCc=
    \\-----END CERTIFICATE-----
    \\-----BEGIN CERTIFICATE-----
    \\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
    \\Q+6IHdfGjjxDah2nGN59PRbxYvnKkKj9
    \\-----END CERTIFICATE-----
    \\-----BEGIN CERTIFICATE-----
    \\MIICjzCCAhWgAwIBAgIQXIuZxVqUxdJxVt7NiYDMJjAKBggqhkjOPQQDAzCBiDELMAkGA1UEBhMC
    \\VVMxEzARBgNVBAgTCk5ldyBKZXJzZXkxFDASBgNVBAcTC0plcnNleSBDaXR5MR4wHAYDVQQKExVU
    \\aGUgVVNFUlRSVVNUIE5ldHdvcmsxLjAsBgNVBAMTJVVTRVJUcnVzdCBFQ0MgQ2VydGlmaWNhdGlv
    \\biBBdXRob3JpdHkwHhcNMTAwMjAxMDAwMDAwWhcNMzgwMTE4MjM1OTU5WjCBiDELMAkGA1UEBhMC
    \\VVMxEzARBgNVBAgTCk5ldyBKZXJzZXkxFDASBgNVBAcTC0plcnNleSBDaXR5MR4wHAYDVQQKExVU
    \\aGUgVVNFUlRSVVNUIE5ldHdvcmsxLjAsBgNVBAMTJVVTRVJUcnVzdCBFQ0MgQ2VydGlmaWNhdGlv
    \\biBBdXRob3JpdHkwdjAQBgcqhkjOPQIBBgUrgQQAIgNiAAQarFRaqfloI+d61SRvU8Za2EurxtW2
    \\0eZzca7dnNYMYf3boIkDuAUU7FfO7l0/4iGzzvfUinngo4N+LZfQYcTxmdwlkWOrfzCjtHDix6Ez
    \\nPO/LlxTsV+zfTJ/ijTjeXmjQjBAMB0GA1UdDgQWBBQ64QmG1M8ZwpZ2dEl23OA1xmNjmjAOBgNV
    \\HQ8BAf8EBAMCAQYwDwYDVR0TAQH/BAUwAwEB/zAKBggqhkjOPQQDAwNoADBlAjA2Z6EWCNzklwBB
    \\HU6+4WMBzzuqQhFkoJ2UOQIReVx7Hfpkue4WQrO/isIJxOzksU0CMQDpKmFHjFJKS04YcPbWRNZu
    \\9YO6bVi9JNlWSOrvxKJGgYhqOkbRqZtNyWHa0V1Xahg=
    \\-----END CERTIFICATE-----
    \\-----BEGIN CERTIFICATE-----
    \\MIICHjCCAaSgAwIBAgIRYFlJ4CYuu1X5CneKcflK2GwwCgYIKoZIzj0EAwMwUDEkMCIGA1UECxMb
    \\R2xvYmFsU2lnbiBFQ0MgUm9vdCBDQSAtIFI1MRMwEQYDVQQKEwpHbG9iYWxTaWduMRMwEQYDVQQD
    \\EwpHbG9iYWxTaWduMB4XDTEyMTExMzAwMDAwMFoXDTM4MDExOTAzMTQwN1owUDEkMCIGA1UECxMb
    \\R2xvYmFsU2lnbiBFQ0MgUm9vdCBDQSAtIFI1MRMwEQYDVQQKEwpHbG9iYWxTaWduMRMwEQYDVQQD
    \\EwpHbG9iYWxTaWduMHYwEAYHKoZIzj0CAQYFK4EEACIDYgAER0UOlvt9Xb/pOdEh+J8LttV7HpI6
    \\SFkc8GIxLcB6KP4ap1yztsyX50XUWPrRd21DosCHZTQKH3rd6zwzocWdTaRvQZU4f8kehOvRnkmS
    \\h5SHDDqFSmafnVmTTZdhBoZKo0IwQDAOBgNVHQ8BAf8EBAMCAQYwDwYDVR0TAQH/BAUwAwEB/zAd
    \\BgNVHQ4EFgQUPeYpSJvqB8ohREom3m7e0oPQn1kwCgYIKoZIzj0EAwMDaAAwZQIxAOVpEslu28Yx
    \\uglB4Zf4+/2a4n0Sye18ZNPLBSWLVtmg515dTguDnFt2KaAJJiFqYgIwcdK1j1zqO+F4CYWodZI7
    \\yFz9SO8NdCKoCOJuxUnOxwy8p2Fp8fc74SrL+SvzZpA3
    \\-----END CERTIFICATE-----
    \\-----BEGIN CERTIFICATE-----
    \\MIIDrzCCApegAwIBAgIQCDvgVpBCRrGhdWrJWZHHSjANBgkqhkiG9w0BAQUFADBhMQswCQYDVQQG
    \\EwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSAw
    \\HgYDVQQDExdEaWdpQ2VydCBHbG9iYWwgUm9vdCBDQTAeFw0wNjExMTAwMDAwMDBaFw0zMTExMTAw
    \\MDAwMDBaMGExCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3
    \\dy5kaWdpY2VydC5jb20xIDAeBgNVBAMTF0RpZ2lDZXJ0IEdsb2JhbCBSb290IENBMIIBIjANBgkq
    \\hkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA4jvhEXLeqKTTo1eqUKKPC3eQyaKl7hLOllsBCSDMAZOn
    \\TjC3U/dDxGkAV53ijSLdhwZAAIEJzs4bg7/fzTtxRuLWZscFs3YnFo97nh6Vfe63SKMI2tavegw5
    \\BmV/Sl0fvBf4q77uKNd0f3p4mVmFaG5cIzJLv07A6Fpt43C/dxC//AH2hdmoRBBYMql1GNXRor5H
    \\4idq9Joz+EkIYIvUX7Q6hL+hqkpMfT7PT19sdl6gSzeRntwi5m3OFBqOasv+zbMUZBfHWymeMr/y
    \\7vrTC0LUq7dBMtoM1O/4gdW7jVg/tRvoSSiicNoxBN33shbyTApOB6jtSj1etX+jkMOvJwIDAQAB
    \\o2MwYTAOBgNVHQ8BAf8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQUA95QNVbRTLtm
    \\8KPiGxvDl7I90VUwHwYDVR0jBBgwFoAUA95QNVbRTLtm8KPiGxvDl7I90VUwDQYJKoZIhvcNAQEF
    \\BQADggEBAMucN6pIExIK+t1EnE9SsPTfrgT1eXkIoyQY/EsrhMAtudXH/vTBH1jLuG2cenTnmCmr
    \\EbXjcKChzUyImZOMkXDiqw8cvpOp/2PV5Adg06O/nVsJ8dWO41P0jmP6P6fbtGbfYmbW0W5BjfIt
    \\tep3Sp+dWOIrWcBAI+0tKIJFPnlUkiaY4IBIqDfv8NZ5YBberOgOzW6sRBc4L0na4UU+Krk2U886
    \\UAb3LujEV0lsYSEY1QSteDwsOoBrp+uvFRTp2InBuThs4pFsiv9kuXclVzDAGySj4dzp30d8tbQk
    \\CAUw7C29C79Fv1C5qfPrmAESrciIxpg0X40KPMbp1ZWVbd4=
    \\-----END CERTIFICATE-----
    \\-----BEGIN CERTIFICATE-----
    \\MIIDxTCCAq2gAwIBAgIQAqxcJmoLQJuPC3nyrkYldzANBgkqhkiG9w0BAQUFADBsMQswCQYDVQQG
    \\EwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSsw
    \\KQYDVQQDEyJEaWdpQ2VydCBIaWdoIEFzc3VyYW5jZSBFViBSb290IENBMB4XDTA2MTExMDAwMDAw
    \\MFoXDTMxMTExMDAwMDAwMFowbDELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZ
    \\MBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTErMCkGA1UEAxMiRGlnaUNlcnQgSGlnaCBBc3N1cmFu
    \\Y2UgRVYgUm9vdCBDQTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMbM5XPm+9S75S0t
    \\Mqbf5YE/yc0lSbZxKsPVlDRnogocsF9ppkCxxLeyj9CYpKlBWTrT3JTWPNt0OKRKzE0lgvdKpVMS
    \\OO7zSW1xkX5jtqumX8OkhPhPYlG++MXs2ziS4wblCJEMxChBVfvLWokVfnHoNb9Ncgk9vjo4UFt3
    \\MRuNs8ckRZqnrG0AFFoEt7oT61EKmEFBIk5lYYeBQVCmeVyJ3hlKV9Uu5l0cUyx+mM0aBhakaHPQ
    \\NAQTXKFx01p8VdteZOE3hzBWBOURtCmAEvF5OYiiAhF8J2a3iLd48soKqDirCmTCv2ZdlYTBoSUe
    \\h10aUAsgEsxBu24LUTi4S8sCAwEAAaNjMGEwDgYDVR0PAQH/BAQDAgGGMA8GA1UdEwEB/wQFMAMB
    \\Af8wHQYDVR0OBBYEFLE+w2kD+L9HAdSYJhoIAu9jZCvDMB8GA1UdIwQYMBaAFLE+w2kD+L9HAdSY
    \\JhoIAu9jZCvDMA0GCSqGSIb3DQEBBQUAA4IBAQAcGgaX3NecnzyIZgYIVyHbIUf4KmeqvxgydkAQ
    \\V8GK83rZEWWONfqe/EW1ntlMMUu4kehDLI6zeM7b41N5cdblIZQB2lWHmiRk9opmzN6cN82oNLFp
    \\myPInngiK3BD41VHMWEZ71jFhS9OMPagMRYjyOfiZRYzy78aG6A9+MpeizGLYAiJLQwGXFK3xPkK
    \\mNEVX58Svnw2Yzi9RKR/5CYrCsSXaQ3pjOLAEFe4yHYSkVXySGnYvCoCWw9E1CAx2/S6cCZdkGCe
    \\vEsXCS+0yx5DaMkHJ8HSXPfqIbloEpw8nL+e/IBcm2PN7EeqJSdnoDfzAIJ9VNep+OkuE6N36B9K
    \\-----END CERTIFICATE-----
;

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
            return std.fs.path.join(allocator, &[_][]const u8{ local_app_data, CACHE_DIR_NAME, MISE_VERSION });
        }
        if (env_map.get("USERPROFILE")) |user_profile| {
            return std.fs.path.join(allocator, &[_][]const u8{ user_profile, "AppData", "Local", CACHE_DIR_NAME, MISE_VERSION });
        }
        if (env_map.get("TEMP")) |temp| {
            return std.fs.path.join(allocator, &[_][]const u8{ temp, CACHE_DIR_NAME, MISE_VERSION });
        }
        if (env_map.get("TMP")) |tmp| {
            return std.fs.path.join(allocator, &[_][]const u8{ tmp, CACHE_DIR_NAME, MISE_VERSION });
        }
    } else {
        if (env_map.get("XDG_CACHE_HOME")) |xdg_cache| {
            return std.fs.path.join(allocator, &[_][]const u8{ xdg_cache, CACHE_DIR_NAME, MISE_VERSION });
        }
        if (env_map.get("HOME")) |home| {
            return std.fs.path.join(allocator, &[_][]const u8{ home, ".cache", CACHE_DIR_NAME, MISE_VERSION });
        }
        // Fallback to /tmp
        return std.fs.path.join(allocator, &[_][]const u8{ "/tmp", CACHE_DIR_NAME, MISE_VERSION });
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

        try unzipFile(zip_path, cache_dir);
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

fn addEmbeddedCerts(cb: *std.crypto.Certificate.Bundle, allocator: std.mem.Allocator) !void {
    const begin_marker = "-----BEGIN CERTIFICATE-----";
    const end_marker = "-----END CERTIFICATE-----";
    const now_sec = std.time.timestamp();

    var index: usize = 0;
    while (std.mem.indexOfPos(u8, EMBEDDED_CERTS, index, begin_marker)) |begin| {
        const after_begin = begin + begin_marker.len;
        if (std.mem.indexOfPos(u8, EMBEDDED_CERTS, after_begin, end_marker)) |end| {
            const pem_content = EMBEDDED_CERTS[after_begin..end];

            // Decoder that ignores whitespace
            // const decoder = std.base64.standard.decoderWithIgnore(&[_]u8{ '\n', '\r', ' ', '\t' });
            // calcSizeForSlice is on Base64Decoder, not WithIgnore in Zig 0.13?
            // Actually Base64DecoderWithIgnore should handle it.
            // The grep showed `calcSizeForSlice` is inside `Base64Decoder` block?
            // If `Base64DecoderWithIgnore` doesn't implement it, we might need manual calc.
            // But `decode` is implemented.
            // Let's assume `calcSizeForSlice` is NOT available on `DecoderWithIgnore` directly or named differently.
            // `calcSizeUpperBound` exists.

            // For PEM (MIME), whitespace is ignored.
            // `calcSizeForSlice` on `DecoderWithIgnore` is available in master but maybe not 0.13?
            // Let's use `calcSizeUpperBound` and then `decode` returns written slice or void?
            // `decode` returns `void` in 0.13 according to grep.

            // We can allocate upper bound, decode, and shrink.

            // const upper_bound = try decoder.calcSizeUpperBound(pem_content.len);
            // const start_write = cb.bytes.items.len;
            // try cb.bytes.ensureUnusedCapacity(allocator, upper_bound);
            // cb.bytes.items.len += upper_bound;
            // const dest_buf = cb.bytes.items[start_write..];

            // Wait, `decode` on `DecoderWithIgnore` doesn't return size written?
            // Zig 0.13 docs say `decode` returns `void`.
            // How do we know actual size if we ignore chars?
            // If it returns void, it must fill `dest`? But `dest` must be exact size?
            // "dest.len must be what you get from ::calcSize."

            // If `calcSizeForSlice` is missing, we can't easily use it?
            // But wait, `standard.Decoder` has it.
            // If we remove newlines manually, we can use `standard.Decoder`.

            // Manually strip whitespace from PEM content (copy to stack buffer or iterate).
            // PEM content is inside `EMBEDDED_CERTS` (const).

            // Allocate a temp buffer for stripped base64?
            var filtered = try std.ArrayList(u8).initCapacity(allocator, pem_content.len);
            defer filtered.deinit();
            for (pem_content) |c| {
                if (c != '\n' and c != '\r' and c != ' ' and c != '\t') {
                    try filtered.append(c);
                }
            }

            const clean_b64 = filtered.items;
            const decoder_std = std.base64.standard.Decoder;
            const decoded_len = try decoder_std.calcSizeForSlice(clean_b64);

            try cb.bytes.ensureUnusedCapacity(allocator, decoded_len);
            const start_idx = cb.bytes.items.len;
            cb.bytes.items.len += decoded_len;

            try decoder_std.decode(cb.bytes.items[start_idx..], clean_b64);

            // Parse and index the certificate
            try cb.parseCert(allocator, @intCast(start_idx), now_sec);

            index = end + end_marker.len;
        } else {
            break;
        }
    }
}

fn downloadFile(allocator: std.mem.Allocator, url: []const u8, output_path: []const u8) !void {
    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();

    // Load CA certs
    // Try to load system certs first
    client.ca_bundle.rescan(allocator) catch |err| {
        std.debug.print("Warning: Failed to load system CA certs: {}\n", .{err});
        // Continue, as we will add embedded ones.
    };

    // Add embedded certs
    try addEmbeddedCerts(&client.ca_bundle, allocator);

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

fn unzipFile(zip_path: []const u8, output_dir: []const u8) !void {
    var file = try std.fs.cwd().openFile(zip_path, .{});
    defer file.close();

    var zip = try std.zip.Iterator(std.fs.File.SeekableStream).init(file.seekableStream());

    // Allocate a buffer for filename. Max path length usually suffices.
    var filename_buf: [std.fs.MAX_PATH_BYTES]u8 = undefined;

    while (try zip.next()) |entry| {
        // Zip iterator in Zig 0.13 seems to handle extraction via entry.extract which reads from the stream.
        // But we need to know where to extract.
        // entry.extract takes `dest: std.fs.Dir`.
        // And it writes the file relative to that dir.
        // It reads filename from the stream (using the buffer we pass).

        var dir = try std.fs.openDirAbsolute(output_dir, .{});
        defer dir.close();

        // Extract directly to the directory.
        _ = try entry.extract(file.seekableStream(), .{}, &filename_buf, dir);
    }
}
