const std = @import("std");
const util = @import("util.zig");

pub const Vec3 = struct {
    points: [3]f64,

    pub fn init(a: f64, b: f64, c: f64) @This() {
        return .{ .points = .{ a, b, c } };
    }

    pub fn x(self: @This()) f64 {
        return self.points[0];
    }
    pub fn y(self: @This()) f64 {
        return self.points[1];
    }
    pub fn z(self: @This()) f64 {
        return self.points[2];
    }

    pub fn sub(self: @This(), other: @This()) @This() {
        return .{ .points = .{ self.x() - other.x(), self.y() - other.y(), self.z() - other.z() } };
    }

    pub fn add(self: @This(), other: @This()) @This() {
        return .{ .points = .{ self.x() + other.x(), self.y() + other.y(), self.z() + other.z() } };
    }

    pub fn subEq(self: *@This(), other: @This()) *@This() {
        for (self.points) |*point, i| {
            point.* -= other.points[i];
        }
        return self;
    }

    pub fn addEq(self: *@This(), other: @This()) *@This() {
        for (self.points) |*point, i| {
            point.* += other.points[i];
        }
        return self;
    }

    pub fn mul(self: @This(), scalar: f64) @This() {
        var copy = self;
        _ = copy.mulEq(scalar);
        return copy;
    }

    pub fn mulEq(self: *@This(), scalar: f64) *@This() {
        for (self.points) |*point| {
            point.* *= scalar;
        }
        return self;
    }

    pub fn componentwiseMul(self: @This(), vec: @This()) @This() {
        return .{ .points = .{ self.x() * vec.x(), self.y() * vec.y(), self.z() * vec.z() } };
    }

    pub fn div(self: @This(), scalar: f64) @This() {
        var copy = self;
        _ = copy.divEq(scalar);
        return copy;
    }

    pub fn divEq(self: *@This(), scalar: f64) *@This() {
        for (self.points) |*point| {
            point.* /= scalar;
        }
        return self;
    }

    pub fn unitVector(self: @This()) @This() {
        var copy = self;
        const mag = copy.magnitude();
        for (copy.points) |*point| {
            point.* /= mag;
        }
        return copy;
    }

    pub fn magnitude(self: @This()) f64 {
        return std.math.sqrt(dot(self, self));
    }

    pub fn dot(self: @This(), other: @This()) f64 {
        var product: f64 = 0;
        for (self.points) |point, i| {
            product += (point * other.points[i]);
        }

        return product;
    }

    pub fn cross(self: @This(), other: @This()) Vec3 {
        return .{
            .points = .{
                self.points[1] * other.points[2] - self.points[2] * other.points[1],
                self.points[2] * other.points[0] - self.points[0] * other.points[2],
                self.points[0] * other.points[1] - self.points[1] * other.points[0],
            },
        };
    }

    pub fn random() @This() {
        return .{ .points = .{ util.random(), util.random(), util.random() } };
    }

    pub fn randomInRange(min: f64, max: f64) @This() {
        return .{
            .points = .{
                util.randomInRange(min, max),
                util.randomInRange(min, max),
                util.randomInRange(min, max),
            },
        };
    }
};

pub fn randomInUnitSphere() Vec3 {
    while (true) {
        const vec = Vec3.randomInRange(-1, 1);
        if (vec.dot(vec) >= 1) continue;
        return vec;
    }
}

pub fn randomInUnitDisk() Vec3 {
    while (true) {
        const vec = Vec3{ .points = .{ util.randomInRange(-1, 1), util.randomInRange(-1, 1), 0 } };
        if (vec.dot(vec) >= 1) {
            continue;
        }
        return vec;
    }
}

pub fn randomUnitVector() Vec3 {
    const a = util.randomInRange(0, 2 * util.pi);
    const z = util.randomInRange(-1, 1);
    const r = std.math.sqrt(1 - z * z);
    return Vec3.init(r * std.math.cos(a), r * std.math.sin(a), z);
}

pub fn reflectAroundVector(to_reflect: Vec3, reflect_around: Vec3) Vec3 {
    const magnitude_b = reflect_around.dot(to_reflect);
    return to_reflect.sub(reflect_around.mul(magnitude_b).mul(2));
}

pub fn refract(light: Vec3, normal: Vec3, etai_over_etat: f64) Vec3 {
    const cos_theta = light.mul(-1).dot(normal);
    const r_out_parallel = normal.mul(cos_theta).add(light).mul(etai_over_etat);
    const r_out_perp = normal.mul(-1 * std.math.sqrt(1.0 - r_out_parallel.dot(r_out_parallel)));
    return r_out_parallel.add(r_out_perp);
}

pub const Point3 = Vec3;
