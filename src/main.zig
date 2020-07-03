const std = @import("std");
const vec3 = @import("vec3.zig");
const color = @import("color.zig");
const rays = @import("ray.zig");
const hits = @import("hit.zig");
const util = @import("util.zig");
const mat = @import("material.zig");
const camera = @import("camera.zig");

const stdout = std.io.getStdOut();
const stderr = std.io.getStdErr();

// Todo make an arena
const allocator = std.heap.c_allocator;
//const allocator = std.heap.c_allocator;

/// ArrayList doesn't have the right interface for a stream
/// but no reason it can't be used as such
/// this gives it the right interface
fn arrayListWriterWrapper(wrapper: DynamicBufferWrapper, data: []const u8) anyerror!usize {
    try wrapper.array.appendSlice(data);
    return data.len;
}

/// A context has to be passed by value so it needs to
/// be a pointer to the ArrayList
const DynamicBufferWrapper = struct {
    array: *std.ArrayList(u8),
};

const DynamicBufferWriter = std.io.Writer(
    DynamicBufferWrapper,
    anyerror,
    arrayListWriterWrapper,
);

pub fn main() anyerror!void {
    try util.initRandom();
    const aspect_ratio: f64 = 16.0 / 9.0;
    const image_width: i32 = 384;
    const image_height = @floatToInt(i32, (@intToFloat(f64, image_width) / aspect_ratio));
    const samples_per_pixel: i32 = 100;
    const max_depth: i32 = 50;

    const outstream = stdout.outStream();
    var intermediate_buffer = try std.ArrayList(u8).initCapacity(allocator, 1024 * 1024);
    defer intermediate_buffer.deinit();
    const wrapper = DynamicBufferWrapper{ .array = &intermediate_buffer };
    var stream = DynamicBufferWriter{ .context = wrapper };

    try outstream.print("P3\n{} {}\n255\n", .{ image_width, image_height });

    // materials
    var lambertian = mat.Lambertian.init(color.Color.init(0.1, 0.2, 0.5));
    var lambertian_2 = mat.Lambertian.init(color.Color.init(0.8, 0.8, 0));
    var metal = mat.Metal.init(color.Color.init(0.8, 0.6, 0.2));
    var metal_2 = mat.Metal.init(color.Color.init(0.8, 0.8, 0.8));
    var glass = mat.Dielectric.init(1.5);

    // objects
    var sphere = Sphere.init(vec3.Point3.init(0, 0, -1), 0.5, &lambertian.material);
    var ground_sphere = Sphere.init(vec3.Point3.init(0, -100.5, -1), 100, &lambertian_2.material);
    var metal_sphere = Sphere.init(vec3.Point3.init(1, 0, -1), 0.5, &metal.material);
    var metal_sphere_2 = Sphere.init(vec3.Point3.init(-1, 0, -1), -0.5, &glass.material);
    var world = hits.HitList.init(allocator);
    defer world.deinit();
    try world.add(&sphere.hittable);
    try world.add(&ground_sphere.hittable);
    try world.add(&metal_sphere.hittable);
    try world.add(&metal_sphere_2.hittable);

    const look_from = vec3.Point3.init(3, 3, 2);
    const look_at = vec3.Point3.init(0, 0, -1);
    const vup = vec3.Vec3.init(0, 1, 0);
    const dist_to_focus = look_from.sub(look_at).magnitude();
    const aperature = 2.0;
    var cam = camera.Camera.init(
        look_from,
        look_at,
        vup,
        20,
        aspect_ratio,
        aperature,
        dist_to_focus,
    );

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
                const r_color = rayColor(r, &world.hittable, max_depth);

                _ = pixel_color.addEq(r_color);
            }
            try color.writeColorMultiSample(
                stream,
                pixel_color,
                samples_per_pixel,
            );
        }
    }

    try stderr.outStream().print("\nWriting to file...\n", .{});

    try outstream.writeAll(intermediate_buffer.items);
    try stderr.outStream().print("\nDone.\n", .{});
}

fn rayColor(ray: rays.Ray, world: *hits.Hittable, depth: i32) color.Color {
    if (depth <= 0) {
        return color.Color.init(0, 0, 0);
    }
    var rec: hits.HitRecord = undefined;
    if (world.hit(ray, 0.001, util.infinity, &rec)) { // on the sphere
        var scattered: rays.Ray = .{ .origin = vec3.Vec3.init(0, 0, 0), .direction = vec3.Vec3.init(0, 0, 0) };
        var attenuation: color.Color = color.Color.init(0, 0, 0);
        if (rec.material.scatter(ray, rec, &attenuation, &scattered)) {
            const next_rc = rayColor(scattered, world, depth - 1);
            return next_rc.componentwiseMul(attenuation);
        }
        return color.Color.init(0, 0, 0);
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

// Now we expand this
const Sphere = struct {
    center: vec3.Point3,
    radius: f64,
    hittable: hits.Hittable,
    material: *mat.Material,

    /// Does not own the material, just has a reference to it
    pub fn init(c: vec3.Point3, r: f64, material: *mat.Material) @This() {
        return .{
            .center = c,
            .radius = r,
            .hittable = .{ .hitFn = hit },
            .material = material,
        };
    }

    fn hit(hittable: *hits.Hittable, ray: rays.Ray, t_min: f64, t_max: f64, hit_record: *hits.HitRecord) bool {
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
                hit_record.material = self.material;
                return true;
            }
            // otherwise try the other root
            const pos_root = (-half_b + disc_root) / a;
            if (pos_root < t_max and pos_root > t_min) {
                hit_record.t = pos_root;
                hit_record.p = ray.at(hit_record.t);
                const outward_normal = hit_record.p.sub(self.center).div(self.radius);
                hit_record.setFaceNormal(ray, outward_normal);
                hit_record.material = self.material;
                return true;
            }
        }

        return false;
    }
};
