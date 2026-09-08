class_name LabReticle
extends Node2D

var player: PlayerController
var measurement := true
var last_weapon: WeaponRuntime
var last_ammo := 0
var completion_time := 0.0

func _ready() -> void:
	z_index = 1000

func _process(delta: float) -> void:
	completion_time = maxf(0.0, completion_time - delta)
	if is_instance_valid(player):
		var current := player.weapons.current()
		if current == last_weapon and current.ammo > last_ammo:
			completion_time = 0.18
		elif current != last_weapon:
			completion_time = 0.0
		last_weapon = current
		last_ammo = current.ammo
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(player):
		return
	var target := get_global_mouse_position().round()
	for direction in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
		draw_line(target + direction * 3, target + direction * 5, Color("efdfc6"), 1)
	draw_rect(Rect2(target, Vector2.ONE), Color("e16b78"))
	var progress := player.weapons.current().progress()
	if progress >= 0.0:
		ReloadFeedback.draw_ring(self, target, progress)
	elif completion_time > 0.0:
		ReloadFeedback.draw_ring(self, target, 1.0)
	if measurement:
		var origin := player.aim_origin()
		var end := origin - player.aim_direction * 18
		draw_line(origin - player.aim_direction * 8, end, Color("69c9c7"), 1)
		draw_line(end, end + player.aim_direction.rotated(0.6) * 5, Color("69c9c7"), 1)
		draw_line(end, end + player.aim_direction.rotated(-0.6) * 5, Color("69c9c7"), 1)
