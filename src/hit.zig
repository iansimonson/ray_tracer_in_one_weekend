const std = @import("std");
const vec3 = @import("vec3.zig");
const rays = @import("ray.zig");
const mat = @import("material.zig");

pub const HitRecord = struct {
    p: vec3.Point3,
    normal: vec3.Vec3,
    t: f64,
    front_face: bool,
    material: *mat.Material,

    pub fn setFaceNormal(self: *@This(), ray: rays.Ray, outward_normal: vec3.Vec3) void {
        self.front_face = ray.direction.dot(outward_normal) < 0;
        self.normal = if (self.front_face) outward_normal else outward_normal.mul(-1);
    }
};

pub const Hittable = struct {
    hitFn: fn (*@This(), rays.Ray, f64, f64, *HitRecord) bool,
    deinitFn: fn (*@This()) void = defaultDeinit,

    pub fn hit(self: *@This(), ray: rays.Ray, t_min: f64, t_max: f64, hit_record: *HitRecord) bool {
        return self.hitFn(self, ray, t_min, t_max, hit_record);
    }

    pub fn deinit(self: *@This()) void {
        self.deinitFn(self);
    }

    fn defaultDeinit(self: *@This()) void {}
};

/// Owns the lifetime of the itmes added
/// Will call deinit on each Hittable
pub const HitList = struct {
    alloc: *std.mem.Allocator,
    items: std.ArrayList(*Hittable),
    hittable: Hittable,

    const ListType = std.ArrayList(*Hittable);

    pub fn init(alloc: *std.mem.Allocator) @This() {
        return .{
            .alloc = alloc,
            .items = ListType.init(alloc),
            .hittable = .{
                .hitFn = hit,
                .deinitFn = virtDeinit,
            },
        };
    }

    pub fn deinit(self: *@This()) void {
        for (self.items.items) |item| {
            item.deinit();
        }
        self.items.deinit();
    }

    /// Takes ownership and will call `deinit`
    pub fn add(self: *@This(), hittable: *Hittable) !void {
        try self.items.append(hittable);
    }

    pub fn clear(self: *@This()) void {
        for (self.items.items) |*item| {
            item.deinit();
        }
        self.items.resize(0);
    }

    fn hit(hittable: *Hittable, ray: rays.Ray, t_min: f64, t_max: f64, hit_record: *HitRecord) bool {
        const self = @fieldParentPtr(HitList, "hittable", hittable);
        var temp_record: HitRecord = undefined;
        var hit_anything: bool = false;
        var closest: f64 = t_max;

        for (self.items.items) |item| {
            if (item.hit(ray, t_min, closest, &temp_record)) {
                hit_anything = true;
                closest = temp_record.t;
                hit_record.* = temp_record;
            }
        }

        return hit_anything;
    }

    fn virtDeinit(hittable: *Hittable) void {
        const self = @fieldParentPtr(HitList, "hittable", hittable);
        self.deinit();
    }
};
