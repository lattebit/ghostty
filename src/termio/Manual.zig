//! Manual implements a termio backend that does not spawn a subprocess or
//! allocate a PTY. Instead, it allows external code to feed VT byte streams
//! directly into the terminal via Termio.processOutput(). Write requests
//! (keyboard input) are forwarded to the host application via the
//! forward_write action so it can send them to the remote endpoint.
const Manual = @This();

const std = @import("std");
const Allocator = std.mem.Allocator;
const apprt = @import("../apprt.zig");
const renderer = @import("../renderer.zig");
const terminal = @import("../terminal/main.zig");
const termio = @import("../termio.zig");

const log = std.log.scoped(.io_manual);

pub fn init() Manual {
    return .{};
}

pub fn deinit(self: *Manual) void {
    _ = self;
}

pub fn initTerminal(self: *Manual, term: *terminal.Terminal) void {
    _ = self;
    _ = term;
}

pub fn threadEnter(
    self: *Manual,
    alloc: Allocator,
    io: *termio.Termio,
    td: *termio.Termio.ThreadData,
) !void {
    _ = self;
    _ = alloc;
    _ = io;
    td.backend = .{ .manual = .{} };
}

pub fn threadExit(self: *Manual, td: *termio.Termio.ThreadData) void {
    _ = self;
    _ = td;
}

pub fn focusGained(
    self: *Manual,
    td: *termio.Termio.ThreadData,
    focused: bool,
) !void {
    _ = self;
    _ = td;
    _ = focused;
}

pub fn resize(
    self: *Manual,
    grid_size: renderer.GridSize,
    screen_size: renderer.ScreenSize,
) !void {
    _ = self;
    _ = grid_size;
    _ = screen_size;
}

pub fn queueWrite(
    self: *Manual,
    alloc: Allocator,
    td: *termio.Termio.ThreadData,
    data: []const u8,
    linefeed: bool,
) !void {
    _ = self;

    // Forward keyboard input to the host application so it can relay
    // the data to the remote endpoint (e.g., SSH channel, serial port).
    const payload = if (linefeed) try expandCrLf(alloc, data) else data;
    defer if (linefeed) alloc.free(payload);
    _ = td.surface_mailbox.push(.{
        .forward_write = try apprt.surface.Message.WriteReq.init(alloc, payload),
    }, .{ .instant = {} });
}

/// Expand bare CR to CR+LF for linefeed mode (DEC mode 20).
fn expandCrLf(alloc: Allocator, data: []const u8) ![]const u8 {
    const cr_count = std.mem.count(u8, data, "\r");
    if (cr_count == 0) return alloc.dupe(u8, data);
    const buf = try alloc.alloc(u8, data.len + cr_count);
    var j: usize = 0;
    for (data) |ch| {
        buf[j] = ch;
        j += 1;
        if (ch == '\r') {
            buf[j] = '\n';
            j += 1;
        }
    }
    return buf[0..j];
}

pub fn childExitedAbnormally(
    self: *Manual,
    gpa: Allocator,
    t: *terminal.Terminal,
    exit_code: u32,
    runtime_ms: u64,
) !void {
    _ = self;
    _ = gpa;
    _ = t;
    _ = exit_code;
    _ = runtime_ms;
}

/// Thread data for the manual backend. No special state needed.
pub const ThreadData = struct {
    pub fn deinit(self: *ThreadData, alloc: Allocator) void {
        _ = self;
        _ = alloc;
    }
};

/// Configuration for the manual backend.
pub const Config = struct {};
