const vec3 = @import("vec3.zig");

pub const Ray = struct {
    origin: vec3.Point3,
    direction: vec3.Vec3,

    pub fn at(self: @This(), t: f64) vec3.Point3 {
        return self.origin.add(self.direction.mul(t));
    }
};
