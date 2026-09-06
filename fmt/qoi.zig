const std = @import("std");

pub const name = "qoi";
pub const ext = "qoi";
pub const mime = "image/qoi";

pub const Channels = enum(u8) {
    rgb = 3,
    rgba = 4,
};

pub const Colorspace = enum(u8) {
    srgb = 0,
    linear = 1,
};

pub const Header = struct {
    w: u32,
    h: u32,
    channels: Channels,
    colorspace: Colorspace,
};

const Op = packed struct(u8) {
    data: u6,
    tag: u2,

    fn rle(n: u6) @This() {
        std.debug.assert(n > 0 and n <= 62);
        return .{ .tag = 0b11, .data = n - 1 };
    }

    fn toInt(self: @This()) u8 {
        return @bitCast(self);
    }
};

const Pixel = packed struct(u32) {
    b: u8,
    g: u8,
    r: u8,
    a: u8,

    const black: @This() = .{ .r = 0, .g = 0, .b = 0, .a = 0xff };
    const transparent: @This() = .{ .r = 0, .g = 0, .b = 0, .a = 0 };

    fn hash(self: @This()) u6 {
        const weights: @Vector(4, u8) = .{ 7, 5, 3, 11 };
        return @truncate(@reduce(.Add, self.toVector() *% weights));
    }

    fn toVector(self: @This()) @Vector(4, u8) {
        return @bitCast(self);
    }

    fn diffRgb(self: @This(), data: u6) @This() {
        const Stream = packed struct(u6) { b: u2, g: u2, r: u2 };
        const diff: Stream = @bitCast(data);
        const bias: @Vector(4, i8) = .{ -2, -2, -2, 0 };
        const vec: @Vector(4, i8) = .{ diff.b, diff.g, diff.r, 0 };
        const sum: @Vector(4, u8) = @bitCast(vec + bias);
        return @bitCast(self.toVector() +% sum);
    }

    fn diffLuma(self: @This(), data: u6, extra: u8) @This() {
        const Stream = packed struct(u16) { g: u6, _: u2, b: u4, r: u4 };
        const payload: [2]u8 = .{ data, extra };
        const diff: Stream = @bitCast(std.mem.readInt(u16, &payload, .little));
        const g: @Vector(4, i8) = .{ diff.g, 0, diff.g, 0 };
        const bias: @Vector(4, i8) = .{ -40, -32, -40, 0 };
        const vec: @Vector(4, i8) = .{ diff.b, diff.g, diff.r, 0 };
        const sum: @Vector(4, u8) = @bitCast(vec + g + bias);
        return @bitCast(self.toVector() +% sum);
    }

    fn fromRgb(rgb: [3]u8, a: u8) @This() {
        return fromRgba(.{ rgb[0], rgb[1], rgb[2], a });
    }

    fn fromRgba(rgba: [4]u8) @This() {
        const swizzle: @Vector(4, u8) = .{ 2, 1, 0, 3 };
        return @bitCast(@shuffle(u8, rgba, undefined, swizzle));
    }
};

pub fn detectExtension(path: []const u8) bool {
    return std.mem.endsWith(u8, path, "." ++ ext);
}

pub fn detectStream(source: *std.Io.Reader) bool {
    return std.mem.eql(u8, source.peekArray(4) catch return false, "qoif");
}

pub const Error = error{ InvalidHeader, InvalidRleChunk } || std.Io.Reader.Error || std.Io.Writer.Error;

/// Decode QOI image from a source
/// Writes pixels in [31:0] A:R:G:B 8:8:8:8 format (BGRA little-endian) to the sink
pub fn decode(noalias source: *std.Io.Reader, noalias sink: *std.Io.Writer) Error!Header {
    if (!std.mem.eql(u8, try source.takeArray(4), "qoif")) return error.InvalidHeader;

    const native_endian = @import("builtin").target.cpu.arch.endian();
    const hdr: Header = .{
        .w = try source.takeInt(u32, .big),
        .h = try source.takeInt(u32, .big),
        .channels = source.takeEnum(Channels, native_endian) catch return error.InvalidHeader,
        .colorspace = source.takeEnum(Colorspace, native_endian) catch return error.InvalidHeader,
    };

    const size = std.math.mul(usize, hdr.w, hdr.h) catch return error.InvalidHeader;
    const raw_size = std.math.mul(usize, size, @sizeOf(Pixel)) catch return error.InvalidHeader;
    const buffer: []Pixel = @alignCast(std.mem.bytesAsSlice(Pixel, (try sink.writableSliceGreedy(raw_size))[0..raw_size]));

    var index: usize = 0;
    var pixel: Pixel = .black;
    var lut: [64]Pixel = undefined;
    memset(Pixel, &lut, .transparent);

    // Handle <https://github.com/phoboslab/qoi/issues/258>
    // Initial QOI_OP_RUN has to be stored into the LUT
    switch (@as(Op, @bitCast(try source.peekByte())).toInt()) {
        Op.rle(1).toInt()...Op.rle(62).toInt() => lut[pixel.hash()] = pixel,
        else => {},
    }

    loop: while (index < buffer.len) : (index += 1) {
        const op: Op = @bitCast(try source.takeByte());
        switch (op.toInt()) {
            0b11111110 => pixel = Pixel.fromRgb((try takeArray(source, 3)), pixel.a),
            0b11111111 => pixel = Pixel.fromRgba((try takeArray(source, 4))),
            0b00000000...0b00111111 => {
                pixel = lut[op.data];
                buffer[index] = pixel;
                continue :loop;
            },
            0b01000000...0b01111111 => pixel = pixel.diffRgb(op.data),
            0b10000000...0b10111111 => pixel = pixel.diffLuma(op.data, try source.takeByte()),
            Op.rle(1).toInt()...Op.rle(62).toInt() => {
                if (op.data + 1 > buffer.len - index) return error.InvalidRleChunk;
                memset(Pixel, buffer[index..][0 .. op.data + 1], pixel);
                index += op.data;
                continue :loop;
            },
        }
        buffer[index] = pixel;
        lut[pixel.hash()] = pixel;
    }

    sink.advance(index * @sizeOf(Pixel));
    std.debug.assert(sink.end == raw_size);
    return hdr;
}

// better codegen for ReleaseSmall
inline fn takeArray(r: *std.Io.Reader, n: comptime_int) ![n]u8 {
    const result = try @call(.always_inline, std.Io.Reader.peek, .{ r, n });
    @call(.always_inline, std.Io.Reader.toss, .{ r, n });
    return result[0..n].*;
}

// slightly modified @kprotty impl
fn memset(T: type, dst: []T, val: T) void {
    switch (dst.len) {
        0 => {},
        1...3 => |len| for ([_]usize{ 0, len / 2, len - 1 }) |i| {
            dst[i] = val;
        },
        else => |len| {
            comptime var chunk = 4;
            inline while (@sizeOf(T) * chunk * 4 <= 64) : (chunk *= 4) {
                if (len <= chunk * 4) {
                    const mid = (len / (chunk * 2)) * chunk;
                    for ([_]usize{ 0, mid, len - chunk, len - chunk - mid }) |i| dst[i..][0..chunk].* = @splat(val);
                    return;
                }
            }
            for (0..(len - 1) / (chunk * 2)) |i| {
                // prevent LLVM from bloating loop via auto-vectorization.
                std.mem.doNotOptimizeAway(i);
                dst[i * (chunk * 2) ..][0..(chunk * 2)].* = @splat(val);
            }
            for ([_]usize{ len -| (chunk * 2), len - chunk }) |i| dst[i..][0..chunk].* = @splat(val);
        },
    }
}
