const std = @import("std");

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
};

pub const Point3 = Vec3;
