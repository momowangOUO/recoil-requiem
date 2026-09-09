class_name ShieldVisual
extends Node2D
## Generated cutout parts. Only the actor owns combat timing and hitboxes.

const ATLAS := preload("res://assets/characters/aegis/aegis_parts_v2.png")
static var cached_regions: Array[Rect2] = []
var actor: ShieldEnemy
var regions: Array[Rect2] = []
var clock := 0.0
var stride := 0.0
var death_time := 0.0
var previous_state := -1
var shield_hand := Vector2.ZERO
var front_knee := Vector2.ZERO
var rear_knee := Vector2.ZERO

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var shader_material := ShaderMaterial.new()
	shader_material.shader = preload("res://assets/characters/requiem/chroma_key.gdshader")
	material = shader_material
	if not cached_regions.is_empty():
		regions = cached_regions
		return
	var source := ATLAS.get_image()
	var cell := Vector2i(source.get_width() / 3, source.get_height() / 3)
	for i in 9:
		var origin := Vector2i(i % 3, i / 3) * cell
		var low := cell
		var high := Vector2i.ZERO
		for y in cell.y:
			for x in cell.x:
				var color := source.get_pixelv(origin + Vector2i(x, y))
				if color.a > 0.8 and minf(color.r, color.b) - color.g < 0.18:
					low = low.min(Vector2i(x, y))
					high = high.max(Vector2i(x, y))
		var bounds := Rect2i(low, high - low + Vector2i.ONE)
		regions.append(Rect2(origin + bounds.position, bounds.size))
	# Generated upper-arm tile includes a forearm: retain only shoulder-to-elbow.
	regions[2].size.y *= 0.48
	cached_regions = regions

func _physics_process(delta: float) -> void:
	if actor.state != previous_state:
		if actor.state == ShieldEnemy.State.DEAD:
			death_time = 0.0
		previous_state = actor.state
	clock += delta
	if actor.state == ShieldEnemy.State.DEAD:
		death_time += delta
	elif actor.state == ShieldEnemy.State.APPROACH and not actor.fixed_target and absf(actor.velocity.x - actor.knockback_velocity.x) > 10:
		stride += delta * absf(actor.velocity.x - actor.knockback_velocity.x) / 48.0 * 9.0
	queue_redraw()

func _part(index: int, at: Vector2, size: Vector2, angle := 0.0, tint := Color.WHITE) -> void:
	draw_set_transform(at.round(), angle)
	draw_texture_rect_region(ATLAS, Rect2(Vector2(-size.x / 2, -1), size), regions[index], tint)
	draw_set_transform(Vector2.ZERO)

func _bone(index: int, from: Vector2, to: Vector2, width: float, tint: Color) -> void:
	_part(index, from, Vector2(width, from.distance_to(to) + 2), (to - from).angle() - PI / 2, tint)

func _joint(from: Vector2, to: Vector2, length: float) -> Vector2:
	var axis := to - from
	var half := minf(axis.length() * 0.5, length)
	return (from + to) * 0.5 + Vector2(axis.y, -axis.x).normalized() * sqrt(maxf(0, length * length - half * half))

func _draw() -> void:
	if regions.size() != 9 or not is_instance_valid(actor):
		return
	# Mirror the rig as a unit, retaining all local joint relationships.
	scale.x = -1.0 if cos(actor.facing_angle) < 0 else 1.0
	var moving := actor.state == ShieldEnemy.State.APPROACH and not actor.fixed_target and absf(actor.velocity.x - actor.knockback_velocity.x) > 10
	var phase := floorf(stride * 6.0) / 6.0
	var step := sin(phase) if moving else 0.0
	var crouch := 0.0
	var lean := 0.0
	var hand := Vector2(13, -27)
	var shield_angle := 0.0
	var front_foot := Vector2(5 + step * 7, -maxf(0, cos(phase)) * 3 if moving else 0.0)
	var rear_foot := Vector2(-5 - step * 7, -maxf(0, -cos(phase)) * 3 if moving else 0.0)
	match actor.state:
		ShieldEnemy.State.WINDUP:
			var t := clampf(actor.state_time / 0.45, 0, 1)
			crouch = 4 * t
			lean = -3 * t
			hand = Vector2(11 - 5 * t, -27 + 2 * t)
			shield_angle = -0.15 * t
			front_foot.x = 7
		ShieldEnemy.State.ATTACK:
			crouch = 3
			lean = 4
			hand = Vector2(23, -29)
			front_foot.x = 12
			rear_foot.x = -9
			shield_angle = 0.12
		ShieldEnemy.State.RECOVERY:
			var t := 1.0 - clampf(actor.state_time / 0.8, 0, 1)
			crouch = 5 * t
			lean = 3 * t
			hand = Vector2(15, -27 + 12 * t)
			shield_angle = 0.35 * t
		ShieldEnemy.State.DEAD:
			var t := clampf(death_time / 0.65, 0, 1)
			crouch = 18 * t
			lean = -9 * t
			hand = Vector2(16, -27 + 25 * t)
			shield_angle = 1.2 * t
			front_foot = Vector2(12, 0)
			rear_foot = Vector2(-7, 0)
	var breath := roundf(sin(clock * 3)) if not moving and actor.state == ShieldEnemy.State.APPROACH else 0.0
	var hip := Vector2(lean, -19 + crouch)
	var shoulder := hip + Vector2(0, -13 + breath)
	var tint := Color(1.6, 1.6, 1.6) if actor.hit_flash > 0 else Color.WHITE
	if actor.state == ShieldEnemy.State.DEAD:
		tint = Color("aaa0ae")
	var rear_tint := tint * Color("b5a6bf")
	front_knee = _joint(hip + Vector2(3, 0), front_foot, 11.5)
	rear_knee = _joint(hip + Vector2(-3, 0), rear_foot, 11.5)
	_bone(4, hip + Vector2(-3, 0), rear_knee, 6, rear_tint)
	_bone(5, rear_knee, rear_foot, 7, rear_tint)
	_part(7, shoulder + Vector2(-6, -7), Vector2(8, 20), sin(clock * 4 - 0.6) * 0.10 - lean * 0.025, rear_tint)
	_bone(4, hip + Vector2(3, 0), front_knee, 6, tint)
	_bone(5, front_knee, front_foot, 7, tint)
	var rear_elbow := _joint(shoulder + Vector2(-4, 0), hip + Vector2(-3, -1), 9)
	_bone(2, shoulder + Vector2(-4, 0), rear_elbow, 6, rear_tint)
	_bone(3, rear_elbow, hip + Vector2(-3, -1), 5, rear_tint)
	_part(1, shoulder + Vector2(0, -2), Vector2(16, 20), 0, tint)
	_part(0, shoulder + Vector2(1 - actor.hit_flash * 15, -12), Vector2(14, 15), 0, tint)
	var elbow := _joint(shoulder + Vector2(4, 0), hand, 12)
	_bone(2, shoulder + Vector2(4, 0), elbow, 6, tint)
	_bone(3, elbow, hand, 5, tint)
	shield_hand = hand
	draw_set_transform(hand.round(), shield_angle)
	draw_texture_rect_region(ATLAS, Rect2(-5, -13, 14, 30), regions[6], tint)
	draw_set_transform(Vector2.ZERO)
