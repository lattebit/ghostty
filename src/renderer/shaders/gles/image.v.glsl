#include "common.glsl"

layout(binding = 0) uniform sampler2D image;

layout(location = 0) in vec2 grid_pos;
layout(location = 1) in vec2 cell_offset;
layout(location = 2) in vec4 source_rect;
layout(location = 3) in vec2 dest_size;

out vec2 tex_coord;

void main() {
    int vid = gl_VertexID;

    vec2 corner;
    corner.x = float(vid == 1 || vid == 3);
    corner.y = float(vid == 2 || vid == 3);

    tex_coord = source_rect.xy;
    tex_coord += source_rect.zw * corner;

    // Normalize coordinates for sampler2D.
    tex_coord /= vec2(textureSize(image, 0));

    vec2 image_pos = (cell_size * grid_pos) + cell_offset;
    image_pos += dest_size * corner;

    gl_Position = projection_matrix * vec4(image_pos.xy, 1.0, 1.0);
}
