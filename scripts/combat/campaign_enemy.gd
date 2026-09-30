class_name CampaignEnemy
extends ShieldEnemy
var archetype := "charger"
var attack_count := 0
var max_health := 72.0
var staging_locked := false
var aim_angle := 0.0
var phase := 1
var attack_kind := ""
var locked_direction := Vector2.RIGHT
var locked_target := Vector2.ZERO
var home := Vector2.ZERO
var shot_line := 0.0
var shot_end := Vector2.ZERO
var bomb_age := -1.0
var bomb_from := Vector2.ZERO
var bomb_to := Vector2.ZERO
var bomb_point := Vector2.ZERO
var blast_time := 0.0
var support_target: ShieldEnemy
var heal_budget := 36.0
var channel_time := 0.0
var artwork: Node2D

func _ready() -> void:
	super._ready()
	max_health = {"charger": 78.0, "grenadier": 66.0, "flyer": 60.0, "support": 70.0, "elite": 140.0, "boss": 240.0}.get(archetype, 78.0)
	health = max_health
	set_meta("campaign_max_health", max_health)
	mass = 2.0 if archetype == "boss" else (1.35 if archetype == "elite" else 1.0)
	home = global_position
	add_to_group("campaign_enemies")
	visual.hide()
	visual.set_physics_process(false)
	# The generated action sheet is wired after its source validation.
	var visual_script = load("res://scripts/combat/campaign_enemy_visual.gd")
	if visual_script != null:
		artwork = visual_script.new()
		artwork.actor = self
		add_child(artwork)

func _notification(what: int) -> void:
	if what == NOTIFICATION_DISABLED:
		_cancel_hazards()
		if state != State.DEAD: _enter(State.APPROACH)

func _cancel_hazards() -> void:
	bomb_age = -1
	shot_line = 0
	blast_time = 0
	support_target = null
	channel_time = 0
	queue_redraw()

func weakpoint_open() -> bool:
	return state == State.RECOVERY and archetype in ["charger", "flyer", "elite", "boss"]

func windup_duration() -> float:
	return {"charger": 0.45, "grenadier": 0.65, "flyer": 0.5, "support": 0.7, "elite": 0.4, "boss": 0.55}.get(archetype, 0.45)

func attack_duration() -> float:
	if archetype == "charger": return 0.22
	if archetype == "flyer": return 0.38
	if archetype == "support": return 1.0
	if attack_kind == "rush": return 0.42
	return 0.15

func recovery_duration() -> float:
	return {"charger": 0.6, "grenadier": 1.0, "flyer": 1.0, "support": 1.4, "elite": 0.75, "boss": 0.85}.get(archetype, 0.6)

func _ray(from: Vector2, to: Vector2, mask := 1) -> Dictionary:
	var query := PhysicsRayQueryParameters2D.create(from, to, mask)
	query.hit_from_inside = true
	return get_world_2d().direct_space_state.intersect_ray(query)

func _visible_target() -> bool:
	return _ray(global_position + Vector2(0, -24), target.aim_origin()).is_empty()

func _begin_attack() -> void:
	facing_angle = 0 if target.global_position.x >= global_position.x else PI
	locked_target = target.global_position
	locked_direction = (target.aim_origin() - (global_position + Vector2(0, -26))).normalized()
	aim_angle = locked_direction.angle()
	attack_kind = "rush" if archetype == "boss" and phase == 2 and attack_count % 2 == 0 else "shot"
	if archetype == "flyer": locked_direction = (target.global_position - global_position).normalized()
	if archetype == "grenadier":
		# Lock a world-space landing spot at windup start, not a homing target.
		var floor_hit := _ray(locked_target + Vector2(0, -8), locked_target + Vector2(0, 180), 1 | 1024)
		if not floor_hit.is_empty(): locked_target = floor_hit.position
	_enter(State.WINDUP)

func _physics_process(delta: float) -> void:
	if not can_process() or state == State.DEAD: return
	if fixed_target or not is_instance_valid(target) or target.health <= 0 or global_position.distance_to(target.global_position) > 700:
		_cancel_hazards()
		if state != State.APPROACH: _enter(State.APPROACH)
		return
	shot_line = maxf(0, shot_line - delta)
	blast_time = maxf(0, blast_time - delta)
	_update_bomb(delta)
	if advance_hurt(delta):
		support_target = null
		channel_time = 0
		return
	state_time += delta
	var movement := Vector2.ZERO
	var difference := target.global_position - global_position
	match state:
		State.APPROACH:
			facing_angle = 0 if difference.x >= 0 else PI
			if archetype == "charger":
				if absf(difference.x) > 105: movement.x = signf(difference.x) * 68
				elif absf(difference.y) < 45 and _visible_target(): _begin_attack()
			elif archetype == "flyer":
				var orbit := target.global_position + Vector2(-signf(difference.x) * 95, -62)
				movement = (orbit - global_position).limit_length(100)
				if state_time >= 0.65 and _visible_target(): _begin_attack()
			elif archetype in ["elite", "boss"]:
				var strafe := 1.0 if attack_count % 2 == 0 else -1.0
				if absf(global_position.x + strafe * 24 - home.x) < 220:
					movement.x = strafe * (135 if archetype == "elite" else 165)
				if state_time >= 0.4 and _visible_target(): _begin_attack()
			elif state_time >= 0.55 and _visible_target():
				_begin_attack()
		State.WINDUP:
			if state_time + 0.000001 >= windup_duration():
				_enter(State.ATTACK)
				attack_count += 1
		State.ATTACK:
			if archetype == "charger" or attack_kind == "rush":
				movement.x = signf(cos(facing_angle)) * (285 if archetype == "charger" else 320)
			elif archetype == "flyer":
				movement = locked_direction * 255
			elif archetype == "support":
				_channel(delta)
			elif not did_attack:
				did_attack = true
				if archetype == "grenadier": _throw_bomb()
				else: _shoot()
			if state_time + 0.000001 >= attack_duration():
				support_target = null
				_enter(State.RECOVERY)
		State.RECOVERY:
			if archetype == "flyer": movement.y = 95
			if state_time + 0.000001 >= recovery_duration(): _enter(State.APPROACH)
	if archetype != "flyer":
		if state == State.APPROACH and is_on_floor() and movement.x != 0:
			var ahead := global_position + Vector2(signf(movement.x) * 22, -4)
			if _ray(ahead, ahead + Vector2(0, 28), 1 | 1024).is_empty(): movement.x = 0
		knockback_velocity.y += 1500 * delta
	else:
		knockback_velocity.y = move_toward(knockback_velocity.y, 0, 200 * delta)
	knockback_velocity.x = move_toward(knockback_velocity.x, 0, 480 * delta)
	velocity = movement + knockback_velocity
	var before := global_position
	move_and_slide()
	if is_on_floor(): knockback_velocity.y = 0
	if is_on_wall(): knockback_velocity.x = 0
	if state == State.ATTACK and (archetype in ["charger", "flyer"] or attack_kind == "rush"):
		_contact_strike(before)
	_sync_weakpoint()
	queue_redraw()

func _contact_strike(before: Vector2) -> void:
	if did_attack: return
	var after := global_position
	var segment := after - before
	var fraction := clampf((target.global_position - before).dot(segment) / maxf(0.001, segment.length_squared()), 0, 1)
	var nearest := before + segment * fraction
	var offset := target.global_position - nearest
	if absf(offset.x) > 42 or absf(offset.y) > 34 or offset.x * signf(cos(facing_angle)) < -16: return
	if not _ray(nearest + Vector2(0, -24), target.aim_origin()).is_empty(): return
	did_attack = true
	target.receive_damage(1, Vector2(signf(cos(facing_angle)) * 220, -85))

func _shoot() -> void:
	var from := global_position + Vector2(0, -26)
	var hit := _ray(from, from + locked_direction * 600, 1 | 2)
	shot_end = hit.position if not hit.is_empty() else from + locked_direction * 600
	shot_line = 0.11
	if not hit.is_empty() and hit.collider == target:
		target.receive_damage(1, locked_direction * 160 + Vector2(0, -55))

func _throw_bomb() -> void:
	bomb_age = 0
	bomb_from = global_position + Vector2(signf(cos(facing_angle)) * 16, -30)
	if not _ray(global_position + Vector2(0, -24), bomb_from).is_empty():
		bomb_from = global_position + Vector2(0, -24)
	bomb_to = locked_target + Vector2(0, -3)
	bomb_point = bomb_from

func _update_bomb(delta: float) -> void:
	if bomb_age < 0: return
	bomb_age += delta
	if bomb_age <= 0.6:
		var t := minf(1, bomb_age / 0.6)
		var next := bomb_from.lerp(bomb_to, t) + Vector2(0, -sin(t * PI) * 60)
		var impact := _ray(bomb_point, next, 1 | 1024)
		if not impact.is_empty():
			bomb_to = impact.position - (next - bomb_point).normalized() * 2
			bomb_point = bomb_to
			bomb_age = 0.6
		else: bomb_point = next
	else: bomb_point = bomb_to
	if bomb_age >= 1.1:
		bomb_age = -1
		blast_time = 0.16
		if target.aim_origin().distance_to(bomb_to) < 54 and _ray(bomb_to, target.aim_origin()).is_empty():
			target.receive_damage(1, (target.aim_origin() - bomb_to).normalized() * 180)

func _channel(delta: float) -> void:
	if heal_budget <= 0: return
	if not is_instance_valid(support_target):
		for candidate in get_tree().get_nodes_in_group("campaign_enemies"):
			if candidate == self or not candidate is ShieldEnemy or candidate.state == State.DEAD or not candidate.can_process(): continue
			if candidate.global_position.distance_to(global_position) > 180: continue
			if not _ray(global_position + Vector2(0, -24), candidate.global_position + Vector2(0, -24)).is_empty(): continue
			if candidate.health < _max_hp(candidate):
				support_target = candidate
				break
	if not is_instance_valid(support_target): return
	if support_target.state == State.DEAD or not support_target.can_process() or support_target.global_position.distance_to(global_position) > 180 or not _ray(global_position + Vector2(0, -24), support_target.global_position + Vector2(0, -24)).is_empty():
		support_target = null
		channel_time = 0
		return
	channel_time += delta
	if channel_time >= 0.3:
		channel_time = 0
		var amount := minf(heal_budget, minf(6, _max_hp(support_target) - support_target.health))
		support_target.health += maxf(0, amount)
		heal_budget -= maxf(0, amount)

func _max_hp(other: ShieldEnemy) -> float:
	return float(other.get_meta("campaign_max_health", 72 if other is RifleEnemy else 120))

func receive_hit(shot: ShotContext, point: Vector2, weak := false) -> Dictionary:
	if state == State.DEAD or staging_locked: return {}
	var back := (shot.source_position - (global_position + Vector2(0, -24))).dot(forward_vector()) < 0
	var multiplier := 2.0 if weak and weakpoint_open() else (1.5 if back else 1.0)
	var damage := shot.damage * multiplier
	health = maxf(0, health - damage)
	knockback_velocity += shot.direction * shot.knockback / mass
	apply_hit_reaction(shot.direction, false)
	support_target = null
	channel_time = 0
	var result := {"zone": "WEAK" if multiplier == 2 else ("BACK" if back else "BODY"), "damage": damage, "point": point, "hp": health, "direction": shot.direction}
	hit_received.emit(result)
	if health <= 0:
		_cancel_hazards()
		_enter(State.DEAD)
		collision_layer = 0
		collision_mask = 0
		hurtbox.collision_layer = 0
		weakpoint.collision_layer = 0
		body_shape.set_deferred("disabled", true)
		defeated.emit()
	elif archetype == "boss" and health <= max_health * 0.5 and phase == 1:
		phase = 2
		_cancel_hazards()
		_enter(State.RECOVERY)
	queue_redraw()
	return result

func _draw() -> void:
	if state == State.DEAD or not can_process(): return
	draw_rect(Rect2(-18, -54, 36, 2), Color("272a3d"))
	draw_rect(Rect2(-18, -54, 36 * health / max_health, 2), Color("ed675d"))
	if state == State.WINDUP:
		draw_arc(Vector2(0, -60), 5, -PI / 2, -PI / 2 + TAU * minf(1, state_time / windup_duration()), 20, Color("ffc883"), 1)
		if archetype in ["elite", "boss"] and attack_kind != "rush":
			var hit := _ray(global_position + Vector2(0, -26), global_position + Vector2(0, -26) + locked_direction * 600)
			var end: Vector2 = hit.position - global_position if not hit.is_empty() else Vector2(0, -26) + locked_direction * 600
			draw_line(Vector2(0, -26), end, Color(0.9, 0.3, 0.3, 0.6), 1)
		elif archetype == "grenadier":
			draw_arc(locked_target - global_position, 26, PI, TAU, 16, Color("ffc883"), 1)
		else:
			draw_line(Vector2(0, -20), Vector2(signf(cos(facing_angle)) * 40, -20), Color("ffc883"), 1)
	if shot_line > 0: draw_line(Vector2(0, -26), shot_end - global_position, Color("fff2be"), 2)
	if bomb_age >= 0:
		draw_circle(bomb_point - global_position, 3, Color("b79257"))
		draw_circle(bomb_point - global_position + Vector2(0, -3), 1, Color("fff2be"))
		draw_arc(bomb_to - global_position, 40, PI, TAU, 20, Color("ed675d"), 1)
	if blast_time > 0: draw_arc(bomb_to - global_position, 54 * (1 - blast_time / 0.16), 0, TAU, 24, Color("ffc883"), 3)
	if is_instance_valid(support_target):
		draw_line(Vector2(0, -24), support_target.global_position - global_position + Vector2(0, -24), Color("6cddd3"), 1)
