class_name PlayerVisual
extends Node2D
## Generated body atlas plus an articulated, pixel-snapped aiming rig.

const IDLE := preload("res://assets/characters/requiem/requiem_idle_v3_red.png")
const RUN := preload("res://assets/characters/requiem/requiem_run_v3_red.png")
const BODY_SCALE := 0.084
const IDLE_ROOTS := [346.0, 311.5, 346.0, 311.0]
const RUN_ROOTS := [369.5, 351.0, 369.5, 344.5]
const RUN_FEET := [583.0, 586.0, 564.0, 563.0]
const IDLE_FEET := [589.0, 589.0, 567.0, 567.0]
var actor: PlayerController
var animation_time := 0.0
var pose := "idle"
var frame := 0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var key_material := ShaderMaterial.new()
	key_material.shader = preload("res://assets/characters/requiem/chroma_key.gdshader")
	material = key_material

func update_pose(delta: float) -> void:
	var next_pose := "idle"
	if not actor.is_on_floor():
		next_pose = "rise" if actor.velocity.y < -30 else "fall"
	elif absf(actor.move_intent_x) > 0.1 and actor.move_intent_x * actor.velocity.x > 20:
		next_pose = "run"
	if next_pose != pose:
		animation_time = 0.0
		pose = next_pose
	# Advance feet by actual travel speed, including reverse playback when backing up.
	var pace := clampf(absf(actor.velocity.x) / actor.tuning.walk_max_speed, 0.0, 1.8) if pose == "run" else 1.0
	var playback_direction := signf(actor.velocity.x * actor.facing) if pose == "run" else 1.0
	animation_time += delta * pace * playback_direction
	if pose == "rise":
		frame = 1
	elif pose == "fall":
		frame = 3
	else:
		frame = posmod(int(floor(animation_time * (10.0 if pose == "run" else 5.0))), 4)
	queue_redraw()

func _arm(shoulder: Vector2, hand: Vector2, rear: bool) -> void:
	# Fixed upper/forearm lengths give a real elbow instead of a rubber midpoint.
	var axis := hand - shoulder
	var distance := maxf(0.1, axis.length())
	axis /= distance
	var upper := 8.5
	var lower := 10.5
	var along := clampf((upper * upper - lower * lower + distance * distance) / (2 * distance), -upper, upper)
	var bend := axis.orthogonal()
	if bend.y < 0 or (absf(bend.y) < 0.01 and bend.x * actor.facing < 0): bend = -bend
	var elbow := shoulder + axis * along + bend * sqrt(maxf(0, upper * upper - along * along))
	var grid := Vector2(0.5, 0.5)
	shoulder = shoulder.snapped(grid)
	elbow = elbow.snapped(grid)
	hand = hand.snapped(grid)
	var sleeve := Color("542638") if rear else Color("963d52")
	draw_line(shoulder, elbow, Color("151722"), 3.5, false)
	draw_line(elbow, hand, Color("151722"), 3, false)
	draw_line(shoulder, elbow, sleeve, 2, false)
	draw_line(elbow, hand, Color("454658"), 1.5, false)
	draw_line(shoulder + Vector2(0.5, 0), elbow + Vector2(0.5, 0), Color("b35b68") if not rear else Color("754052"), 0.5, false)

func _hand(at: Vector2, angle: float, support: bool) -> void:
	# Gloves and exposed fingertips rotate with the grip, including vertical aim.
	draw_set_transform(at.snapped(Vector2(0.5, 0.5)), angle, Vector2(1, actor.facing))
	draw_rect(Rect2(-2, -1.5, 3.5, 3), Color("151722"))
	draw_rect(Rect2(-1.5, -1, 2.5, 2), Color("454658"))
	draw_rect(Rect2(0, -1.5, 1.5, 1), Color("bc8d81") if support else Color("e4baa0"))
	draw_rect(Rect2(1, -0.5, 0.5, 1.5), Color("bc8d81"))
	draw_set_transform(Vector2.ZERO)

func _draw() -> void:
	if not is_instance_valid(actor):
		return
	var weapon := actor.weapons.current()
	var forward := actor.aim_direction
	var down := forward.orthogonal() * -actor.facing
	var origin := Vector2(0, -26)
	var grip := origin + forward * 10 + down * 4.5
	# Pistol: support hand cups the firing hand. Long guns: under the fore-end.
	var support := origin + forward * (9 if weapon.data.id == &"revolver" else 14) + down * (6 if weapon.data.id == &"revolver" else 3)
	var progress := weapon.progress()
	if progress >= 0:
		# Each shell uses its real reload progress; the hand visits the belt then chamber.
		var travel := sin(progress * PI)
		support = support.lerp(Vector2(3 * actor.facing, -15), travel)
	_arm(Vector2(-3 * actor.facing, -27), support - forward, true)
	var atlas := IDLE if pose == "idle" else RUN
	var cell := Vector2(atlas.get_width() * 0.5, atlas.get_height() * 0.5)
	var feet: float = IDLE_FEET[frame] if pose == "idle" else RUN_FEET[frame]
	var root_x: float = IDLE_ROOTS[frame] if pose == "idle" else RUN_ROOTS[frame]
	var region := Rect2(Vector2((frame % 2) * cell.x, (frame / 2) * cell.y), cell)
	var dest := Rect2(Vector2(-root_x * BODY_SCALE, -feet * BODY_SCALE).round(), cell * BODY_SCALE)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(actor.facing, 1))
	var tint := Color(1.7, 1.7, 1.7) if actor.invulnerability > 0 and int(actor.invulnerability * 30) % 2 == 0 else Color.WHITE
	draw_texture_rect_region(atlas, dest, region, tint)
	draw_set_transform(Vector2.ZERO)
	_arm(Vector2(-2 * actor.facing, -27), grip - forward, false)
	_hand(support, forward.angle(), true)
	# All three silhouettes terminate at the shared, real 25px muzzle anchor.
	draw_set_transform(origin, forward.angle(), Vector2(1, actor.facing))
	var ink := Color("151722")
	var silver := Color("cac6c2")
	draw_rect(Rect2(8, 1, 5, 7), ink)
	match weapon.data.id:
		&"shotgun":
			draw_rect(Rect2(3, -2, 22, 5), ink)
			draw_rect(Rect2(8, -2, 17, 2), silver)
			draw_rect(Rect2(14, 2, 7, 3), Color("963d52"))
			draw_rect(Rect2(3, 0, 6, 4), Color("542638"))
		&"smg":
			draw_rect(Rect2(6, -3, 15, 6), ink)
			draw_rect(Rect2(9, -3, 12, 2), Color("848594"))
			draw_rect(Rect2(20, -1, 5, 2), silver)
			draw_rect(Rect2(16, 3, 3, 6), Color("454658"))
		_:
			draw_rect(Rect2(8, -3, 9, 6), ink)
			draw_rect(Rect2(15, -2, 10, 3), silver)
			draw_rect(Rect2(10, -2, 5, 4), Color("848594"))
	draw_set_transform(Vector2.ZERO)
	_hand(grip, forward.angle(), false)
	if actor.flash_time > 0:
		var muzzle := origin + forward * 25
		draw_line(muzzle.round(), (muzzle + forward * 7).round(), Color("edc875"), 3, false)
		draw_line(muzzle.round(), (muzzle + forward * 11).round(), Color("fff2be"), 1, false)
