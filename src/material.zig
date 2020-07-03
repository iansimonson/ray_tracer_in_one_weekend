const std = @import("std");
const r = @import("ray.zig");
const hits = @import("hit.zig");
const color = @import("color.zig");
const vec3 = @import("vec3.zig");
const util = @import("util.zig");

pub const Material = struct {
    scatter_fn: fn (*const Material, r.Ray, hits.HitRecord, *color.Color, *r.Ray) bool,

    pub fn scatter(
        self: *const @This(),
        ray: r.Ray,
        hit_record: hits.HitRecord,
        attenuation: *color.Color,
        scattered: *r.Ray,
    ) bool {
        return self.scatter_fn(self, ray, hit_record, attenuation, scattered);
    }
};

pub const Lambertian = struct {
    material: Material,
    albedo: color.Color,

    pub fn init(albedo: color.Color) @This() {
        return .{
            .material = .{ .scatter_fn = scatterFn },
            .albedo = albedo,
        };
    }

    fn scatterFn(
        material: *const Material,
        ray: r.Ray,
        hit_record: hits.HitRecord,
        attenuation: *color.Color,
        scattered: *r.Ray,
    ) bool {
        const self = @fieldParentPtr(Lambertian, "material", material);
        const scatter_direction = hit_record.normal.add(vec3.randomUnitVector());
        scattered.* = .{ .origin = hit_record.p, .direction = scatter_direction };
        attenuation.* = self.albedo;
        return true;
    }
};

pub const Metal = struct {
    material: Material,
    albedo: color.Color,

    pub fn init(albedo: color.Color) @This() {
        return .{
            .material = .{ .scatter_fn = scatterFn },
            .albedo = albedo,
        };
    }

    fn scatterFn(
        material: *const Material,
        ray: r.Ray,
        hit_record: hits.HitRecord,
        attenuation: *color.Color,
        scattered: *r.Ray,
    ) bool {
        const self = @fieldParentPtr(Metal, "material", material);
        const reflected = vec3.reflectAroundVector(ray.direction.unitVector(), hit_record.normal);
        scattered.* = .{ .origin = hit_record.p, .direction = reflected };
        attenuation.* = self.albedo;
        return (scattered.direction.dot(hit_record.normal) > 0);
    }
};

pub const Dielectric = struct {
    material: Material,
    ref_idx: f64,

    pub fn init(ref_idx: f64) @This() {
        return .{
            .material = .{ .scatter_fn = scatterFn },
            .ref_idx = ref_idx,
        };
    }

    fn scatterFn(
        material: *const Material,
        ray: r.Ray,
        hit_record: hits.HitRecord,
        attenuation: *color.Color,
        scattered: *r.Ray,
    ) bool {
        const self = @fieldParentPtr(Dielectric, "material", material);
        const etai_over_etat = if (hit_record.front_face) 1.0 / self.ref_idx else self.ref_idx;
        const unit_direction = ray.direction.unitVector();
        const cos_theta = std.math.min(unit_direction.mul(-1).dot(hit_record.normal), 1);
        const sin_theta = std.math.sqrt(1 - cos_theta * cos_theta);
        const reflect_probability = schlick(cos_theta, etai_over_etat);
        const direction = if (etai_over_etat * sin_theta > 1 or util.random() < reflect_probability)
            vec3.reflectAroundVector(unit_direction, hit_record.normal)
        else
            vec3.refract(unit_direction, hit_record.normal, etai_over_etat);
        scattered.* = .{ .origin = hit_record.p, .direction = direction };
        attenuation.* = color.Color.init(1, 1, 1);

        return true;
    }

    fn schlick(cos: f64, ref_idx: f64) f64 {
        const r0 = (1 - ref_idx) / (1 + ref_idx);
        const r1 = r0 * r0;
        return r1 + (1 - r0)*std.math.pow(f64, (1 - cos), 5);
    }

};
