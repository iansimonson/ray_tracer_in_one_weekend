const std = @import("std");

pub const infinity = std.math.inf_f64;
pub const pi: f64 = 3.1415926535897932385;

pub fn degreesToRadians(degrees: f64) f64 {
    return degrees * pi / 180.0;
}

var initialized: bool = false;
var rnd: std.rand.DefaultPrng = undefined;

pub fn initRandom() !void {
    var buf: [8]u8 = undefined;
    try std.crypto.randomBytes(buf[0..]);
    const seed = std.mem.readIntLittle(u64, buf[0..8]);
    rnd = std.rand.DefaultPrng.init(seed);
    initialized = true;
}

pub fn random() f64 {
    std.debug.assert(initialized);
    return rnd.random.float(f64);
}

pub fn randomInRange(min: f64, max: f64) f64 {
    std.debug.assert(initialized);
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
