shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

uniform sampler2D castle_texture : source_color, filter_nearest, repeat_disable;

void fragment() {
	vec4 ink = texture(castle_texture, UV);
	ALBEDO = ink.rgb;
	// The finite terrain painting dissolves into the independent sky below it.
	// Only its lowest quarter blends; towers keep their authored pixel edges.
	ALPHA = ink.a * (1.0 - smoothstep(0.75, 1.0, UV.y));
}
