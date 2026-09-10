class_name RifleEnemy
extends ShieldEnemy
## Stationary sentry: tracking, locked aim, one shot, long reload.
var locked_direction := Vector2.LEFT
var attack_count := 0
var shot_line := 0.0

func _ready() -> void:
	super._ready()
	health = 72
	mass = 1.0
	visual.hide()
	visual.set_physics_process(false)
	var artwork := RifleVisual.new()
	artwork.name = "RifleArtwork"
	artwork.actor = self
	add_child(artwork)

func weakpoint_open() -> bool:
	return false

func muzzle() -> Vector2:
	return global_position + Vector2(signf(cos(facing_angle)) * 32, -30)

func _physics_process(delta: float) -> void:
	if state == State.DEAD: return
	hit_flash = maxf(0, hit_flash - delta)
	shot_line = maxf(0, shot_line - delta)
	state_time += delta
	if not fixed_target and is_instance_valid(target):
		match state:
			State.APPROACH:
				facing_angle = 0 if target.position.x >= position.x else PI
				if state_time > 0.5 and _can_see_target(): _enter(State.WINDUP)
			State.WINDUP:
				# Last 0.35s locks direction, allowing an intentional dodge.
				if state_time <= 0.5:
					facing_angle = 0 if target.position.x >= position.x else PI
					locked_direction = (target.aim_origin() - muzzle()).normalized()
				if state_time >= 0.85: _enter(State.ATTACK)
			State.ATTACK:
				if not did_attack:
					did_attack = true
					attack_count += 1
					shot_line = 0.1
					var hit := _shot_hit(1 | 2)
					if not hit.is_empty() and hit.collider == target:
						target.receive_damage(1, locked_direction * 180 + Vector2(0, -80))
				if state_time >= 0.15: _enter(State.RECOVERY)
			State.RECOVERY:
				if state_time >= 1.4: _enter(State.APPROACH)
	knockback_velocity.x = move_toward(knockback_velocity.x, 0, 480 * delta)
	knockback_velocity.y += 1500 * delta
	velocity = knockback_velocity
	move_and_slide()
	if is_on_floor(): knockback_velocity.y = 0
	if is_on_wall(): knockback_velocity.x = 0
	queue_redraw()

func _can_see_target() -> bool:
	if global_position.distance_to(target.global_position) > 520: return false
	var ray := PhysicsRayQueryParameters2D.create(global_position + Vector2(0, -30), target.aim_origin(), 1 | 2)
	var hit := get_world_2d().direct_space_state.intersect_ray(ray)
	return not hit.is_empty() and hit.collider == target

func _shot_hit(mask: int) -> Dictionary:
	var space := get_world_2d().direct_space_state
	var near_wall := PhysicsRayQueryParameters2D.create(global_position + Vector2(0, -30), muzzle(), 1)
	near_wall.hit_from_inside = true
	var obstruction := space.intersect_ray(near_wall)
	if not obstruction.is_empty(): return obstruction
	var ray := PhysicsRayQueryParameters2D.create(muzzle(), muzzle() + locked_direction * 600, mask)
	ray.hit_from_inside = true
	return space.intersect_ray(ray)

func receive_hit(shot: ShotContext, point: Vector2, _weak: bool = false) -> Dictionary:
	if state == State.DEAD: return {}
	var back := (shot.source_position - global_position).dot(forward_vector()) < 0
	var damage := shot.damage * (1.5 if back else 1.0)
	health = maxf(0, health - damage)
	knockback_velocity += shot.direction * shot.knockback / mass
	hit_flash = 0.1
	var result := {"zone": "BACK" if back else "BODY", "damage": damage, "point": point, "hp": health}
	hit_received.emit(result)
	if health <= 0:
		_enter(State.DEAD)
		collision_layer = 0
		collision_mask = 0
		hurtbox.collision_layer = 0
		weakpoint.collision_layer = 0
		body_shape.set_deferred("disabled", true)
		defeated.emit()
	queue_redraw()
	return result

func _draw() -> void:
	if state == State.DEAD: return
	draw_rect(Rect2(-18, -54, 36, 2), Color("272a3d"))
	draw_rect(Rect2(-18, -54, 36 * health / 72.0, 2), Color("e9bb77"))
	if state == State.WINDUP or shot_line > 0:
		var start := muzzle() - global_position
		var end := start + locked_direction * 600
		var hit := _shot_hit(1)
		if not hit.is_empty(): end = hit.position - global_position
		draw_line(start, end, Color("fff2be") if shot_line > 0 else Color(0.95, 0.35, 0.27, 0.6), 2 if shot_line > 0 else 1)
		if state == State.WINDUP:
			draw_arc(Vector2(0, -63), 5, -PI / 2, -PI / 2 + TAU * minf(1, state_time / 0.85), 20, Color("ffb873"), 1)
