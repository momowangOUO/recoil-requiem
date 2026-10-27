class_name NightBackdrop
extends Node3D
## Independent authored sky, moon and castle planes. One sky system per map.

var sky: Sprite3D
var moon: Sprite3D
var castle_haze: ShaderMaterial
var moon_origin_x := 8.1
var moon_camera_anchor_x := 4.8

func _ready() -> void:
	sky = layer("Sky", preload("res://assets/environments/crimson/sky_v3.png"), Vector3(4.8, -7, -28), 0.05)
	moon = layer("Moon", preload("res://assets/environments/crimson/moon_v1.png"), Vector3(8.1, -4.8, -22), 0.0021)
	castle_haze = ShaderMaterial.new()
	castle_haze.shader = preload("res://assets/environments/crimson/castle_haze.gdshader")
	castle_haze.set_shader_parameter("castle_texture", preload("res://assets/environments/crimson/castle_v3.png"))
	# Adjacent copies meet beyond the playable map, without repeating the moon.
	for index in range(-1, 5):
		layer("CastleSilhouette%d" % (index + 1), preload("res://assets/environments/crimson/castle_v3.png"), Vector3(index * 20.0 + 10, -5.1, -9), 20.0 / 1536.0)

func layer(label: String, texture: Texture2D, at: Vector3, pixel_size: float) -> Sprite3D:
	var sprite := Sprite3D.new()
	sprite.name = label
	sprite.texture = texture
	sprite.position = at
	sprite.pixel_size = pixel_size
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.alpha_scissor_threshold = 0.5
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(sprite)
	if label.begins_with("CastleSilhouette"):
		sprite.material_override = castle_haze
	return sprite

func follow_camera(camera_position: Vector3, camera: Camera3D = null) -> void:
	# Infinite sky; a very distant moon travels slowly relative to the skyline.
	sky.position.x = camera_position.x
	moon.position.x = moon_origin_x + (camera_position.x - moon_camera_anchor_x) * 0.98
	if camera == null:
		return
	# Intersect the actual tilted frustum with the sky plane. Fixed world-height
	# cards expose their edges on tall maps; following just camera Y also misses
	# the downward projection at this depth, especially with the close shotgun.
	var viewport_size := camera.get_viewport().get_visible_rect().size
	var lower := Vector2(INF, INF)
	var upper := Vector2(-INF, -INF)
	for corner in [Vector2.ZERO, Vector2(viewport_size.x, 0), Vector2(0, viewport_size.y), viewport_size]:
		var origin := camera.project_ray_origin(corner)
		var ray := camera.project_ray_normal(corner)
		var hit := origin + ray * ((sky.global_position.z - origin.z) / ray.z)
		var point := Vector2(hit.x, hit.y)
		lower = lower.min(point)
		upper = upper.max(point)
	var center := (lower + upper) * 0.5
	sky.global_position = Vector3(center.x, center.y, sky.global_position.z)
	# Uniform size retains the artwork aspect ratio;
	# a small world-space margin keeps rounding away from the visible border.
	var required := (upper - lower + Vector2.ONE) / sky.texture.get_size()
	sky.pixel_size = maxf(0.05, maxf(required.x, required.y))
