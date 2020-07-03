const std = @import("std");
const vec3 = @import("vec3.zig");

pub const Color = vec3.Vec3;

pub fn writeColor(stream: var, pixel_color: Color) !void {
    var scaled: [3]i32 = undefined;

    for (pixel_color.points) |point, i| {
        scaled[i] = std.math.clamp(@floatToInt(i32, 255.999 * point), 0, 255);
    }

    try stream.print("{} {} {}\n", .{
        scaled[0],
        scaled[1],
        scaled[2],
    });
}

pub fn writeColorMultiSample(stream: var, pixel_color: Color, samples_per_pixel: i32) !void {
    var pixel_copy = pixel_color;

    const scale = 1.0 / @intToFloat(f64, samples_per_pixel);
    // Assumes a gamma of 2...need to look up gamma correction to understand
    // why we're doing this but it does the thing
    for (pixel_copy.points) |*point| {
        point.* = std.math.sqrt(point.* * scale);
        point.* = std.math.clamp(point.*, 0, 1);
    }

    try writeColor(stream, pixel_copy);
}

pub fn normalizeColor(value: i32, scale: i32) f64 {
    return @intToFloat(f64, value) / @intToFloat(f64, scale);
}

pub fn normalizeColorFloat(value: f64, scale: f64) f64 {
    return value / scale;
}
