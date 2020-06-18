const std = @import("std");
const vec3 = @import("vec3.zig");
const rays = @import("ray.zig");

pub const Camera = struct {
    origin: vec3.Point3,
    horizontal: vec3.Vec3,
    vertical: vec3.Vec3,
    lower_left_corner: vec3.Point3,

    pub fn init() @This() {
        const aspect_ratio: f64 = 16.0 / 9.0;
        const viewport_height: f64 = 2.0;
        const viewport_width = viewport_height * aspect_ratio;
        const focal_length: f64 = 1.0;

        const origin = vec3.Point3.init(0, 0, 0);
        const horizontal = vec3.Vec3.init(viewport_width, 0, 0);
        const vertical = vec3.Vec3.init(0, viewport_height, 0);
        const llc = origin.sub(horizontal.div(2)).sub(vertical.div(2)).sub(vec3.Vec3.init(0, 0, focal_length));

        return .{
            .origin = origin,
            .horizontal = horizontal,
            .vertical = vertical,
            .lower_left_corner = llc,
        };
    }

    pub fn getRay(self: @This(), u: f64, v: f64) rays.Ray {
        const direction_vec = self.lower_left_corner.add(self.horizontal.mul(u)).add(self.vertical.mul(v)).sub(self.origin);
        return rays.Ray{
            .origin = self.origin,
            .direction = direction_vec,
        };
    }
};
