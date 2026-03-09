const std = @import("std");

pub fn build(b: *std.Build) !void {
    const module = b.addModule("opengl", .{ .root_source_file = b.path("main.zig") });

    // GLAD headers are only needed for desktop OpenGL (non-Android targets).
    // For Android/ES, the GLES headers come from the NDK sysroot via libc paths.
    module.addIncludePath(b.path("../../vendor/glad/include"));
}
