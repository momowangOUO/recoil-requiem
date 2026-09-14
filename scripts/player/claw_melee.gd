class_name ClawMelee
extends RefCounted

## One attack per press. Its bounded displacement never becomes stored velocity.
const WINDUP := 0.08
const HIT_TIME := 0.08
const RECOVERY := 0.22
const COOLDOWN := 0.65
const LUNGE := 22.0
const DAMAGE := 35.0
const IMPULSE := 260.0
var cooldown := 0.0
var elapsed := -1.0
var direction := 1.0
var air_lunge_used := false
var assisted := false
var origin := Vector2.ZERO
var struck: Dictionary = {}

func active() -> bool: return elapsed >= 0.0

func start(actor: CharacterBody2D) -> bool:
	if active() or cooldown > 0.000001 or actor.health <= 0 or actor.hurt_stun > 0:
		return false
	elapsed = 0
	cooldown = COOLDOWN
	direction = actor.facing
	origin = actor.global_position + Vector2(0, -24)
	assisted = actor.is_on_floor() or not air_lunge_used
	if not actor.is_on_floor() and assisted: air_lunge_used = true
	struck.clear()
	actor.flash_time = 0
	return true

func cancel() -> void:
	elapsed = -1
	assisted = false
	struck.clear()

func reset() -> void:
	cancel()
	cooldown = 0
	air_lunge_used = false

func tick_cooldown(delta: float, grounded: bool) -> void:
	cooldown = maxf(0, cooldown - delta)
	if grounded: air_lunge_used = false

func advance(actor: CharacterBody2D, delta: float, movement_start: Vector2) -> void:
	if not active(): return
	var previous := elapsed
	elapsed += delta
	var hit_delta := maxf(0, minf(elapsed, WINDUP + HIT_TIME) - maxf(previous, WINDUP))
	if hit_delta > 0:
		# The player's normal move_and_slide has already resolved recoil and gravity.
		# Apply only this attack's small, collision-tested addition to its position.
		if assisted:
			if not actor.is_on_floor(): air_lunge_used = true
			actor.move_and_collide(Vector2(direction * LUNGE * hit_delta / HIT_TIME, 0))
		var finish: Vector2 = actor.global_position
		var subdivisions := maxi(1, ceili(movement_start.distance_to(finish) / 4.0))
		for i in range(subdivisions + 1):
			_hit_at(actor, movement_start.lerp(finish, float(i) / subdivisions))
	if elapsed + 0.000001 >= WINDUP + HIT_TIME + RECOVERY: cancel()

func _hit_at(actor: CharacterBody2D, at: Vector2) -> void:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(24, 26)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0, at + Vector2(direction * 12, -24))
	query.collision_mask = 64
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var space := actor.get_world_2d().direct_space_state
	var candidates: Dictionary = {}
	for hit in space.intersect_shape(query, 64):
		var area: Area2D = hit.collider
		if not area.has_meta("receiver"): continue
		var receiver: Node2D = area.get_meta("receiver")
		var id := receiver.get_instance_id()
		if struck.has(id): continue
		var point := area.global_position
		var obstruction := PhysicsRayQueryParameters2D.create(at + Vector2(0, -24), point, 1)
		obstruction.hit_from_inside = true
		if not space.intersect_ray(obstruction).is_empty(): continue
		var weak := bool(area.get_meta("weakpoint", false))
		if not candidates.has(id) or weak:
			candidates[id] = {"receiver": receiver, "point": point, "weak": weak}
	for id in candidates:
		var hit: Dictionary = candidates[id]
		struck[id] = true
		var shot := ShotContext.new()
		shot.source_position = origin
		shot.direction = Vector2(direction, 0)
		shot.damage = DAMAGE
		shot.knockback = IMPULSE
		hit.receiver.receive_hit(shot, hit.point, hit.weak)
