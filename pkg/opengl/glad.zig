const std = @import("std");
const c_mod = @import("c.zig");
const c = c_mod.c;
const is_gles = c_mod.is_gles;

/// The GL function context. On desktop, this is GLAD's loader context.
/// On ES, it is a struct of function pointers initialized to the linked
/// ES symbols so that the same `context.FuncName.?(args)` call pattern
/// works uniformly across both backends.
pub const Context = if (is_gles) GLESContext else c.GladGLContext;

pub threadlocal var context: Context = if (is_gles) .{} else undefined;

pub fn load(getProcAddress: anytype) !c_int {
    if (is_gles) {
        // ES functions are linked directly; no runtime loading needed.
        // Return a fake version encoding for ES 3.2.
        return @bitCast(@as(c_uint, (3 << 16) | 2));
    }

    const GlProc = *const fn () callconv(.c) void;
    const GlfwFn = *const fn ([*:0]const u8) callconv(.c) ?GlProc;

    const res = switch (@TypeOf(getProcAddress)) {
        GlfwFn => c.gladLoadGLContext(&context, @ptrCast(getProcAddress)),
        @TypeOf(null) => c.gladLoaderLoadGLContext(&context),
        else => c.gladLoadGLContext(&context, @ptrCast(getProcAddress)),
    };
    if (res == 0) return error.GLInitFailed;
    return res;
}

pub fn unload() void {
    if (is_gles) return;
    c.gladLoaderUnloadGLContext(&context);
    context = undefined;
}

pub fn versionMajor(res: c_uint) c_uint {
    if (is_gles) return @intCast(res >> 16);
    return c.GLAD_VERSION_MAJOR(res);
}

pub fn versionMinor(res: c_uint) c_uint {
    if (is_gles) return @intCast(res & 0xFFFF);
    return c.GLAD_VERSION_MINOR(res);
}

/// Pre-initialized context for OpenGL ES. Each field is an optional function
/// pointer defaulting to the corresponding linked ES symbol.
const GLESContext = if (is_gles) struct {
    // Buffer
    GenBuffers: ?@TypeOf(&c.glGenBuffers) = &c.glGenBuffers,
    DeleteBuffers: ?@TypeOf(&c.glDeleteBuffers) = &c.glDeleteBuffers,
    BindBuffer: ?@TypeOf(&c.glBindBuffer) = &c.glBindBuffer,
    BindBufferBase: ?@TypeOf(&c.glBindBufferBase) = &c.glBindBufferBase,
    BufferData: ?@TypeOf(&c.glBufferData) = &c.glBufferData,
    BufferSubData: ?@TypeOf(&c.glBufferSubData) = &c.glBufferSubData,
    VertexAttribDivisor: ?@TypeOf(&c.glVertexAttribDivisor) = &c.glVertexAttribDivisor,
    VertexAttribPointer: ?@TypeOf(&c.glVertexAttribPointer) = &c.glVertexAttribPointer,
    VertexAttribIPointer: ?@TypeOf(&c.glVertexAttribIPointer) = &c.glVertexAttribIPointer,
    EnableVertexAttribArray: ?@TypeOf(&c.glEnableVertexAttribArray) = &c.glEnableVertexAttribArray,

    // Draw
    ClearColor: ?@TypeOf(&c.glClearColor) = &c.glClearColor,
    Clear: ?@TypeOf(&c.glClear) = &c.glClear,
    DrawArrays: ?@TypeOf(&c.glDrawArrays) = &c.glDrawArrays,
    DrawArraysInstanced: ?@TypeOf(&c.glDrawArraysInstanced) = &c.glDrawArraysInstanced,
    DrawElements: ?@TypeOf(&c.glDrawElements) = &c.glDrawElements,
    DrawElementsInstanced: ?@TypeOf(&c.glDrawElementsInstanced) = &c.glDrawElementsInstanced,
    Enable: ?@TypeOf(&c.glEnable) = &c.glEnable,
    Disable: ?@TypeOf(&c.glDisable) = &c.glDisable,
    FrontFace: ?@TypeOf(&c.glFrontFace) = &c.glFrontFace,
    BlendFunc: ?@TypeOf(&c.glBlendFunc) = &c.glBlendFunc,
    Viewport: ?@TypeOf(&c.glViewport) = &c.glViewport,
    PixelStorei: ?@TypeOf(&c.glPixelStorei) = &c.glPixelStorei,
    Finish: ?@TypeOf(&c.glFinish) = &c.glFinish,
    Flush: ?@TypeOf(&c.glFlush) = &c.glFlush,

    // Error / query
    GetError: ?@TypeOf(&c.glGetError) = &c.glGetError,
    GetIntegerv: ?@TypeOf(&c.glGetIntegerv) = &c.glGetIntegerv,
    GetStringi: ?@TypeOf(&c.glGetStringi) = &c.glGetStringi,

    // Framebuffer
    GenFramebuffers: ?@TypeOf(&c.glGenFramebuffers) = &c.glGenFramebuffers,
    DeleteFramebuffers: ?@TypeOf(&c.glDeleteFramebuffers) = &c.glDeleteFramebuffers,
    BindFramebuffer: ?@TypeOf(&c.glBindFramebuffer) = &c.glBindFramebuffer,
    FramebufferTexture2D: ?@TypeOf(&c.glFramebufferTexture2D) = &c.glFramebufferTexture2D,
    FramebufferRenderbuffer: ?@TypeOf(&c.glFramebufferRenderbuffer) = &c.glFramebufferRenderbuffer,
    DrawBuffers: ?@TypeOf(&c.glDrawBuffers) = &c.glDrawBuffers,
    CheckFramebufferStatus: ?@TypeOf(&c.glCheckFramebufferStatus) = &c.glCheckFramebufferStatus,
    BlitFramebuffer: ?@TypeOf(&c.glBlitFramebuffer) = &c.glBlitFramebuffer,

    // Renderbuffer
    GenRenderbuffers: ?@TypeOf(&c.glGenRenderbuffers) = &c.glGenRenderbuffers,
    DeleteRenderbuffers: ?@TypeOf(&c.glDeleteRenderbuffers) = &c.glDeleteRenderbuffers,
    BindRenderbuffer: ?@TypeOf(&c.glBindRenderbuffer) = &c.glBindRenderbuffer,
    RenderbufferStorage: ?@TypeOf(&c.glRenderbufferStorage) = &c.glRenderbufferStorage,

    // Program
    CreateProgram: ?@TypeOf(&c.glCreateProgram) = &c.glCreateProgram,
    DeleteProgram: ?@TypeOf(&c.glDeleteProgram) = &c.glDeleteProgram,
    AttachShader: ?@TypeOf(&c.glAttachShader) = &c.glAttachShader,
    LinkProgram: ?@TypeOf(&c.glLinkProgram) = &c.glLinkProgram,
    GetProgramiv: ?@TypeOf(&c.glGetProgramiv) = &c.glGetProgramiv,
    GetProgramInfoLog: ?@TypeOf(&c.glGetProgramInfoLog) = &c.glGetProgramInfoLog,
    UseProgram: ?@TypeOf(&c.glUseProgram) = &c.glUseProgram,
    UniformBlockBinding: ?@TypeOf(&c.glUniformBlockBinding) = &c.glUniformBlockBinding,
    GetUniformLocation: ?@TypeOf(&c.glGetUniformLocation) = &c.glGetUniformLocation,
    Uniform1i: ?@TypeOf(&c.glUniform1i) = &c.glUniform1i,
    Uniform1f: ?@TypeOf(&c.glUniform1f) = &c.glUniform1f,
    Uniform2f: ?@TypeOf(&c.glUniform2f) = &c.glUniform2f,
    Uniform3f: ?@TypeOf(&c.glUniform3f) = &c.glUniform3f,
    Uniform4f: ?@TypeOf(&c.glUniform4f) = &c.glUniform4f,
    UniformMatrix4fv: ?@TypeOf(&c.glUniformMatrix4fv) = &c.glUniformMatrix4fv,

    // Shader
    CreateShader: ?@TypeOf(&c.glCreateShader) = &c.glCreateShader,
    DeleteShader: ?@TypeOf(&c.glDeleteShader) = &c.glDeleteShader,
    ShaderSource: ?@TypeOf(&c.glShaderSource) = &c.glShaderSource,
    CompileShader: ?@TypeOf(&c.glCompileShader) = &c.glCompileShader,
    GetShaderiv: ?@TypeOf(&c.glGetShaderiv) = &c.glGetShaderiv,
    GetShaderInfoLog: ?@TypeOf(&c.glGetShaderInfoLog) = &c.glGetShaderInfoLog,

    // Texture
    ActiveTexture: ?@TypeOf(&c.glActiveTexture) = &c.glActiveTexture,
    GenTextures: ?@TypeOf(&c.glGenTextures) = &c.glGenTextures,
    DeleteTextures: ?@TypeOf(&c.glDeleteTextures) = &c.glDeleteTextures,
    BindTexture: ?@TypeOf(&c.glBindTexture) = &c.glBindTexture,
    TexParameteri: ?@TypeOf(&c.glTexParameteri) = &c.glTexParameteri,
    TexImage2D: ?@TypeOf(&c.glTexImage2D) = &c.glTexImage2D,
    TexSubImage2D: ?@TypeOf(&c.glTexSubImage2D) = &c.glTexSubImage2D,
    CopyTexSubImage2D: ?@TypeOf(&c.glCopyTexSubImage2D) = &c.glCopyTexSubImage2D,
    GenerateMipmap: ?@TypeOf(&c.glGenerateMipmap) = &c.glGenerateMipmap,

    // Vertex array
    GenVertexArrays: ?@TypeOf(&c.glGenVertexArrays) = &c.glGenVertexArrays,
    DeleteVertexArrays: ?@TypeOf(&c.glDeleteVertexArrays) = &c.glDeleteVertexArrays,
    BindVertexArray: ?@TypeOf(&c.glBindVertexArray) = &c.glBindVertexArray,
    VertexBindingDivisor: ?@TypeOf(&c.glVertexBindingDivisor) = &c.glVertexBindingDivisor,
    VertexAttribBinding: ?@TypeOf(&c.glVertexAttribBinding) = &c.glVertexAttribBinding,
    VertexAttribFormat: ?@TypeOf(&c.glVertexAttribFormat) = &c.glVertexAttribFormat,
    VertexAttribIFormat: ?@TypeOf(&c.glVertexAttribIFormat) = &c.glVertexAttribIFormat,
    BindVertexBuffer: ?@TypeOf(&c.glBindVertexBuffer) = &c.glBindVertexBuffer,

    // Sampler
    GenSamplers: ?@TypeOf(&c.glGenSamplers) = &c.glGenSamplers,
    DeleteSamplers: ?@TypeOf(&c.glDeleteSamplers) = &c.glDeleteSamplers,
    BindSampler: ?@TypeOf(&c.glBindSampler) = &c.glBindSampler,
    SamplerParameteri: ?@TypeOf(&c.glSamplerParameteri) = &c.glSamplerParameteri,

    // Debug (ES 3.2)
    DebugMessageCallback: ?@TypeOf(&c.glDebugMessageCallback) = &c.glDebugMessageCallback,
} else void;
