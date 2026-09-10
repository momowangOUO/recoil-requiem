shader_type canvas_item;
render_mode unshaded;
uniform float hit_flash : hint_range(0.0, 1.0) = 0.0;

// Only the generated idle source needs keying. The RGBA run atlas passes through.
// The source image remains unchanged; transparency is resolved during rendering.
void fragment() {
	vec4 sampled = texture(TEXTURE, UV);
	float magenta = min(sampled.r, sampled.b) - sampled.g;
	COLOR.a *= 1.0 - smoothstep(0.18, 0.36, magenta);
	COLOR.rgb = mix(COLOR.rgb, vec3(1.0, 0.94, 0.85), hit_flash);
}
