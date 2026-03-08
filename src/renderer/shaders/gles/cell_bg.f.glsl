#include "common.glsl"

// GLSL ES has no layout(origin_upper_left). gl_FragCoord origin is
// lower-left, so we flip Y using screen_size from the uniform block.

layout(location = 0) out vec4 out_FragColor;

layout(binding = 1, std430) readonly buffer bg_cells {
    uint cells[];
};

vec4 cell_bg() {
    uvec2 grid_size = unpack2u16(grid_size_packed_2u16);
    bool use_linear_blending = (bools & USE_LINEAR_BLENDING) != 0;

    // Flip Y to get upper-left origin (ES has lower-left origin).
    vec2 frag_coord = vec2(gl_FragCoord.x, screen_size.y - gl_FragCoord.y);
    ivec2 grid_pos = ivec2(floor((frag_coord - grid_padding.wx) / cell_size));

    vec4 bg = vec4(0.0);

    if (grid_pos.x < 0) {
        if ((padding_extend & EXTEND_LEFT) != 0u) {
            grid_pos.x = 0;
        } else {
            return bg;
        }
    } else if (grid_pos.x > int(grid_size.x) - 1) {
        if ((padding_extend & EXTEND_RIGHT) != 0u) {
            grid_pos.x = int(grid_size.x) - 1;
        } else {
            return bg;
        }
    }

    if (grid_pos.y < 0) {
        if ((padding_extend & EXTEND_UP) != 0u) {
            grid_pos.y = 0;
        } else {
            return bg;
        }
    } else if (grid_pos.y > int(grid_size.y) - 1) {
        if ((padding_extend & EXTEND_DOWN) != 0u) {
            grid_pos.y = int(grid_size.y) - 1;
        } else {
            return bg;
        }
    }

    vec4 cell_color = load_color(
            unpack4u8(cells[grid_pos.y * int(grid_size.x) + grid_pos.x]),
            use_linear_blending
        );

    return cell_color;
}

void main() {
    out_FragColor = cell_bg();
}
