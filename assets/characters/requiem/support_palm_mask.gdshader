shader_type canvas_item;
render_mode unshaded;
uniform sampler2D body_atlas : filter_nearest, repeat_disable;
uniform sampler2D near_atlas : filter_nearest, repeat_disable;
uniform vec4 body_source;
uniform vec4 body_destination;
uniform float facing = 1.0;
uniform float aim_angle = 0.0;
uniform vec2 muzzle;
uniform float hit_flash = 0.0;
varying vec2 actor_point;
void vertex() { actor_point = VERTEX; }
float coverage(vec4 pixel) {
	return pixel.a * (1.0-smoothstep(0.18,0.36,min(pixel.r,pixel.b)-pixel.g));
}
void fragment() {
	vec2 body_uv = (vec2(actor_point.x*facing,actor_point.y)-body_destination.xy)/body_destination.zw;
	float blocked = 0.0;
	if (all(greaterThanEqual(body_uv,vec2(0.0))) && all(lessThan(body_uv,vec2(1.0)))) {
		vec2 atlas_uv = (body_source.xy+body_uv*body_source.zw)/vec2(textureSize(body_atlas,0));
		blocked = coverage(texture(body_atlas,atlas_uv));
	}
	vec2 relative = actor_point-vec2(0.0,-26.0);
	float c = cos(aim_angle);
	float s = sin(aim_angle);
	vec2 gun_point = vec2(c*relative.x+s*relative.y,(-s*relative.x+c*relative.y)*facing);
	vec2 source_point = (gun_point-vec2(25.0,0.0))/0.05+muzzle;
	// Mask the near trigger hand, while allowing the palm to cover the magazine.
	if (source_point.x >= 375.0 && source_point.x < 520.0 && source_point.y >= 0.0 && source_point.y < float(textureSize(near_atlas,0).y)) {
		blocked = max(blocked,coverage(texture(near_atlas,source_point/vec2(textureSize(near_atlas,0)))));
	}
	vec4 pixel = texture(TEXTURE,UV);
	COLOR.a *= (1.0-blocked)*(1.0-smoothstep(0.18,0.36,min(pixel.r,pixel.b)-pixel.g));
	COLOR.rgb = mix(COLOR.rgb,vec3(1.0,0.94,0.85),hit_flash);
}
