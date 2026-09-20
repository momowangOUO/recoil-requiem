@tool
extends Node3D
## A painted near-plane panorama. It follows the camera's frustum, while a
## small horizontal drift keeps the closest stonework moving against the stage.

const PLANE_Z := 2.35
const WIDTH_MARGIN := 1.55
const BOTTOM_OVERSCAN := 0.08
const TEXTURE := preload("res://assets/environments/crimson/foreground_panorama_v3.png")

var card: Sprite3D

func _ready() -> void:
	card = Sprite3D.new()
	card.name = "PaintedNearWall"
	card.texture = TEXTURE
	card.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	card.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	card.shaded = false
	card.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	card.modulate = Color(0.82, 0.83, 0.90, 1.0)
	add_child(card)

func follow_camera(view_camera: Camera3D) -> void:
	if card == null or view_camera == null:
		return
	var viewport_size := view_camera.get_viewport().get_visible_rect().size
	var left_top := _on_plane(view_camera, Vector2.ZERO)
	var right_top := _on_plane(view_camera, Vector2(viewport_size.x, 0))
	var left_bottom := _on_plane(view_camera, Vector2(0, viewport_size.y))
	var right_bottom := _on_plane(view_camera, viewport_size)
	var left := minf(left_top.x, left_bottom.x)
	var right := maxf(right_top.x, right_bottom.x)
	var top := maxf(left_top.y, right_top.y)
	var bottom := minf(left_bottom.y, right_bottom.y)
	var view_width := right - left
	var view_height := top - bottom
	var card_width := view_width * WIDTH_MARGIN
	card.pixel_size = card_width / float(TEXTURE.get_width())
	var card_height := card.pixel_size * TEXTURE.get_height()
	# The continuous masonry starts below the image. Only its irregular upper
	# contour occupies the lower quarter of the playable view.
	# Keep the tall authored finials out of the actor's central landing lane.
	var drift := -view_width * 0.10 + sin(view_camera.global_position.x * 0.12) * view_width * 0.035
	card.global_position = Vector3((left + right) * 0.5 + drift,
		bottom - view_height * BOTTOM_OVERSCAN + card_height * 0.5, PLANE_Z)

func _on_plane(view_camera: Camera3D, screen: Vector2) -> Vector3:
	var origin := view_camera.project_ray_origin(screen)
	var direction := view_camera.project_ray_normal(screen)
	return origin + direction * ((PLANE_Z - origin.z) / direction.z)
