shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_always;

uniform vec4 trail_color : source_color = vec4(1.0, 0.8, 0.3, 1.0);
uniform float tail_falloff = 2.0;
uniform float width_falloff = 1.5;

void fragment() {
    // Along trail: UV.y = 0 (head) → 1 (tail)
    float t = clamp(UV.y, 0.0, 1.0);

    // Across width: 0.5 is center line
    float dist_to_center = abs(UV.x - 0.5) * 2.0; // 0 at center, 1 at edges
    dist_to_center = clamp(dist_to_center, 0.0, 1.0);

    float tail_factor  = pow(1.0 - t, tail_falloff);
    float width_factor = pow(1.0 - dist_to_center, width_falloff);

    float alpha = tail_factor * width_factor;

    ALBEDO = trail_color.rgb;
    ALPHA  = trail_color.a * alpha;
}