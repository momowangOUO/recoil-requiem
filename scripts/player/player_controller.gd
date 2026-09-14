class_name PlayerController
extends CharacterBody2D

signal shot_fired(context: ShotContext, data: WeaponData)
signal died
signal hurt

var tuning := PlayerTuning.new()
var weapons := WeaponController.new()
var melee := preload("res://scripts/player/claw_melee.gd").new()
var input_source: Callable
var manual_control := false
var aim_direction := Vector2.RIGHT
var facing: float = 1.0
var health: int = 5
var invulnerability: float = 0.0
var drop_time: float = 0.0
var flash_time: float = 0.0
var max_rise: float = 0.0
var start_y: float = 0.0
var last_recoil := Vector2.ZERO
const COYOTE_SECONDS := 0.10
const JUMP_BUFFER_SECONDS := 0.10
var coyote_time := 0.0
var jump_buffer_time := 0.0
var visual: PlayerVisual
var move_intent_x := 0.0
var air_lift_age := 0.0
var air_lift_started := false
var hurt_stun := 0.0
var hit_flash := 0.0
var last_hit_direction := Vector2.RIGHT

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1 | 1024
	floor_snap_length = 2.0
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(18, 38)
	collision.shape = shape
	collision.position.y = -19
	add_child(collision)
	add_child(weapons)
	visual = PlayerVisual.new()
	visual.actor = self
	add_child(visual)
	start_y = position.y

func aim_origin() -> Vector2:
	return global_position + Vector2(0, -26)

func update_aim(target: Vector2) -> void:
	var raw := target - aim_origin()
	if raw.length() >= 12.0:
		aim_direction = raw.normalized()
		if absf(aim_direction.x) > 0.06:
			facing = signf(aim_direction.x)

func _physics_process(delta: float) -> void:
	if not manual_control and input_source.is_valid():
		step(input_source.call(), delta)

func step(frame: InputFrame, delta: float) -> void:
	if health <= 0:
		melee.cancel()
		return
	melee.tick_cooldown(delta, is_on_floor())
	if is_on_floor():
		air_lift_age = 0.0
		air_lift_started = false
	elif air_lift_started:
		air_lift_age += delta
	invulnerability = maxf(0.0, invulnerability - delta)
	hit_flash = maxf(0.0, hit_flash - delta)
	flash_time = maxf(0.0, flash_time - delta)
	drop_time = maxf(0.0, drop_time - delta)
	set_collision_mask_value(11, drop_time <= 0.0)
	if hurt_stun > 0.0:
		hurt_stun = maxf(0.0, hurt_stun - delta)
		clear_jump_buffer()
		coyote_time = 0.0
		move_intent_x = 0.0
		# Cooldowns and an existing reload keep real time, but hits cannot buffer a shot.
		weapons.advance(delta, InputFrame.new())
		velocity.y = minf(tuning.terminal_velocity, velocity.y + tuning.gravity * delta)
		velocity.x = move_toward(velocity.x, 0, 300 * delta)
		move_and_slide()
		visual.update_pose(delta)
		return
	coyote_time = COYOTE_SECONDS if is_on_floor() and drop_time <= 0.0 else maxf(0.0, coyote_time - delta)
	jump_buffer_time = JUMP_BUFFER_SECONDS if frame.jump_pressed else maxf(0.0, jump_buffer_time - delta)
	if not melee.active(): update_aim(frame.aim_world)
	if frame.melee_pressed: melee.start(self)
	if melee.active(): facing = melee.direction
	move_intent_x = frame.move.x
	if is_on_floor():
		var acceleration := tuning.ground_acceleration if frame.move.x != 0.0 else tuning.ground_deceleration
		if frame.move.x * velocity.x < 0.0:
			acceleration = tuning.ground_deceleration
		velocity.x = move_toward(velocity.x, frame.move.x * tuning.walk_max_speed, acceleration * delta)
		if frame.drop_pressed:
			clear_jump_buffer()
			coyote_time = 0.0
			drop_time = 0.22
			set_collision_mask_value(11, false)
			velocity.y = maxf(velocity.y, 80.0)
	else:
		if frame.move.x == 0.0:
			velocity.x = move_toward(velocity.x, 0.0, tuning.air_deceleration * delta)
		elif velocity.x * frame.move.x < tuning.air_max_speed:
			# Input has a cruise speed; existing faster recoil is not clamped away.
			velocity.x = move_toward(velocity.x, frame.move.x * tuning.air_max_speed, tuning.air_control_x * delta)
		velocity.y += frame.move.y * minf(tuning.air_control_y, tuning.gravity * 0.8) * delta
	if velocity.y < tuning.terminal_velocity:
		velocity.y = minf(tuning.terminal_velocity, velocity.y + tuning.gravity * delta)
	if jump_buffer_time > 0.0 and coyote_time > 0.0 and drop_time <= 0.0:
		# Add lift to existing upward momentum; never erase recoil or horizontal speed.
		velocity.y = minf(velocity.y, 0.0) - tuning.jump_impulse
		jump_buffer_time = 0.0
		coyote_time = 0.0
	var weapon := weapons.advance(delta, frame, melee.active())
	if weapon:
		last_recoil = -aim_direction * weapon.recoil_impulse
		last_recoil.x *= tuning.horizontal_recoil_scale
		if tuning.air_lift_speed > 0.0 and last_recoil.y < 0.0 and (not is_on_floor() or velocity.y < 0.0):
			# Braking descent stays effective. Added ascent saturates smoothly and
			# fades during this airborne episode; switching/reloading cannot renew it.
			air_lift_started = true
			var braking := minf(maxf(velocity.y, 0.0), -last_recoil.y)
			var lift := -last_recoil.y - braking
			var headroom := maxf(0.0, tuning.air_lift_speed - maxf(-velocity.y, 0.0))
			# The first shot supplies its real impulse. Later shots retain useful lift;
			# a speed ceiling bounds ascent without making gravity change mid-flight.
			var fade := 0.35 + 0.65 * exp(-air_lift_age * 0.65)
			last_recoil.y = -braking - minf(headroom, lift * fade)
		if is_on_floor() and velocity.y >= 0.0:
			# Ground contact absorbs horizontal kick, never the upward launch impulse.
			last_recoil.x *= tuning.ground_recoil_scale
		velocity += last_recoil
		flash_time = 0.065
		var context := ShotContext.new()
		context.source_position = aim_origin()
		context.muzzle_position = aim_origin() + aim_direction * 25.0
		context.direction = aim_direction
		context.damage = weapon.damage
		context.knockback = weapon.enemy_knockback / weapon.pellet_count
		context.speed = weapon.projectile_speed
		context.color = weapon.color
		shot_fired.emit(context, weapon)
	if absf(velocity.x) > tuning.soft_cap_x:
		velocity.x = move_toward(velocity.x, signf(velocity.x) * tuning.soft_cap_x, tuning.overspeed_drag_x * delta)
	if absf(velocity.y) > tuning.soft_cap_y:
		velocity.y = move_toward(velocity.y, signf(velocity.y) * tuning.soft_cap_y, tuning.overspeed_drag_y * delta)
	var movement_start := global_position
	move_and_slide()
	melee.advance(self, delta, movement_start)
	max_rise = maxf(max_rise, start_y - position.y)
	visual.update_pose(delta)
	queue_redraw()

func clear_jump_buffer() -> void:
	jump_buffer_time = 0.0

func receive_damage(amount: int, push: Vector2) -> void:
	if invulnerability > 0.0 or health <= 0:
		return
	health = maxi(0, health - amount)
	invulnerability = 0.55
	hurt_stun = 0.18
	hit_flash = 0.09
	last_hit_direction = push.normalized()
	melee.cancel()
	clear_jump_buffer()
	velocity += push
	hurt.emit()
	if health == 0:
		died.emit()
