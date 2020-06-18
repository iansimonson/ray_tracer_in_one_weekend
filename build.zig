const std = @import("std");
const Builder = std.build.Builder;

pub fn build(b: *Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const exe = createExecutable(b, .{
        .name = "ppm",
        .entry_point = "src/ppm.zig",
        .target = target,
        .mode = mode,
    });

    const ray_trace = createExecutable(b, .{
        .name = "ray_trace",
        .entry_point = "src/main.zig",
        .target = target,
        .mode = mode,
    });
    ray_trace.linkSystemLibrary("c");
}

fn createExecutable(b: *Builder, meta_data: Info) *std.build.LibExeObjStep {
    const exe = b.addExecutable(meta_data.name, meta_data.entry_point);
    exe.setTarget(meta_data.target);
    exe.setBuildMode(meta_data.mode);
    exe.install();
    return exe;
}

const Info = struct {
    name: []const u8,
    entry_point: []const u8,
    target: std.zig.CrossTarget,
    mode: std.builtin.Mode,
};
