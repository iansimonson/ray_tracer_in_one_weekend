const std = @import("std");
const vec3 = @import("vec3.zig");
const color = @import("color.zig");
const rays = @import("ray.zig");
const util = @import("util.zig");
const camera = @import("camera.zig");

const stdout = std.io.getStdOut();
const stderr = std.io.getStdErr();

// Todo make an arena
const allocator = std.heap.page_allocator;
//const allocator = std.heap.c_allocator;

pub fn main() anyerror!void {
    const aspect_ratio: f64 = 16.0 / 9.0;
    const image_width: i32 = 384;
    const image_height = @floatToInt(i32, (@intToFloat(f64, image_width) / aspect_ratio));
    const samples_per_pixel: i32 = 100;

    const outstream = stdout.outStream();
    try outstream.print("P3\n{} {}\n255\n", .{ image_width, image_height });

    var world = HitList.init(allocator);
    defer world.deinit();
    var sphere = Sphere.init(vec3.Point3.init(0, 0, -1), 0.5);
    var sphere_2 = Sphere.init(vec3.Point3.init(0, -100.5, -1), 100);
    try world.add(&sphere.hittable);
    try world.add(&sphere_2.hittable);

    var cam = camera.Camera.init();

    var j: i32 = image_height - 1;
    while (j >= 0) : (j -= 1) {
        try stderr.outStream().print("\rScanlines remaining: {} ", .{j});
        var i: i32 = 0;
        while (i < image_width) : (i += 1) {
            var pixel_color = color.Color.init(0, 0, 0);
            var s: i32 = 0;
            while (s < samples_per_pixel) : (s += 1) {
                const u = color.normalizeColorFloat(@intToFloat(f64, i) + util.random(), image_width - 1);
                const v = color.normalizeColorFloat(@intToFloat(f64, j) + util.random(), image_height - 1);

                const r = cam.getRay(u, v);
                const r_color = rayColor(r, &world.hittable);

                _ = pixel_color.addEq(r_color);
            }
            try color.writeColorMultiSample(
                outstream,
                pixel_color,
                samples_per_pixel,
            );
        }
    }

    try stderr.outStream().print("\nDone.\n", .{});
}

fn rayColor(ray: rays.Ray, world: *Hittable) color.Color {
    var rec: HitRecord = undefined;
    if (world.hit(ray, 0, util.infinity, &rec)) { // on the sphere
        return rec.normal.add(color.Color.init(1, 1, 1)).mul(0.5);
    } else { // off the sphere
        const unit_direction = ray.direction.unitVector();
        const t: f64 = 0.5 * (unit_direction.y() + 1.0);
        return (color.Color.init(
            1.0,
            1.0,
            1.0,
        )).mul(1.0 - t).add((color.Color.init(
            0.5,
            0.7,
            1.0,
        )).mul(t));
    }
}

const HitRecord = struct {
    p: vec3.Point3,
    normal: vec3.Vec3,
    t: f64,
    front_face: bool,

    pub fn setFaceNormal(self: *@This(), ray: rays.Ray, outward_normal: vec3.Vec3) void {
        self.front_face = ray.direction.dot(outward_normal) < 0;
        self.normal = if (self.front_face) outward_normal else outward_normal.mul(-1);
    }
};

const Hittable = struct {
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

// Now we expand this
const Sphere = struct {
    center: vec3.Point3,
    radius: f64,
    hittable: Hittable,

    pub fn init(c: vec3.Point3, r: f64) @This() {
        return .{ .center = c, .radius = r, .hittable = .{ .hitFn = hit } };
    }

    fn hit(hittable: *Hittable, ray: rays.Ray, t_min: f64, t_max: f64, hit_record: *HitRecord) bool {
        const self = @fieldParentPtr(@This(), "hittable", hittable);
        const oc = ray.origin.sub(self.center);
        const a = ray.direction.dot(ray.direction);
        const half_b = oc.dot(ray.direction);
        const c = oc.dot(oc) - (self.radius * self.radius);
        const discriminant = (half_b * half_b) - (a * c);
        if (discriminant > 0) {
            const disc_root = std.math.sqrt(discriminant);
            // quadratic formula, there are 2 roots
            // try the first root
            const neg_root = (-half_b - disc_root) / a;
            // if that's in range use it
            if (neg_root < t_max and neg_root > t_min) {
                hit_record.t = neg_root;
                hit_record.p = ray.at(hit_record.t);
                const outward_normal = hit_record.p.sub(self.center).div(self.radius);
                hit_record.setFaceNormal(ray, outward_normal);
                return true;
            }
            // otherwise try the other root
            const pos_root = (-half_b + disc_root) / a;
            if (pos_root < t_max and pos_root > t_min) {
                hit_record.t = pos_root;
                hit_record.p = ray.at(hit_record.t);
                const outward_normal = hit_record.p.sub(self.center).div(self.radius);
                hit_record.setFaceNormal(ray, outward_normal);
                return true;
            }
        }

        return false;
    }
};

/// Owns the lifetime of the itmes added
/// Will call deinit on each Hittable
const HitList = struct {
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
