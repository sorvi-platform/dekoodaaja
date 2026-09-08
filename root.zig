const std = @import("std");
pub const qoi = @import("fmt/qoi.zig");

pub const all_decoders: []const type = &.{
    qoi,
};

pub const Colorspace = enum {
    srgb,
    srgb_linear_alpha,
    rgb,
    rgba,

    pub fn channels(self: @This()) u2 {
        switch (self) {
            .srgb => 3,
            .srgb_linear_alpha => 4,
            .rgb => 3,
            .rgba => 4,
        }
    }
};

pub const Header = struct {
    w: u32,
    h: u32,
    colorspace: Colorspace,
};

/// Detect the image format from a path extension
pub fn detectExtension(path: []const u8, comptime decoders: []const type) ?[]const u8 {
    inline for (decoders) |d| {
        if (d.detectExtension(path)) return d.mime;
    }
    return null;
}

/// Detect the image format from a source
pub fn detectStream(source: *std.Io.Reader, comptime decoders: []const type) ?[]const u8 {
    inline for (decoders) |d| {
        if (d.detectStream(source)) return d.mime;
    }
    return null;
}

pub const Error = error{MalformedStream} || std.Io.Reader.Error || std.Io.Writer.Error;

/// Decode image from a source
/// Writes pixels in [31:0] A:R:G:B 8:8:8:8 format (BGRA little-endian) to the sink
/// Returns null if source does not contain a known image format
pub fn decode(noalias source: *std.Io.Reader, noalias sink: *std.Io.Writer, comptime decoders: []const type) Error!?Header {
    inline for (decoders) |d| {
        if (d.detectStream(source)) {
            return d.decode(source, sink) catch |err| return switch (err) {
                error.EndOfStream, error.ReadFailed, error.WriteFailed => |e| e,
                else => error.MalformedStream,
            };
        }
    }
    return null;
}
