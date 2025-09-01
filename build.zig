const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const node_api_headers = b.dependency("node_api_headers", .{});
    const module = b.createModule(.{
        .target = target,
        .optimize = optimize,
    });
    const node_api = b.addObject(.{
        .name = "node_api",
        .root_module = module
    });

    const node_addon_api = b.dependency("node_addon_api", .{
        .target = target,
        .optimize = optimize,
    });

    node_api.installHeadersDirectory(node_api_headers.path("include"), "", .{});
    node_api.installHeadersDirectory(node_addon_api.path("."), "", .{});
    
    if (target.result.os.tag == .windows) {
        const concat = b.addExecutable(.{
            .name = "concat",
            .root_module = b.createModule(.{
              .root_source_file = b.path("concat.zig"),
              .target = b.resolveTargetQuery(.{}),
              .optimize = .Debug,
            }),
        });

        const concat_cmd = b.addRunArtifact(concat);
        concat_cmd.addFileArg(node_api_headers.path("def/node_api.def"));
        concat_cmd.addFileArg(node_api_headers.path("def/js_native_api.def"));
        const combined_def = concat_cmd.addOutputFileArg("combined.def");

        // Create single library from combined .def file
        const combined_lib = dlltool(b, target, combined_def, "combined.lib");
        module.addObjectFile(combined_lib);
    } else {
        module.addCSourceFile(.{.file = b.path("empty.c"), .flags = &.{}});
    }
    
    var installFile = b.addInstallArtifact(node_api, .{
        .dest_dir = .disabled
    });

    b.getInstallStep().dependOn(&installFile.step);
}

pub fn dlltool(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    def_file: std.Build.LazyPath,
    lib_file_basename: []const u8
) std.Build.LazyPath {
    const exe = b.addSystemCommand(&.{b.graph.zig_exe, "dlltool", "-d"});
    exe.addFileArg(def_file);
    exe.addArg("-l");
    const lib_file = exe.addOutputFileArg(lib_file_basename);
    
    exe.addArgs(&.{
        "-m", switch (target.result.cpu.arch) {
            .x86 => "i386",
            .x86_64 => "i386:x86-64",
            .arm => "arm",
            .aarch64 => "arm64",
            else => "i386:x86-64",
        },
    });
    
    return lib_file;
}