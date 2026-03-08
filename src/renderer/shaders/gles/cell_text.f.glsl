#include "common.glsl"

// In GLSL ES, sampler2DRect does not exist. We use sampler2D with normalized
// texture coordinates instead (pixel coords are normalized in the shader).
layout(binding = 0) uniform sampler2D atlas_grayscale;
layout(binding = 1) uniform sampler2D atlas_color;

// Atlas texture sizes for normalizing pixel coordinates to [0,1].
uniform vec2 atlas_grayscale_size;
uniform vec2 atlas_color_size;

in CellTextVertexOut {
    flat uint atlas;
    flat vec4 color;
    flat vec4 bg_color;
    vec2 tex_coord;
} in_data;

const uint ATLAS_GRAYSCALE = 0u;
const uint ATLAS_COLOR = 1u;

layout(location = 0) out vec4 out_FragColor;

void main() {
    bool use_linear_blending = (bools & USE_LINEAR_BLENDING) != 0;
    bool use_linear_correction = (bools & USE_LINEAR_CORRECTION) != 0;

    if (in_data.atlas == ATLAS_GRAYSCALE) {
        vec4 color = in_data.color;

        if (!use_linear_blending) {
            color.rgb /= vec3(color.a);
            color = unlinearize(color);
            color.rgb *= vec3(color.a);
        }

        // Normalize pixel coords for sampler2D.
        vec2 norm_coord = in_data.tex_coord / atlas_grayscale_size;
        float a = texture(atlas_grayscale, norm_coord).r;

        if (use_linear_correction) {
            vec4 bg = in_data.bg_color;
            float fg_l = luminance(color.rgb);
            float bg_l = luminance(bg.rgb);
            if (abs(fg_l - bg_l) > 0.001) {
                float blend_l = linearize_float(unlinearize_float(fg_l) * a + unlinearize_float(bg_l) * (1.0 - a));
                a = clamp((blend_l - bg_l) / (fg_l - bg_l), 0.0, 1.0);
            }
        }

        color *= a;
        out_FragColor = color;
    } else {
        // ATLAS_COLOR
        vec2 norm_coord = in_data.tex_coord / atlas_color_size;
        vec4 color = texture(atlas_color, norm_coord);

        if (use_linear_blending) {
            out_FragColor = color;
        } else {
            color.rgb /= vec3(color.a);
            color = unlinearize(color);
            color.rgb *= vec3(color.a);
            out_FragColor = color;
        }
    }
}
