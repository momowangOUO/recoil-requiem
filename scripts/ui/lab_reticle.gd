class_name LabReticle
extends Node2D
const ART := preload("res://assets/ui/gothic_reticle_v1.png")

var player: PlayerController
var measurement := true
var last_weapon: WeaponRuntime
var last_ammo := 0
var completion_time := 0.0
var screen_position_source: Callable

func _ready() -> void:
	z_index = 1000
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var keyed := ShaderMaterial.new()
	keyed.shader = preload("res://assets/characters/requiem/chroma_key.gdshader")
	material = keyed

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
	# CanvasLayer makes cursor placement independent of camera follow and shake.
	var target: Vector2 = screen_position_source.call() if screen_position_source.is_valid() else get_viewport().get_mouse_position()
	target = target.round()
	# The authored sight has an empty center registered to the exact aim point.
	# It renders on the native UI canvas; the pixel-world sampler is not involved.
	draw_texture_rect(ART, Rect2(target - Vector2(12, 12), Vector2(24, 24)), false)
	var progress := player.weapons.current().progress()
	if progress >= 0.0:
		ReloadFeedback.draw_ring(self, target, progress)
	elif completion_time > 0.0:
		ReloadFeedback.draw_ring(self, target, 1.0)
