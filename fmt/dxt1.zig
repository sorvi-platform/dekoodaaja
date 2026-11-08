pub const name = "dxt1";
pub const ext = "dxt1";
pub const mime = "image/x-dxt1";

pub fn detectExtension(path: []const u8) bool {
    return std.mem.endsWith(u8, path, "." ++ ext);
}

pub fn detectStream(_: *std.Io.Reader) bool {
    // this is a raw dxt1 decoder, it uses made up format without any standard container
    return false;
}

pub const Error = error{InvalidDimensions} || std.Io.Reader.Error || std.Io.Writer.Error;

/// Decode dxt1 blocks from a source
/// Writes pixels in [31:0] A:R:G:B 8:8:8:8 format (BGRA little-endian) to the sink
pub fn decodeRaw(w: u16, h: u16, noalias source: *std.Io.Reader, noalias sink: *std.Io.Writer) Error!void {
    const bw, const bh = .{ w / 4, h / 4 };
    const size = std.math.mul(usize, w, h) catch return error.InvalidDimensions;
    const raw_size = std.math.mul(usize, size, @sizeOf(Pixel)) catch return error.InvalidDimensions;
    const buffer: []Pixel = @alignCast(std.mem.bytesAsSlice(Pixel, (try sink.writableSliceGreedy(raw_size))[0..raw_size]));
    for (0..bh) |by| {
        for (0..bw) |bx| {
            var pal: [4]Pixel = undefined;
            pal[0], pal[1] = .{
                (try source.takeStruct(Bgr565, .little)).toBgra(),
                (try source.takeStruct(Bgr565, .little)).toBgra(),
            };
            if (pal[0].toInt() > pal[1].toInt()) {
                pal[2] = pal[0].lerp(pal[1], 1, 3);
                pal[3] = pal[0].lerp(pal[1], 2, 3);
            } else {
                pal[2] = pal[0].mix(pal[1]);
                pal[3] = .transparent;
            }
            const idx = try source.takeInt(u32, .little);
            var px: [16]Pixel = undefined;
            for (0..16) |i| px[i] = pal[(idx >> @intCast(2 * i)) & 3];
            for (0..4) |y| {
                for (0..4) |x| {
                    const dst = ((by * 4 + y) * w + bx * 4 + x);
                    buffer[dst] = px[y * 4 + x];
                }
            }
        }
    }
    sink.advance(raw_size);
    std.debug.assert(sink.end == raw_size);
}

const Bgr565 = packed struct(u16) {
    b: u5,
    g: u6,
    r: u5,

    fn toBgra(self: @This()) Pixel {
        const bgra: Pixel = .{ .c = .{ .b = self.b, .g = self.g, .r = self.r, .a = 255 } };
        const sl: @Vector(4, u8) = .{ 3, 2, 3, 0 };
        const sr: @Vector(4, u8) = .{ 2, 4, 2, 0 };
        return @bitCast((bgra.toVector() << sl) | (bgra.toVector() >> sr));
    }
};

const Pixel = packed struct(u32) {
    c: switch (@import("builtin").cpu.arch.endian()) {
        .little => packed struct(u32) { b: u8, g: u8, r: u8, a: u8 },
        .big => packed struct(u32) { a: u8, r: u8, g: u8, b: u8 },
    },

    const transparent: @This() = .{ .c = .{ .r = 0, .g = 0, .b = 0, .a = 0 } };

    fn toInt(self: @This()) u32 {
        return @bitCast(self);
    }

    fn toVector(self: @This()) @Vector(4, u8) {
        return @bitCast(self);
    }

    fn lerp(a: @This(), b: @This(), num: u8, den: u8) @This() {
        const num_vec: @Vector(4, u8) = @splat(num);
        const den_vec: @Vector(4, u8) = @splat(den);
        return @bitCast(((den_vec - num_vec) * a.toVector() + num_vec * b.toVector()) / den_vec);
    }

    fn mix(a: @This(), b: @This()) @This() {
        const half: @Vector(4, u8) = @splat(2);
        return @bitCast((a.toVector() + b.toVector()) / half);
    }
};

const Header = @import("../root.zig").Header;
const std = @import("std");
