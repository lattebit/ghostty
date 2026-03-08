const builtin = @import("builtin");

/// True when targeting OpenGL ES (Android).
pub const is_gles = builtin.target.abi.isAndroid();

pub const c = @cImport({
    if (is_gles) {
        @cInclude("GLES3/gl32.h");
        @cInclude("GLES2/gl2ext.h");
    } else {
        @cInclude("glad/gl.h");
    }
});
