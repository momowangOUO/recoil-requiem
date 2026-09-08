class_name ImpactFX
extends Node2D

var tint := Color.WHITE
var time: float = 0.0

func _process(delta: float) -> void:
	time += delta
	if time > 0.18:
		queue_free()
	queue_redraw()

func _draw() -> void:
	for index in 6:
		var direction := Vector2.from_angle(index * TAU / 6.0)
		draw_line(direction * time * 32, direction * (3 + time * 62), Color(tint, 1 - time / 0.18), 1)
