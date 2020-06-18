const std = @import("std");

pub const infinity = std.math.inf_f64;
pub const pi: f64 = 3.1415926535897932385;

pub fn degreesToRadians(degrees: f64) f64 {
    return degrees * pi / 180.0;
}

pub fn random() f64 {
    var buf: [8]u8 = undefined;
    std.crypto.randomBytes(buf[0..]) catch unreachable;
    const seed = std.mem.readIntLittle(u64, buf[0..8]);

    var r = std.rand.DefaultPrng.init(seed);
    const s = r.random.float(f64);
    return s;
}

pub fn randomInRange(min: f64, max: f64) f64 {
    std.debug.assert(max >= min);
    return min + (max - min) * random();
}

test "get rands" {
    var i: i32 = 0;
    while (i < 10000) : (i += 1) {
        const r = random();
        std.debug.assert(r <= 1);
    }
}
