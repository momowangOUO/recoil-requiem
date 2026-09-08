class_name LabProjectile
extends Node2D
## Swept collision owns damage dispatch: one receiver call per pellet, never Area callbacks.

signal impact(point: Vector2, color: Color)
var shot: ShotContext
var age: float = 0.0
var finished := false
var previous_position := Vector2.ZERO
var muzzle_checked := false

func _ready() -> void:
	position = shot.muzzle_position
	previous_position = position

func _physics_process(delta: float) -> void:
	step(delta)

func _ray(from: Vector2, to: Vector2, mask: int = 1 | 64) -> Dictionary:
	var query := PhysicsRayQueryParameters2D.create(from, to, mask)
	query.collide_with_areas = true
	query.hit_from_inside = true
	return get_world_2d().direct_space_state.intersect_ray(query)

func step(delta: float) -> void:
	if finished:
		return
	age += delta
	if age > shot.lifetime:
		_finish()
		return
	if not muzzle_checked:
		muzzle_checked = true
		var obstruction := _ray(shot.source_position, shot.muzzle_position)
		if not obstruction.is_empty():
			_resolve(obstruction, shot.source_position, shot.muzzle_position)
			return
	previous_position = global_position
	var next := global_position + shot.direction * shot.speed * delta
	var hit := _ray(global_position, next)
	if not hit.is_empty():
		_resolve(hit, global_position, next)
		return
	global_position = next
	queue_redraw()

func _resolve(hit: Dictionary, from: Vector2, to: Vector2) -> void:
	var collider: Object = hit.collider
	if collider.has_meta("receiver"):
		var receiver: ShieldEnemy = collider.get_meta("receiver")
		var weak := bool(collider.get_meta("weakpoint", false))
		# Body and exposed weakpoint can overlap. Prefer this same actor's weakpoint
		# along the current segment, without penetrating a nearer world obstruction.
		if not weak and receiver.weakpoint_open():
			var query := PhysicsRayQueryParameters2D.create(from, to, 1 | 64)
			query.collide_with_areas = true
			query.hit_from_inside = true
			query.exclude = [receiver.hurtbox.get_rid()]
			var other := get_world_2d().direct_space_state.intersect_ray(query)
			if not other.is_empty() and other.collider == receiver.weakpoint:
				weak = true
				hit = other
		receiver.receive_hit(shot, hit.position, weak)
	impact.emit(hit.position, shot.color)
	_finish()

func _finish() -> void:
	finished = true
	queue_free()

func _draw() -> void:
	draw_line(-shot.direction * 7, Vector2.ZERO, shot.color, 1)
	draw_rect(Rect2(-1, -1, 2, 2), Color("fff6d8"))
