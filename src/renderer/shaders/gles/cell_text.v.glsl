#include "common.glsl"

layout(location = 0) in uvec2 glyph_pos;
layout(location = 1) in uvec2 glyph_size;
layout(location = 2) in ivec2 bearings;
layout(location = 3) in uvec2 grid_pos;
layout(location = 4) in uvec4 color;
layout(location = 5) in uint atlas;
layout(location = 6) in uint glyph_bools;

const uint ATLAS_GRAYSCALE = 0u;
const uint ATLAS_COLOR = 1u;

const uint NO_MIN_CONTRAST = 1u;
const uint IS_CURSOR_GLYPH = 2u;

out CellTextVertexOut {
    flat uint atlas;
    flat vec4 color;
    flat vec4 bg_color;
    // Normalized texture coordinates for sampler2D (ES has no sampler2DRect).
    vec2 tex_coord;
} out_data;

layout(binding = 1, std430) readonly buffer bg_cells {
    uint bg_colors[];
};

void main() {
    uvec2 grid_size = unpack2u16(grid_size_packed_2u16);
    uvec2 cursor_pos = unpack2u16(cursor_pos_packed_2u16);
    bool cursor_wide = (bools & CURSOR_WIDE) != 0;
    bool use_linear_blending = (bools & USE_LINEAR_BLENDING) != 0;

    vec2 cell_pos = cell_size * vec2(grid_pos);

    int vid = gl_VertexID;
    vec2 corner;
    corner.x = float(vid == 1 || vid == 3);
    corner.y = float(vid == 2 || vid == 3);

    out_data.atlas = atlas;

    vec2 size = vec2(glyph_size);
    vec2 offset = vec2(bearings);
    offset.y = cell_size.y - offset.y;

    cell_pos = cell_pos + size * corner + offset;
    gl_Position = projection_matrix * vec4(cell_pos.x, cell_pos.y, 0.0, 1.0);

    // Texture coordinates in pixel space; will be normalized in fragment
    // shader by dividing by textureSize().
    out_data.tex_coord = vec2(glyph_pos) + vec2(glyph_size) * corner;

    out_data.color = load_color(color, true);
    out_data.bg_color = load_color(
            unpack4u8(bg_colors[grid_pos.y * grid_size.x + grid_pos.x]),
            true
        );
    vec4 global_bg = load_color(
            unpack4u8(bg_color_packed_4u8),
            true
        );
    out_data.bg_color += global_bg * vec4(1.0 - out_data.bg_color.a);

    if (min_contrast > 1.0 && (glyph_bools & NO_MIN_CONTRAST) == 0u) {
        out_data.color = contrasted_color(min_contrast, out_data.color, out_data.bg_color);
    }

    bool is_cursor_pos = ((grid_pos.x == cursor_pos.x) || (cursor_wide && (grid_pos.x == (cursor_pos.x + 1u)))) && (grid_pos.y == cursor_pos.y);

    if ((glyph_bools & IS_CURSOR_GLYPH) == 0u && is_cursor_pos) {
        out_data.color = load_color(unpack4u8(cursor_color_packed_4u8), use_linear_blending);
    }
}
