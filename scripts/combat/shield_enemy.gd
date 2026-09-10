class_name ShieldEnemy
extends CharacterBody2D

signal hit_received(result: Dictionary)
signal defeated

enum State { APPROACH, WINDUP, ATTACK, RECOVERY, DEAD }
var target: PlayerController
var fixed_target := false
var turn_speed: float = 110.0
var health: float = 120.0
var mass: float = 1.5
var facing_angle: float = PI
var state: State = State.APPROACH
var state_time: float = 0.0
var hit_flash: float = 0.0
var did_attack := false
var hurtbox: Area2D
var weakpoint: Area2D
var body_shape: CollisionShape2D
var knockback_velocity := Vector2.ZERO
var visual: ShieldVisual
var hurt_stun := 0.0
var stun_guard := 0.0
var last_hit_direction := Vector2.RIGHT

func apply_hit_reaction(direction: Vector2, frontal_shield: bool) -> void:
	last_hit_direction = direction
	hit_flash = 0.09
	# One blast gets one reaction. SMG and pellets cannot renew it indefinitely.
	if stun_guard <= 0.0:
		hurt_stun = 0.055 if frontal_shield else 0.18
		stun_guard = 0.38
		if not frontal_shield and state in [State.WINDUP, State.ATTACK]:
			_enter(State.RECOVERY)

func advance_hurt(delta: float) -> bool:
	hit_flash = maxf(0, hit_flash - delta)
	stun_guard = maxf(0, stun_guard - delta)
	if hurt_stun <= 0: return false
	hurt_stun = maxf(0, hurt_stun - delta)
	knockback_velocity.x = move_toward(knockback_velocity.x, 0, 480 * delta)
	knockback_velocity.y += 1500 * delta
	velocity = knockback_velocity
	move_and_slide()
	if is_on_floor(): knockback_velocity.y = 0
	if is_on_wall(): knockback_velocity.x = 0
	_sync_weakpoint()
	queue_redraw()
	return true

func _ready() -> void:
	collision_layer = 4
	collision_mask = 1 | 1024
	body_shape = CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(26, 44)
	body_shape.shape = shape
	body_shape.position.y = -22
	add_child(body_shape)
	hurtbox = _area(Vector2(30, 48), Vector2(0, -24), false)
	weakpoint = _area(Vector2(9, 12), Vector2(16, -18), true)
	_sync_weakpoint()
	visual = ShieldVisual.new()
	visual.actor = self
	add_child(visual)

func _area(size: Vector2, at: Vector2, weak: bool) -> Area2D:
	var area := Area2D.new()
	area.collision_layer = 64
	area.collision_mask = 0
	area.position = at
	area.set_meta("receiver", self)
	area.set_meta("weakpoint", weak)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	area.add_child(collision)
	add_child(area)
	return area

func forward_vector() -> Vector2:
	return Vector2.from_angle(facing_angle)

func weakpoint_open() -> bool:
	return not fixed_target and state == State.RECOVERY

func _sync_weakpoint() -> void:
	weakpoint.position.x = -signf(cos(facing_angle)) * 17.0
	weakpoint.collision_layer = 64 if weakpoint_open() else 0

func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	if advance_hurt(delta): return
	state_time += delta
	var walk := 0.0
	if not fixed_target and is_instance_valid(target):
		var to_player := target.global_position - global_position
		match state:
			State.APPROACH:
				# Turn on the horizontal plane, rather than aiming armor at the player's feet.
				var desired := 0.0 if to_player.x >= 0 else PI
				facing_angle = rotate_toward(facing_angle, desired, deg_to_rad(turn_speed) * delta)
				if absf(angle_difference(facing_angle, desired)) < 0.12:
					if absf(to_player.x) <= 54 and absf(to_player.y) <= 32:
						_enter(State.WINDUP)
					else:
						walk = signf(to_player.x) * 48
			State.WINDUP:
				if state_time >= 0.45:
					_enter(State.ATTACK)
			State.ATTACK:
				walk = signf(cos(facing_angle)) * 180
				var forward_x := signf(cos(facing_angle))
				if not did_attack and to_player.x * forward_x >= -8 and to_player.x * forward_x < 58 and absf(to_player.y) < 36:
					target.receive_damage(1, Vector2(forward_x * 230, -150))
					did_attack = true
				if state_time >= 0.15:
					_enter(State.RECOVERY)
			State.RECOVERY:
				if state_time >= 0.8:
					_enter(State.APPROACH)
	# Sentries hold their ledge while approaching. A committed bash or player
	# knockback can still send them off, so terrain remains a combat tool.
	if state == State.APPROACH and is_on_floor() and walk != 0:
		var ahead := global_position + Vector2(signf(walk) * 22, -4)
		var probe := PhysicsRayQueryParameters2D.create(ahead, ahead + Vector2(0, 28), 1 | 1024)
		if get_world_2d().direct_space_state.intersect_ray(probe).is_empty(): walk = 0
	knockback_velocity.x = move_toward(knockback_velocity.x, 0, 480 * delta)
	knockback_velocity.y += 1500 * delta
	velocity = Vector2(walk, 0) + knockback_velocity
	move_and_slide()
	if is_on_floor() and knockback_velocity.y > 0:
		knockback_velocity.y = 0
	if is_on_wall():
		knockback_velocity.x = 0
	_sync_weakpoint()
	queue_redraw()

func _enter(next: State) -> void:
	state = next
	state_time = 0
	did_attack = false

func receive_hit(shot: ShotContext, point: Vector2, weak: bool = false) -> Dictionary:
	if state == State.DEAD:
		return {}
	var origin_dir := (shot.source_position - (global_position + Vector2(0, -24))).normalized()
	var dot := origin_dir.dot(forward_vector())
	var zone := "SIDE"
	var multiplier := 0.7
	if dot > 0.5:
		zone = "FRONT"
		multiplier = 0.15
	elif dot < -0.5:
		zone = "BACK"
		multiplier = 1.8
	if weak and weakpoint_open():
		zone = "WEAK"
		multiplier = 2.5
	var damage := shot.damage * multiplier
	health = maxf(0, health - damage)
	knockback_velocity += shot.direction * shot.knockback / mass
	apply_hit_reaction(shot.direction, zone == "FRONT")
	var result := {"zone": zone, "damage": damage, "point": point, "hp": health, "direction": shot.direction}
	hit_received.emit(result)
	if health <= 0.0001:
		health = 0
		state = State.DEAD
		collision_layer = 0
		collision_mask = 0
		hurtbox.collision_layer = 0
		weakpoint.collision_layer = 0
		body_shape.set_deferred("disabled", true)
		defeated.emit()
	queue_redraw()
	return result

func _draw() -> void:
	if state == State.DEAD:
		return
	var facing := signf(cos(facing_angle))
	draw_circle(Vector2(-facing * 16, -19), 4 if weakpoint_open() else 2, Color("ff6d79") if weakpoint_open() else Color("873746"))
	draw_rect(Rect2(-18, -54, 36, 2), Color("272a3d"))
	draw_rect(Rect2(-18, -54, 36 * health / 120.0, 2), Color("e56766"))
	if state == State.WINDUP:
		draw_line(Vector2(facing * 25, -35), Vector2(facing * 25, -24), Color("ffc883"), 2)
		draw_circle(Vector2(facing * 25, -19), 1, Color("ffc883"))
