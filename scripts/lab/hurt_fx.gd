class_name HurtFX
extends Node2D
## Brief directional pixel shards. Their lifetime follows the paused game world.
var direction := Vector2.RIGHT
var shield := false
var age := 0.0
const LIFETIME := 0.28

func _physics_process(delta: float) -> void:
	age += delta
	if age >= LIFETIME: queue_free()
	queue_redraw()

func _draw() -> void:
	var color := Color("f2c776") if shield else Color("c93352")
	color.a = clampf(1.0 - age / LIFETIME, 0, 1)
	for i in 7:
		var ray := direction.rotated((i - 3) * 0.31)
		var travel := ray * age * (65 + i * 9) + Vector2(0, age * age * 90)
		draw_rect(Rect2(travel.round(), Vector2(2 if i % 2 == 0 else 1, 2)), color)
	if age < 0.065:
		draw_line(Vector2(-5, -5), Vector2(5, 5), Color("fff4d7"), 2)
		draw_line(Vector2(-5, 5), Vector2(5, -5), Color("fff4d7"), 2)
