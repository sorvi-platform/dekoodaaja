// This is in separate build file so that build.zig.zon deps
// even if marked lazy do not get accidentally included in
// the closure of zig package manager integrations

const std = @import("std");
const build_crab = @import("build.crab");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const external = b.option(bool, "external", "include external decoders in benchmark") orelse true;

    const dekoodaaja = b.dependency("dekoodaaja", .{ .target = target, .optimize = optimize }).module("dekoodaaja");

    const include_rust = D: {
        if (!external) break :D false;
        if (@import("builtin").zig_version.minor <= 15) break :D false;
        _ = std.process.run(b.allocator, b.graph.io, .{ .argv = &.{ "cargo", "version" } }) catch break :D false;
        break :D true;
    };

    const opts = b.addOptions();
    opts.addOption(bool, "rust", include_rust);
    opts.addOption(bool, "external", external);
    const bench = b.addExecutable(.{
        .name = "bench",
        .root_module = b.createModule(.{
            .root_source_file = b.path("bench.zig"),
            .optimize = optimize,
            .target = target,
            .strip = false,
            .link_libc = false,
            .imports = &.{
                .{ .name = "build_options", .module = opts.createModule() },
                .{ .name = "dekoodaaja", .module = dekoodaaja },
            },
        }),
    });

    bench.lto = switch (target.result.ofmt) {
        // zig's macho linker does not suppor atm
        .macho => .none,
        // <https://codeberg.org/ziglang/zig/issues/31958>
        .coff => .none,
        else => .full,
    };

    if (external) {
        const zig_qoi = b.dependency("zig-qoi", .{ .target = target, .optimize = optimize }).module("qoi");
        zig_qoi.strip = false;
        zig_qoi.link_libc = false;

        const zqoi = b.dependency("zqoi", .{ .target = target, .optimize = optimize }).module("root");
        zqoi.strip = false;
        zqoi.link_libc = false;

        const qoi = D: {
            const dep = b.dependency("qoi", .{});
            const c = b.addTranslateC(.{
                .root_source_file = dep.path("qoi.h"),
                .optimize = optimize,
                .target = target,
                .link_libc = true,
            });
            const mod = c.createModule();
            const files = b.addWriteFiles();
            _ = files.add("qoi.c",
                \\#define QOI
                \\#define QOI_IMPLEMENTATION
                \\#define QOI_MALLOC(sz) dekoodaaja_bench_malloc(sz)
                \\#define QOI_FREE(p) ((void)p)
                \\#include <stddef.h>
                \\void* dekoodaaja_bench_malloc(size_t sz);
                \\#include "qoi.h"
            );
            mod.addCSourceFiles(.{
                .files = &.{"qoi.c"},
                .root = files.getDirectory(),
            });
            mod.addIncludePath(dep.path(""));
            mod.strip = false;
            break :D mod;
        };

        const qoi_simd = D: {
            const dep = b.dependency("qoi-simd", .{});
            const c = b.addTranslateC(.{
                .root_source_file = b.addWriteFiles().add("c.h",
                    \\#define qoi_encode simd_qoi_encode
                    \\#define qoi_decode simd_qoi_decode
                    \\#define qoi_write simd_qoi_write
                    \\#define qoi_read simd_qoi_read
                    \\#include "qoi.h"
                ),
                .optimize = optimize,
                .target = target,
                .link_libc = true,
            });
            c.addIncludePath(dep.path(""));
            const mod = c.createModule();
            const files = b.addWriteFiles();
            _ = files.add("qoi.c",
                \\#define QOI
                \\#define QOI_IMPLEMENTATION
                \\#define QOI_MALLOC(sz) dekoodaaja_bench_malloc(sz)
                \\#define QOI_FREE(p) ((void)p)
                \\#include <stddef.h>
                \\void* dekoodaaja_bench_malloc(size_t sz);
                \\#define qoi_encode simd_qoi_encode
                \\#define qoi_decode simd_qoi_decode
                \\#define qoi_write simd_qoi_write
                \\#define qoi_read simd_qoi_read
                \\#include "qoi.h"
            );
            mod.addCSourceFiles(.{
                .files = &.{"qoi.c"},
                .root = files.getDirectory(),
            });
            mod.addIncludePath(dep.path(""));
            mod.strip = false;
            break :D mod;
        };

        const magicqoi = D: {
            const dep = b.dependency("magicqoi", .{});
            const c = b.addTranslateC(.{
                .root_source_file = dep.path("magicqoi/magicqoi.h"),
                .optimize = optimize,
                .target = target,
                .link_libc = true,
            });
            c.addIncludePath(dep.path(""));
            const mod = c.createModule();
            mod.addCSourceFiles(.{
                .files = &.{"magicqoi.c"},
                .root = dep.path("magicqoi"),
            });
            mod.addIncludePath(dep.path(""));
            mod.strip = false;
            break :D mod;
        };

        switch (target.result.cpu.arch) {
            .x86_64 => {
                bench.root_module.addImport("qoi-simd", qoi_simd);
            },
            else => {},
        }
        bench.root_module.addImport("qoi", qoi);
        if (target.result.os.tag != .windows) {
            bench.root_module.addImport("magicqoi", magicqoi);
        }
        bench.root_module.addImport("zig-qoi", zig_qoi);
        bench.root_module.addImport("zqoi", zqoi);
    }

    if (include_rust) {
        const rs = D: {
            const cargo = build_crab.addCargoBuild(
                b,
                .{
                    .manifest_path = b.path("rust/Cargo.toml"),
                    .cargo_args = &.{
                        "--quiet", "--profile",
                        switch (optimize) {
                            .ReleaseSmall => "small",
                            .ReleaseFast => "release",
                            .ReleaseSafe => "release",
                            .Debug => "debug",
                        },
                    },
                },
                .{
                    .optimize = optimize,
                    .target = target,
                },
            );
            const c = b.addTranslateC(.{
                .root_source_file = b.path("rust/ffi.h"),
                .optimize = optimize,
                .target = target,
                .link_libc = true,
            });
            const mod = c.createModule();
            mod.addLibraryPath(cargo);
            mod.linkSystemLibrary("ffi", .{});
            break :D mod;
        };
        bench.root_module.addImport("rs", rs);
    }

    const run_bench = b.addRunArtifact(bench);
    const bench_step = b.step("run", "Run the benchmark");
    bench_step.dependOn(&run_bench.step);
}
