#version 310 es
#extension GL_EXT_shader_io_blocks : enable
precision highp float;
precision highp int;

// These are common definitions to be shared across shaders, the first
// line of any shader that needs these should be `#include "common.glsl"`.

//----------------------------------------------------------------------------//
// Global Uniforms
//----------------------------------------------------------------------------//
layout(binding = 1, std140) uniform Globals {
    mat4 projection_matrix;
    vec2 screen_size;
    vec2 cell_size;
    uint grid_size_packed_2u16;
    vec4 grid_padding;
    uint padding_extend;
    float min_contrast;
    uint cursor_pos_packed_2u16;
    uint cursor_color_packed_4u8;
    uint bg_color_packed_4u8;
    uint bools;
};

// Bools
const uint CURSOR_WIDE = 1u;
const uint USE_DISPLAY_P3 = 2u;
const uint USE_LINEAR_BLENDING = 4u;
const uint USE_LINEAR_CORRECTION = 8u;

// Padding extend enum
const uint EXTEND_LEFT = 1u;
const uint EXTEND_RIGHT = 2u;
const uint EXTEND_UP = 4u;
const uint EXTEND_DOWN = 8u;

//----------------------------------------------------------------------------//
// Functions for Unpacking Values
//----------------------------------------------------------------------------//

uvec4 unpack4u8(uint packed_value) {
    return uvec4(
        uint(packed_value >> 0) & uint(0xFF),
        uint(packed_value >> 8) & uint(0xFF),
        uint(packed_value >> 16) & uint(0xFF),
        uint(packed_value >> 24) & uint(0xFF)
    );
}

uvec2 unpack2u16(uint packed_value) {
    return uvec2(
        uint(packed_value >> 0) & uint(0xFFFF),
        uint(packed_value >> 16) & uint(0xFFFF)
    );
}

ivec2 unpack2i16(int packed_value) {
    return ivec2(
        (packed_value << 16) >> 16,
        (packed_value << 0) >> 16
    );
}

//----------------------------------------------------------------------------//
// Color Functions
//----------------------------------------------------------------------------//

float luminance(vec3 color) {
    return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

float contrast_ratio(vec3 color1, vec3 color2) {
    float luminance1 = luminance(color1) + 0.05;
    float luminance2 = luminance(color2) + 0.05;
    return max(luminance1, luminance2) / min(luminance1, luminance2);
}

vec4 contrasted_color(float min_ratio, vec4 fg, vec4 bg) {
    float ratio = contrast_ratio(fg.rgb, bg.rgb);
    if (ratio < min_ratio) {
        float white_ratio = contrast_ratio(vec3(1.0, 1.0, 1.0), bg.rgb);
        float black_ratio = contrast_ratio(vec3(0.0, 0.0, 0.0), bg.rgb);
        if (white_ratio > black_ratio) {
            return vec4(1.0);
        } else {
            return vec4(0.0, 0.0, 0.0, 1.0);
        }
    }
    return fg;
}

vec4 linearize_vec4(vec4 srgb) {
    bvec3 cutoff = lessThanEqual(srgb.rgb, vec3(0.04045));
    vec3 higher = pow((srgb.rgb + vec3(0.055)) / vec3(1.055), vec3(2.4));
    vec3 lower = srgb.rgb / vec3(12.92);
    return vec4(mix(higher, lower, cutoff), srgb.a);
}
float linearize_float(float v) {
    return v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4);
}

vec4 unlinearize_vec4(vec4 linear_val) {
    bvec3 cutoff = lessThanEqual(linear_val.rgb, vec3(0.0031308));
    vec3 higher = pow(linear_val.rgb, vec3(1.0 / 2.4)) * vec3(1.055) - vec3(0.055);
    vec3 lower = linear_val.rgb * vec3(12.92);
    return vec4(mix(higher, lower, cutoff), linear_val.a);
}
float unlinearize_float(float v) {
    return v <= 0.0031308 ? v * 12.92 : pow(v, 1.0 / 2.4) * 1.055 - 0.055;
}

// GLSL ES 310 does not support function overloading with different
// parameter types (vec4 vs float), so we use distinct names.
#define linearize linearize_vec4
#define unlinearize unlinearize_vec4

vec4 load_color(uvec4 in_color, bool linear_out) {
    vec4 color = vec4(in_color) / vec4(255.0);
    if (linear_out) color = linearize_vec4(color);
    color.rgb *= color.a;
    return color;
}

//----------------------------------------------------------------------------//
