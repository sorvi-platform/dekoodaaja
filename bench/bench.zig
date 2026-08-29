const std = @import("std");
const build_options = @import("build_options");
const dekoodaaja = @import("dekoodaaja");

const total_rounds = 4096;
const raw_data = @embedFile("assets/zero.raw");

// this is the arena allocator, for C libs this is used to implement custom malloc
// free is always no-op as arena memory is reused, this effecively gets rid of
// allocator bias for C impls
var c_allocator: ?std.mem.Allocator = null;

export fn dekoodaaja_bench_malloc(n: usize) ?*anyopaque {
    return c_allocator.?.rawAlloc(n, .of(std.c.max_align_t), @returnAddress());
}

fn dekoodaaja_bench_rs_malloc(n: usize, alignment: usize) callconv(.c) ?*anyopaque {
    return c_allocator.?.rawAlloc(n, .fromByteUnits(alignment), @returnAddress());
}

// for things that do not allow overriding malloc
fn malloc(n: usize) callconv(.c) ?*anyopaque {
    if (c_allocator) |a| {
        return a.rawAlloc(n, .of(std.c.max_align_t), @returnAddress());
    } else {
        // leaks but whatever
        return std.heap.smp_allocator.rawAlloc(n, .of(std.c.max_align_t), @returnAddress());
    }
}

fn free(_: ?*anyopaque) callconv(.c) void {}

comptime {
    // <https://codeberg.org/ziglang/zig/issues/36678>
    if (!@import("builtin").target.isMuslLibC()) {
        @export(&malloc, .{ .name = "malloc" });
        @export(&free, .{ .name = "free" });
    }
}

const QoiDecoder = struct {
    const name = "qoi <https://github.com/phoboslab/qoi.git>";
    const ext = "qoi";
    const mime = "image/qoi";
    const is_swizzled = true;

    fn decode(noalias source: *std.Io.Reader, noalias sink: *std.Io.Writer) !dekoodaaja.Header {
        const c = @import("qoi");
        var desc: c.qoi_desc = undefined;
        const bytes: [*]u8 = @ptrCast(c.qoi_decode(source.buffer.ptr, @intCast(source.buffer.len), &desc, 4));
        const raw_size = desc.width * desc.height * 4;
        sink.buffer = std.mem.sliceAsBytes(bytes[0..raw_size]);
        sink.advance(raw_size);
        return .{ .w = desc.width, .h = desc.height };
    }
};

const QoiSimdDecoder = struct {
    const name = "qoi-simd <https://github.com/chocolate42/qoi-simd>";
    const ext = "qoi";
    const mime = "image/qoi";
    const is_swizzled = true;

    fn decode(noalias source: *std.Io.Reader, noalias sink: *std.Io.Writer) !dekoodaaja.Header {
        const c = @import("qoi-simd");
        var desc: c.qoi_desc = undefined;
        const bytes: [*]u8 = @ptrCast(c.qoi_decode(source.buffer.ptr, @intCast(source.buffer.len), &desc, 4));
        const raw_size = desc.width * desc.height * 4;
        sink.buffer = std.mem.sliceAsBytes(bytes[0..raw_size]);
        sink.advance(raw_size);
        return .{ .w = desc.width, .h = desc.height };
    }
};

const MagicQoiDecoder = struct {
    const name = "magicqoi <https://github.com/marty1885/magicqoi>";
    const ext = "qoi";
    const mime = "image/qoi";
    const is_swizzled = true;

    fn decode(noalias source: *std.Io.Reader, noalias sink: *std.Io.Writer) !dekoodaaja.Header {
        const c = @import("magicqoi");
        var w: u32 = undefined;
        var h: u32 = undefined;
        var cc: u32 = undefined;
        const bytes: [*]u8 = c.magicqoi_decode_mem(source.buffer.ptr, source.buffer.len, &w, &h, &cc);
        const raw_size = w * h * 4;
        sink.buffer = std.mem.sliceAsBytes(bytes[0..raw_size]);
        sink.advance(raw_size);
        return .{ .w = w, .h = h };
    }
};

const ZigQoiDecoder = struct {
    const name = "zig-qoi <https://github.com/ikskuh/zig-qoi>";
    const ext = "qoi";
    const mime = "image/qoi";
    const is_swizzled = true;

    fn decode(noalias source: *std.Io.Reader, noalias sink: *std.Io.Writer) !dekoodaaja.Header {
        const qoi = @import("zig-qoi");
        const allocating: *std.Io.Writer.Allocating = @fieldParentPtr("writer", sink);
        const img = try qoi.decodeStream(allocating.allocator, source);
        allocating.writer.buffer = std.mem.sliceAsBytes(img.pixels);
        sink.advance(sink.buffer.len);
        return .{ .w = img.width, .h = img.height };
    }
};

const ZQoiDecoder = struct {
    const name = "zqoi <https://codeberg.org/Pivok/zqoi.git>";
    const ext = "qoi";
    const mime = "image/qoi";
    const is_swizzled = true;

    fn decode(noalias source: *std.Io.Reader, noalias sink: *std.Io.Writer) !dekoodaaja.Header {
        const qoi = @import("zqoi");
        const allocating: *std.Io.Writer.Allocating = @fieldParentPtr("writer", sink);
        const img: qoi.Image = try .fromReader(allocating.allocator, source);
        allocating.writer.buffer = std.mem.sliceAsBytes(img.pixels);
        sink.advance(sink.buffer.len);
        return .{ .w = img.width, .h = img.height };
    }
};

const RapidQoiDecoder = struct {
    const name = "rapid-qoi <https://github.com/zakarumych/rapid-qoi>";
    const ext = "qoi";
    const mime = "image/qoi";
    const is_swizzled = true;

    fn decode(noalias source: *std.Io.Reader, noalias sink: *std.Io.Writer) !dekoodaaja.Header {
        const rs = @import("rs");
        var hdr: rs.header = undefined;
        const bytes: [*]u8 = @ptrCast(rs.decode_rapid_qoi(source.buffer.ptr, source.buffer.len, &hdr));
        const raw_size = hdr.width * hdr.height * 4;
        sink.buffer = std.mem.sliceAsBytes(bytes[0..raw_size]);
        sink.advance(raw_size);
        return .{ .w = hdr.width, .h = hdr.height };
    }
};

const QoiRustDecoder = struct {
    const name = "qoi-rust <https://github.com/aldanor/qoi-rust>";
    const ext = "qoi";
    const mime = "image/qoi";
    const is_swizzled = true;

    fn decode(noalias source: *std.Io.Reader, noalias sink: *std.Io.Writer) !dekoodaaja.Header {
        const rs = @import("rs");
        var hdr: rs.header = undefined;
        const bytes: [*]u8 = @ptrCast(rs.decode_qoi_rust(source.buffer.ptr, source.buffer.len, &hdr));
        const raw_size = hdr.width * hdr.height * 4;
        sink.buffer = std.mem.sliceAsBytes(bytes[0..raw_size]);
        sink.advance(raw_size);
        return .{ .w = hdr.width, .h = hdr.height };
    }
};

const QoicoubehDecoder = struct {
    const name = "qoicoubeh <https://github.com/elmarco/qoi-rust>";
    const ext = "qoi";
    const mime = "image/qoi";
    const is_swizzled = true;

    fn decode(noalias source: *std.Io.Reader, noalias sink: *std.Io.Writer) !dekoodaaja.Header {
        const rs = @import("rs");
        var hdr: rs.header = undefined;
        const bytes: [*]u8 = @ptrCast(rs.decode_qoicoubeh(source.buffer.ptr, source.buffer.len, &hdr));
        const raw_size = hdr.width * hdr.height * 4;
        sink.buffer = std.mem.sliceAsBytes(bytes[0..raw_size]);
        sink.advance(raw_size);
        return .{ .w = hdr.width, .h = hdr.height };
    }
};

const decoders = dekoodaaja.all_decoders ++ (if (build_options.external) .{
    QoiDecoder,
    ZigQoiDecoder,
    ZQoiDecoder,
} ++ (if (@import("builtin").target.os.tag != .windows) .{
    MagicQoiDecoder,
} else .{}) ++ (if (@import("builtin").target.cpu.arch == .x86_64) .{
    QoiSimdDecoder,
} else .{}) else .{}) ++ (if (build_options.rust) .{
    RapidQoiDecoder,
    QoiRustDecoder,
    QoicoubehDecoder,
} else .{});

const Result = struct {
    ns: u64,
    in: usize,
};

fn benchDecoder(dec: type, arena: *std.heap.ArenaAllocator, root: std.Progress.Node, swizzled: []const u8) !Result {
    const node = root.start(std.fmt.comptimePrint("{s} ({s})", .{ dec.name, dec.mime }), total_rounds);
    defer node.end();
    const src_data = @embedFile("assets/zero." ++ dec.ext);
    var total_time: u64 = 0;
    var rounds: usize = total_rounds;
    while (rounds > 0) : (rounds -= 1) {
        const start_point = nanoTimestamp();
        var reader: std.Io.Reader = .fixed(src_data);
        var allocating: std.Io.Writer.Allocating = .init(arena.allocator());
        const hdr = try dec.decode(&reader, &allocating.writer);
        const end_point = nanoTimestamp();
        total_time += @as(u64, @intCast(end_point - start_point));

        if (@hasDecl(dec, "is_swizzled") and dec.is_swizzled) {
            if (hdr.w != 512 or hdr.h != 512 or !std.mem.eql(u8, swizzled, allocating.written()))
                return error.DecodingError;
        } else {
            if (hdr.w != 512 or hdr.h != 512 or !std.mem.eql(u8, raw_data, allocating.written()))
                return error.DecodingError;
        }

        node.completeOne();
        _ = arena.reset(.retain_capacity);
    }
    return .{ .ns = total_time, .in = src_data.len * total_rounds };
}

fn runHarness(progress: std.Progress.Node) !void {
    var swizzled = raw_data.*;
    {
        const pixels = std.mem.bytesAsSlice(u32, &swizzled);
        const swizzle: @Vector(4, u8) = .{ 2, 1, 0, 3 };
        for (pixels) |*p| p.* = @bitCast(@shuffle(u8, @as([4]u8, @bitCast(p.*)), undefined, swizzle));
    }

    if (build_options.rust) {
        @import("rs").set_malloc(dekoodaaja_bench_rs_malloc);
    }

    const root = progress.start("decoders", decoders.len);
    defer root.end();
    var arena: std.heap.ArenaAllocator = .init(std.heap.smp_allocator);
    defer arena.deinit();
    _ = try arena.allocator().alloc(u8, 3.2e+7);
    _ = arena.reset(.retain_capacity);
    c_allocator = arena.allocator();
    inline for (decoders) |d| {
        if (benchDecoder(d, &arena, root, &swizzled)) |res| {
            const in: f64 = @floatFromInt(res.in);
            const out: f64 = @floatFromInt(@as(u64, raw_data.len) * @as(u64, total_rounds));
            const seconds = @as(f64, @floatFromInt(res.ns)) / std.time.ns_per_s;
            const gbps_in = in / seconds / 1e9;
            const gbps_out = out / seconds / 1e9;
            std.debug.print("{s} ({s}): {d:.2} GB/s in, {d:.2} GB/s out, {f}\n", .{
                d.name,
                d.mime,
                gbps_in,
                gbps_out,
                duration(res.ns / total_rounds),
            });
        } else |err| {
            std.debug.print("{s} ({s}): {}\n", .{ d.name, d.mime, err });
        }
    }
}

fn zig15main() !void {
    const progress = std.Progress.start(.{});
    defer progress.end();
    try runHarness(progress);
}

fn zig16main(init: std.process.Init) !void {
    const progress = std.Progress.start(init.io, .{});
    defer progress.end();
    try runHarness(progress);
}

fn nanoTimestamp() i128 {
    switch (@import("builtin").zig_version.minor) {
        15 => return std.time.nanoTimestamp(),
        else => {
            const io = std.Io.Threaded.global_single_threaded.io();
            return std.Io.Timestamp.now(io, .awake).toNanoseconds();
        },
    }
}

fn duration(in: u64) switch (@import("builtin").zig_version.minor) {
    15 => struct {
        nanoseconds: u64,
        pub fn format(self: @This(), w: *std.Io.Writer) !void {
            try w.print("{D}", .{self.nanoseconds});
        }
    },
    else => std.Io.Duration,
} {
    return .{ .nanoseconds = in };
}

pub const main = switch (@import("builtin").zig_version.minor) {
    15 => zig15main,
    else => zig16main,
};
