class_name ContactShadow
extends Node2D

var actor: CharacterBody2D
var height := 0.0

func _ready() -> void:
	z_index = -1

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(actor):
		hide()
		return
	var origin := actor.global_position + Vector2(0, -2)
	var query := PhysicsRayQueryParameters2D.create(origin, origin + Vector2(0, 164), 1 | 1024)
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	visible = not hit.is_empty()
	if visible:
		height = maxf(0.0, hit.position.y - actor.global_position.y)
		global_position = (hit.position + Vector2(0, 3)).round()
		queue_redraw()

func _draw() -> void:
	var amount := clampf(height / 160.0, 0, 1)
	var half_width := roundf(lerpf(11, 4, amount))
	var tint := Color(0.04, 0.03, 0.07, lerpf(0.65, 0.12, amount))
	draw_rect(Rect2(-half_width + 2, -2, half_width * 2 - 4, 4), tint)
	draw_rect(Rect2(-half_width, -1, half_width * 2, 2), tint)
