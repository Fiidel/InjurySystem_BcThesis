shader_type spatial;
render_mode unshaded, blend_add, cull_disabled;

uniform vec4 trail_color : source_color = vec4(1.0, 0.8, 0.3, 1.0);
uniform float tail_falloff = 2.0;
uniform float width_falloff = 1.5;

void fragment() {
    float dist_to_center = abs(UV.x - 0.5) * 2.0; // 0 at center, 1 at edges
    float tail_alpha  = pow(1.0 - UV.y, tail_falloff);
    float width_alpha = pow(1.0 - dist_to_center, width_falloff);
    ALBEDO = trail_color.rgb;
    ALPHA  = tail_alpha * width_alpha;
}
