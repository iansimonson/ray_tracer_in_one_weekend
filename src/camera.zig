const std = @import("std");
const vec3 = @import("vec3.zig");
const rays = @import("ray.zig");
const util = @import("util.zig");

pub const Camera = struct {
    origin: vec3.Point3,
    horizontal: vec3.Vec3,
    vertical: vec3.Vec3,
    lower_left_corner: vec3.Point3,
    u: vec3.Vec3,
    v: vec3.Vec3,
    w: vec3.Vec3,
    lens_radius: f64,

    pub fn init(
        look_from: vec3.Point3,
        look_at: vec3.Point3,
        vup: vec3.Vec3,
        vertical_fov: f64,
        aspect_ratio: f64,
        aperature: f64,
        focus_distance: f64,
    ) @This() {
        const theta = util.degreesToRadians(vertical_fov);
        const h = std.math.tan(theta / 2);
        const viewport_height: f64 = 2.0 * h;
        const viewport_width = viewport_height * aspect_ratio;

        const w = look_from.sub(look_at).unitVector();
        const u = vup.cross(w).unitVector();
        const v = w.cross(u);

        const origin = look_from;
        const horizontal = u.mul(viewport_width * focus_distance);
        const vertical = v.mul(viewport_height * focus_distance);
        const llc = origin.sub(horizontal.div(2)).sub(vertical.div(2)).sub(w.mul(focus_distance));

        const lens_radius = aperature / 2;

        return .{
            .origin = origin,
            .horizontal = horizontal,
            .vertical = vertical,
            .lower_left_corner = llc,
            .u = u,
            .v = v,
            .w = w,
            .lens_radius = lens_radius,
        };
    }

    pub fn getRay(self: @This(), u: f64, v: f64) rays.Ray {
        const rd = vec3.randomInUnitDisk().mul(self.lens_radius);
        const offset = self.u.mul(rd.x()).add(self.v.mul(rd.y()));
        const direction_vec = self.lower_left_corner.add(self.horizontal.mul(u)).add(self.vertical.mul(v)).sub(self.origin).sub(offset);
        return rays.Ray{
            .origin = self.origin.add(offset),
            .direction = direction_vec,
        };
    }
};
