#include "common.glsl"

layout(binding = 0) uniform sampler2D image;

flat in vec4 bg_color;
flat in vec2 v_offset;
flat in vec2 v_scale;
flat in float opacity;
flat in uint repeat;

layout(location = 0) out vec4 out_FragColor;

void main() {
    bool use_linear_blending = (bools & USE_LINEAR_BLENDING) != 0;

    // Flip Y: ES has lower-left origin, we need upper-left.
    vec2 frag_coord = vec2(gl_FragCoord.x, screen_size.y - gl_FragCoord.y);

    vec2 tex_coord = (frag_coord - v_offset) * v_scale;
    vec2 tex_size = vec2(textureSize(image, 0));

    if (repeat != 0u) {
        tex_coord = mod(mod(tex_coord, tex_size) + tex_size, tex_size);
    }

    vec4 rgba;
    if (any(lessThan(tex_coord, vec2(0.0))) ||
            any(greaterThan(tex_coord, tex_size)))
    {
        rgba = vec4(0.0);
    } else {
        rgba = texture(image, tex_coord / tex_size);

        if (!use_linear_blending) {
            rgba = unlinearize(rgba);
        }

        rgba.rgb *= rgba.a;
    }

    rgba *= min(opacity, 1.0 / bg_color.a);
    rgba += max(vec4(0.0), vec4(bg_color.rgb, 1.0) * vec4(1.0 - rgba.a));
    rgba *= bg_color.a;

    out_FragColor = rgba;
}
