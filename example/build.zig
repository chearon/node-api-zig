const std = @import("std");

pub fn build(b: *std.Build) void {
  const target = b.standardTargetOptions(.{});
  const optimize = b.standardOptimizeOption(.{});
  const node_api = b.dependency("node_api", .{
    .target = target,
    .optimize = optimize,
  }).artifact("node_api");

  const lib = b.addLibrary(.{
    .name = "example_callbacks",
    .linkage = .dynamic,
    .root_module = b.createModule(.{
      .target = target,
      .optimize = optimize,
    })
  });

  // this tells the Unixes to allow napi_ functions to be unresolved
  lib.linker_allow_shlib_undefined = true;

  // add your sources/flags here
  lib.addCSourceFiles(.{
    .files = &.{"addon.cc"},
    .flags = &.{}
  });

  // makes node-addon-api (C++) and n-api (C) headers available
  // on Windows, this links to import libraries
  // on Unixes, it links to an empty object file
  lib.addObject(node_api);

  lib.linkLibCpp();

  // name/move the addon to a place addon.js loads it from
  const move = b.addInstallFile(lib.getEmittedBin(), "../addon.node");
  move.step.dependOn(&lib.step);
  b.getInstallStep().dependOn(&move.step);
}
