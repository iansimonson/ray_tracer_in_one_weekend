const std = @import("std");
const vec3 = @import("vec3.zig");
const color = @import("color.zig");
const rays = @import("ray.zig");

const image_width: i32 = 256;
const image_height: i32 = 256;

const stdout = std.io.getStdOut();

pub fn main() !void {
    try stdout.outStream().print("P3\n{} {}\n255\n", .{ image_width, image_height });

    var j: i32 = image_height - 1;
    while (j >= 0) : (j -= 1) {
        var i: i32 = 0;
        std.debug.warn("\rScanlines remaining: {} ", .{j});
        while (i < image_width) : (i += 1) {
            const pixel: color.Color = .{
                .points = .{
                    color.normalizeColor(i, image_width - 1),
                    color.normalizeColor(j, image_height - 1),
                    0.25,
                },
            };

            try color.writeColor(stdout.outStream(), pixel);
        }
    }
    std.debug.warn("\nDone.\n", .{});
}

fn rayColor(ray: rays.Ray) color.Color {
    const unit_direction = ray.direction.unitVector();
    const t: f64 = (0.5 * unit_direction.y() + 1.0);
    return (color.Color{
        .points = .{
            1.0,
            1.0,
            1.0,
        },
    }).mul(1.0 - t).add((color.Color{
        .points = .{
            0.5,
            0.7,
            1.0,
        },
    }).mul(t));
}
