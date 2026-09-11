class_name PlayerVisual
extends Node2D
## Generated body atlas plus an articulated, pixel-snapped aiming rig.

const IDLE := preload("res://assets/characters/requiem/requiem_idle_v5_socket.png")
const RUN := preload("res://assets/characters/requiem/requiem_run_v5_socket.png")
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
	var palm_front := preload("res://scripts/player/support_palm_front.gd").new()
	palm_front.name = "FarPalmOccluded"
	palm_front.rig = self
	add_child(palm_front)

func update_pose(delta: float) -> void:
	material.set_shader_parameter("hit_flash", clampf(actor.hit_flash / 0.06, 0, 1))
	position = (actor.last_hit_direction * minf(2.0, actor.hurt_stun * 12)).snapped(Vector2(0.5, 0.5))
	if actor.hurt_stun > 0:
		queue_redraw()
		return
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

const FIRING_ARMS := [preload("res://assets/characters/requiem/revolver_right_trigger_v3.png"), preload("res://assets/characters/requiem/shotgun_right_trigger_v3.png"), preload("res://assets/characters/requiem/smg_right_trigger_v3.png")]
const SUPPORT_ARMS := [preload("res://assets/characters/requiem/revolver_left_support_v3.png"), preload("res://assets/characters/requiem/shotgun_left_support_v3.png"), preload("res://assets/characters/requiem/smg_left_support_v5.png")]
const MUZZLES := [Vector2(768, 142), Vector2(782, 75), Vector2(755, 79)]
const SUPPORT_ROOTS := [Vector2(165, 150), Vector2(165, 75), Vector2(165, 86)]
const ARM_SCALE := 0.05
const RIGHT_SHOULDERS := [Vector2(250, 145), Vector2(250, 70), Vector2(250, 85)]
const RIGHT_ELBOWS := [Vector2(270, 245), Vector2(270, 175), Vector2(270, 186)]
const RIGHT_WRISTS := [Vector2(380, 220), Vector2(380, 150), Vector2(388, 170)]
const RIGHT_UPPER := [Rect2(180, 75, 132, 210), Rect2(180, 15, 132, 190), Rect2(180, 25, 132, 200)]
const RIGHT_FORE := [Rect2(255, 194, 125, 88), Rect2(250, 117, 130, 85), Rect2(250, 134, 138, 90)]
const RIGHT_GRIP := [Rect2(375, 0, 475, 385), Rect2(375, 0, 475, 285), Rect2(380, 0, 470, 354)]
const LEFT_SHOULDERS := [Vector2.ZERO, Vector2(165, 60), Vector2(254.25, 112.5)]
const LEFT_ELBOWS := [Vector2.ZERO, Vector2(195, 175), Vector2(299.25, 240.75)]
const LEFT_WRISTS := [Vector2.ZERO, Vector2(300, 150), Vector2(434.25, 240.75)]
const LEFT_PALMS := [Vector2.ZERO, Vector2(345, 137), Vector2(486, 240.75)]
const LEFT_UPPER := [Rect2(), Rect2(110, 15, 115, 200), Rect2(180, 60.75, 150.75, 220.5)]
const LEFT_FORE := [Rect2(), Rect2(178, 120, 124, 90), Rect2(281.25, 193.5, 156.15, 90)]
const LEFT_HAND := [Rect2(), Rect2(300, 95, 110, 100), Rect2(431.1, 191.25, 110.7, 101.25)]

func _oriented(point: Vector2, angle: float) -> Vector2:
	return Vector2(point.x, point.y * actor.facing).rotated(angle)

func _elbow(shoulder: Vector2, wrist: Vector2, upper: float, lower: float) -> Vector2:
	var axis := wrist - shoulder
	var distance := maxf(0.001, axis.length())
	axis /= distance
	var along := clampf((upper * upper - lower * lower + distance * distance) / (2 * distance), -upper, upper)
	# Keep the same anatomical branch throughout the aim sweep. Choosing by
	# screen-space bend.y flips the elbow abruptly when the wrist passes below it.
	var bend := axis.rotated(PI * 0.5) * actor.facing
	return shoulder + axis * along + bend * sqrt(maxf(0, upper * upper - along * along))

func _bone(texture: Texture2D, region: Rect2, source_start: Vector2, source_end: Vector2, start: Vector2, end: Vector2, tint := Color.WHITE) -> void:
	# Rotate source pixels around authored joint anchors; never stretch a limb.
	var angle := (end - start).angle() - (source_end - source_start).angle() * actor.facing
	draw_set_transform(start, angle, Vector2(ARM_SCALE, ARM_SCALE * actor.facing))
	draw_texture_rect_region(texture, Rect2(region.position - source_start, region.size), region, tint)
	draw_set_transform(Vector2.ZERO)

func right_wrist(index: int, forward: Vector2) -> Vector2:
	return Vector2(0, -26) + _oriented(Vector2(25, 0) + (RIGHT_WRISTS[index] - MUZZLES[index]) * ARM_SCALE, forward.angle())

func _right_arm(index: int, forward: Vector2) -> void:
	var shoulder := Vector2(-3 * actor.facing, -26)
	var wrist := right_wrist(index, forward)
	var upper: float = RIGHT_SHOULDERS[index].distance_to(RIGHT_ELBOWS[index]) * ARM_SCALE
	var lower: float = RIGHT_ELBOWS[index].distance_to(RIGHT_WRISTS[index]) * ARM_SCALE
	var elbow := _elbow(shoulder, wrist, upper, lower)
	_bone(FIRING_ARMS[index], RIGHT_UPPER[index], RIGHT_SHOULDERS[index], RIGHT_ELBOWS[index], shoulder, elbow)
	_bone(FIRING_ARMS[index], RIGHT_FORE[index], RIGHT_ELBOWS[index], RIGHT_WRISTS[index], elbow, wrist)

func left_pose(index: int, forward: Vector2, progress: float) -> Dictionary:
	var travel := sin(progress * PI) if progress >= 0 else 0.0
	var angle := lerp_angle(forward.angle(), PI / 2, travel)
	# SMG support palm registers to the left edge of its magazine (source x=539),
	# not the trigger/receiver. The authored fingers extend over the magazine.
	var palm := Vector2(0, -26) + _oriented(Vector2(12.5, 3) if index == 1 else Vector2(14.2, 3.5), forward.angle())
	palm = palm.lerp(Vector2(3 * actor.facing, -15), travel)
	var wrist := palm - _oriented((LEFT_PALMS[index] - LEFT_WRISTS[index]) * ARM_SCALE, angle)
	return {"palm": palm, "wrist": wrist, "angle": angle}

func _support_arm(index: int, forward: Vector2, progress: float, hand_only := false) -> void:
	if index == 0:
		if hand_only: return
		var reach := sin(progress * PI) if progress >= 0 else 0.0
		draw_set_transform(Vector2(actor.facing, -26), -reach * 0.95 * actor.facing, Vector2(ARM_SCALE * actor.facing, ARM_SCALE))
		draw_texture(SUPPORT_ARMS[0], -SUPPORT_ROOTS[0], Color(0.85, 0.85, 0.85))
		draw_set_transform(Vector2.ZERO)
		return
	var fitted := left_pose(index, forward, progress)
	if hand_only:
		draw_set_transform(fitted.palm, fitted.angle, Vector2(ARM_SCALE, ARM_SCALE * actor.facing))
		var region: Rect2 = LEFT_HAND[index]
		draw_texture_rect_region(SUPPORT_ARMS[index], Rect2(region.position - LEFT_PALMS[index], region.size), region)
		draw_set_transform(Vector2.ZERO)
		return
	var shoulder := Vector2(actor.facing, -26)
	var upper: float = LEFT_SHOULDERS[index].distance_to(LEFT_ELBOWS[index]) * ARM_SCALE
	var lower: float = LEFT_ELBOWS[index].distance_to(LEFT_WRISTS[index]) * ARM_SCALE
	var elbow := _elbow(shoulder, fitted.wrist, upper, lower)
	_bone(SUPPORT_ARMS[index], LEFT_UPPER[index], LEFT_SHOULDERS[index], LEFT_ELBOWS[index], shoulder, elbow, Color(0.85, 0.85, 0.85))
	_bone(SUPPORT_ARMS[index], LEFT_FORE[index], LEFT_ELBOWS[index], LEFT_WRISTS[index], elbow, fitted.wrist, Color(0.85, 0.85, 0.85))

func body_layout() -> Dictionary:
	var atlas := IDLE if pose == "idle" else RUN
	var cell := Vector2(atlas.get_width() * 0.5, atlas.get_height() * 0.5)
	var feet: float = IDLE_FEET[frame] if pose == "idle" else RUN_FEET[frame]
	var root_x: float = IDLE_ROOTS[frame] if pose == "idle" else RUN_ROOTS[frame]
	var region := Rect2(Vector2((frame % 2) * cell.x, (frame / 2) * cell.y), cell)
	var dest := Rect2(Vector2(-root_x * BODY_SCALE, -feet * BODY_SCALE).round(), cell * BODY_SCALE)
	return {"atlas":atlas,"region":region,"dest":dest}

func _draw() -> void:
	if not is_instance_valid(actor): return
	var weapon := actor.weapons.current()
	var forward := actor.aim_direction
	var origin := Vector2(0, -26)
	var index := 1 if weapon.data.id == &"shotgun" else (2 if weapon.data.id == &"smg" else 0)
	_support_arm(index, forward, weapon.progress())
	_support_arm(index, forward, weapon.progress(), true)
	var body := body_layout()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(actor.facing, 1))
	var tint := Color(1.7, 1.7, 1.7) if actor.invulnerability > 0 and int(actor.invulnerability * 30) % 2 == 0 else Color.WHITE
	draw_texture_rect_region(body.atlas, body.dest, body.region, tint)
	draw_set_transform(Vector2.ZERO)
	_right_arm(index, forward)
	# Only the grip/hand and weapon rotate together. Shoulders stay on the torso.
	var region_grip: Rect2 = RIGHT_GRIP[index]
	var offset: Vector2 = Vector2(25, 0) + (region_grip.position - MUZZLES[index]) * ARM_SCALE
	draw_set_transform(origin, forward.angle(), Vector2(1, actor.facing))
	draw_texture_rect_region(FIRING_ARMS[index], Rect2(offset, region_grip.size * ARM_SCALE), region_grip)
	draw_set_transform(Vector2.ZERO)
	if actor.flash_time > 0:
		var muzzle := origin + forward * 25
		draw_line(muzzle.round(), (muzzle + forward * 7).round(), Color("edc875"), 3, false)
		draw_line(muzzle.round(), (muzzle + forward * 11).round(), Color("fff2be"), 1, false)
