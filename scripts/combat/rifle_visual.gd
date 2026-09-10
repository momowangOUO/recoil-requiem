class_name RifleVisual
extends Node2D
## Authored full-body poses with fixed shared scale, never a rotating static corpse.
const SHEETS := [preload("res://assets/characters/rifle/rifle_shoot_v1.png"), preload("res://assets/characters/rifle/rifle_death_v1.png"), preload("res://assets/characters/rifle/rifle_idle_v1.png")]
const ROOTS := [[285, 240, 285, 245], [300, 260, 300, 300], [280, 245, 280, 245]]
const BODY_SCALE := 0.09
static var regions: Array = []
var actor: RifleEnemy
var death_time := 0.0
var idle_time := 0.0
var frame := 0
var sheet := 0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var keyed := ShaderMaterial.new()
	keyed.shader = preload("res://assets/characters/requiem/chroma_key.gdshader")
	material = keyed
	if not regions.is_empty(): return
	for texture in SHEETS:
		var source: Image = texture.get_image()
		var cell := Vector2i(source.get_width() / 2, source.get_height() / 2)
		var row: Array[Rect2] = []
		for i in 4:
			var origin := Vector2i(i % 2, i / 2) * cell
			var low := cell
			var high := Vector2i.ZERO
			for y in cell.y:
				for x in cell.x:
					var c := source.get_pixelv(origin + Vector2i(x, y))
					if c.a > 0.8 and minf(c.r, c.b) - c.g < 0.18:
						low = low.min(Vector2i(x, y))
						high = high.max(Vector2i(x, y))
			row.append(Rect2(origin + low, high - low + Vector2i.ONE))
		regions.append(row)

func _physics_process(delta: float) -> void:
	material.set_shader_parameter("hit_flash", 0.0 if actor.state == ShieldEnemy.State.DEAD else clampf(actor.hit_flash / 0.06, 0, 1))
	position = Vector2.ZERO if actor.state == ShieldEnemy.State.DEAD else (actor.last_hit_direction * minf(2.0, actor.hurt_stun * 12)).snapped(Vector2(0.5, 0.5))
	if actor.hurt_stun > 0 and actor.state != ShieldEnemy.State.DEAD:
		queue_redraw()
		return
	sheet = 0
	match actor.state:
		ShieldEnemy.State.APPROACH:
			idle_time += delta
			sheet = 2
			frame = int(idle_time * 4) % 4
		ShieldEnemy.State.WINDUP: frame = 1
		ShieldEnemy.State.ATTACK: frame = 2
		ShieldEnemy.State.RECOVERY: frame = 3
		ShieldEnemy.State.DEAD:
			death_time += delta
			sheet = 1
			frame = mini(3, int(death_time / 0.18))
	queue_redraw()

func _draw() -> void:
	if regions.is_empty(): return
	var texture: Texture2D = SHEETS[sheet]
	var region: Rect2 = regions[sheet][frame]
	var cell_x := (frame % 2) * (texture.get_width() / 2)
	var destination := Rect2(Vector2((region.position.x - cell_x - ROOTS[sheet][frame]) * BODY_SCALE, -region.size.y * BODY_SCALE).round(), region.size * BODY_SCALE)
	draw_set_transform(Vector2.ZERO, 0, Vector2(-1 if cos(actor.facing_angle) < 0 else 1, 1))
	draw_texture_rect_region(texture, destination, region, Color(1.6, 1.6, 1.6) if actor.hit_flash > 0 else Color.WHITE)
	draw_set_transform(Vector2.ZERO)
