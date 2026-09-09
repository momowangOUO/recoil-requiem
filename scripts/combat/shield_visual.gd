class_name ShieldVisual
extends Node2D
## Whole authored poses preserve anatomy; no procedural limb stretching.

const SHEETS := {
	"walk": preload("res://assets/characters/aegis/aegis_walk_v3.png"),
	"bash": preload("res://assets/characters/aegis/aegis_bash_v3.png"),
	"death": preload("res://assets/characters/aegis/aegis_death_v3.png")
}
const BODY_SCALE := 0.09
## Pelvis anchors in source-cell pixels, not per-pose scale corrections.
const ROOTS := {"walk": [326, 273, 331, 281], "bash": [326, 253, 335, 281], "death": [320, 243, 310, 248]}
static var cached_regions: Dictionary = {}
var actor: ShieldEnemy
var stride := 0.0
var death_time := 0.0
var previous_state := -1
var animation := "bash"
var frame := 0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var keyed := ShaderMaterial.new()
	keyed.shader = preload("res://assets/characters/requiem/chroma_key.gdshader")
	material = keyed
	if not cached_regions.is_empty():
		return
	for action in SHEETS:
		var source: Image = SHEETS[action].get_image()
		var cell := Vector2i(source.get_width() / 2, source.get_height() / 2)
		var regions: Array[Rect2] = []
		for i in 4:
			var origin := Vector2i(i % 2, i / 2) * cell
			var low := cell
			var high := Vector2i.ZERO
			for y in cell.y:
				for x in cell.x:
					var color := source.get_pixelv(origin + Vector2i(x, y))
					if color.a > 0.8 and minf(color.r, color.b) - color.g < 0.18:
						low = low.min(Vector2i(x, y))
						high = high.max(Vector2i(x, y))
			regions.append(Rect2(origin + low, high - low + Vector2i.ONE))
		cached_regions[action] = regions

func _physics_process(delta: float) -> void:
	if actor.state != previous_state:
		if actor.state == ShieldEnemy.State.DEAD:
			death_time = 0.0
		previous_state = actor.state
	var walking_speed := absf(actor.velocity.x - actor.knockback_velocity.x)
	animation = "bash"
	frame = 0
	match actor.state:
		ShieldEnemy.State.APPROACH:
			if not actor.fixed_target and walking_speed > 10:
				stride += delta * walking_speed / 48.0 * 8.0
				animation = "walk"
				frame = int(stride) % 4
		ShieldEnemy.State.WINDUP:
			frame = 1
		ShieldEnemy.State.ATTACK:
			frame = 2
		ShieldEnemy.State.RECOVERY:
			frame = 3 if actor.state_time < 0.65 else 0
		ShieldEnemy.State.DEAD:
			death_time += delta
			animation = "death"
			frame = mini(3, int(death_time / 0.18))
	queue_redraw()

func _draw() -> void:
	if cached_regions.is_empty() or not is_instance_valid(actor):
		return
	var texture: Texture2D = SHEETS[animation]
	var region: Rect2 = cached_regions[animation][frame]
	var cell_x := (frame % 2) * (texture.get_width() / 2)
	var destination := Rect2(Vector2((region.position.x - cell_x - ROOTS[animation][frame]) * BODY_SCALE, -region.size.y * BODY_SCALE).round(), region.size * BODY_SCALE)
	var facing := -1.0 if cos(actor.facing_angle) < 0 else 1.0
	draw_set_transform(Vector2.ZERO, 0, Vector2(facing, 1))
	draw_texture_rect_region(texture, destination, region, Color(1.6, 1.6, 1.6) if actor.hit_flash > 0 and actor.state != ShieldEnemy.State.DEAD else Color.WHITE)
	draw_set_transform(Vector2.ZERO)
