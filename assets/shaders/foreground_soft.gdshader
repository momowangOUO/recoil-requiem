shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;

uniform sampler2D artwork : source_color, filter_linear, repeat_disable;
uniform float blur_pixels = 2.8;

void fragment() {
	vec2 step_uv = vec2(blur_pixels) / vec2(textureSize(artwork, 0));
	vec4 sum = vec4(0.0);
	float total = 0.0;
	for (int y = -2; y <= 2; y++) {
		for (int x = -2; x <= 2; x++) {
			float weight = exp(-float(x*x + y*y) * 0.5);
			vec4 sample_color = texture(artwork, UV + vec2(float(x), float(y)) * step_uv);
			sum += vec4(sample_color.rgb * sample_color.a, sample_color.a) * weight;
			total += weight;
		}
	}
	// Premultiplied accumulation prevents black fringes around transparent art.
	ALBEDO = sum.rgb / max(sum.a, 0.0001) * vec3(0.38, 0.40, 0.49);
	float edge = smoothstep(0.62, 0.94, abs(SCREEN_UV.x * 2.0 - 1.0));
	ALPHA = sum.a / total * edge * 0.68;
}
