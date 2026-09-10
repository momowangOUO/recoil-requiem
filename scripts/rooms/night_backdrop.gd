class_name NightBackdrop
extends Node3D
## Independent authored sky, moon and castle planes. One sky system per map.

var sky: Sprite3D
var moon: Sprite3D

func _ready() -> void:
	sky = layer("Sky", preload("res://assets/environments/crimson/sky_v3.png"), Vector3(4.8, -7, -28), 0.05)
	moon = layer("Moon", preload("res://assets/environments/crimson/moon_v1.png"), Vector3(8.1, -4.8, -22), 0.0021)
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
	return sprite

func follow_camera(camera_position: Vector3) -> void:
	# Infinite sky; a very distant moon travels slowly relative to the skyline.
	sky.position.x = camera_position.x
	moon.position.x = 8.1 + (camera_position.x - 4.8) * 0.98
