shader_type spatial;
render_mode unshaded, cull_disabled, depth_prepass_alpha;

uniform sampler2D mask_texture : source_color, filter_linear, repeat_disable;
uniform vec4 silhouette_color : source_color = vec4(0.035, 0.025, 0.055, 0.97);
uniform float base_extension = 0.0;
uniform float authored_height = 1.2;

void vertex() {
	// Extend only the bottom vertices. UVs beyond 1 clamp to the solid base row,
	// preserving the original contour's world position and texel density.
	VERTEX.y -= UV.y * base_extension;
	UV.y *= (authored_height + base_extension) / authored_height;
}

void fragment() {
	float authored_alpha = texture(mask_texture, UV).a;
	ALBEDO = silhouette_color.rgb;
	ALPHA = authored_alpha * silhouette_color.a;
	if (ALPHA < 0.015) {
		discard;
	}
}
