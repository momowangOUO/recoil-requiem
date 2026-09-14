extends SceneTree
var checks := 0
var failures := 0
var world: Node2D
var player: PlayerController
var shots := 0
const DT := 1.0 / 60.0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func run() -> void:
	var game: RecoilLab = load("res://scenes/lab.tscn").instantiate()
	root.add_child(game)
	game.player.manual_control = true
	check(game.player.get("melee") != null, "Player owns a claw melee runtime independent of weapon slots")
	if game.player.get("melee") == null:
		game.free()
		print("CLAW STAGE RESULT: %d checks, %d failures" % [checks, failures])
		quit(1)
		return
	game.player.melee.start(game.player)
	game.player.manual_control = false
	game.pause_trial()
	var paused_cooldown: float = game.player.melee.cooldown
	for i in 3: await process_frame
	check(game.player.melee.cooldown == paused_cooldown and game.player.melee.elapsed == 0, "Game pause freezes actual melee runtime")
	game.player.manual_control = true
	game.resume_trial()
	game._respawn()
	check(not game.player.melee.active() and game.player.melee.cooldown == 0, "Production respawn clears old melee state")
	game.free()
	world = Node2D.new()
	root.add_child(world)
	player = PlayerController.new()
	player.manual_control = true
	player.weapons.configure(WeaponData.baselines())
	player.position = Vector2(100, 100)
	world.add_child(player)
	player.tuning.gravity = 0
	player.tuning.air_deceleration = 0
	player.tuning.soft_cap_x = 10000
	player.shot_fired.connect(func(_context, _data): shots += 1)
	await physics_frame
	var enemy := ShieldEnemy.new()
	enemy.fixed_target = true
	enemy.position = Vector2(137, 100)
	world.add_child(enemy)
	enemy.set_physics_process(false)
	await physics_frame
	var input := InputFrame.new()
	input.set("melee_pressed", true)
	input.fire_pressed = true
	input.fire_held = true
	input.aim_world = Vector2(300, -100)
	var ammo := player.weapons.current().ammo
	player.step(input, DT)
	check(player.get("melee").active(), "V starts an actual controller attack")
	check(shots == 0 and player.weapons.current().ammo == ammo, "Melee has priority over same-frame fire without ammo or shot event")
	input.fire_pressed = false
	input.fire_held = false
	await ticks(3)
	check(enemy.health == 120 and is_equal_approx(player.position.x, 100), "Windup has no hit or lunge")
	await ticks(6)
	check(is_equal_approx(enemy.health, 120 - 35 * 0.15), "Swept claw connects once against shield front")
	check(is_equal_approx(enemy.knockback_velocity.x, 260.0 / 1.5), "Melee impulse uses enemy mass once")
	check(absf(player.position.x - 122) < 0.1 and player.position.y == 100, "Lunge adds exactly 22 horizontal pixels and no vertical motion")
	check(player.facing == 1, "Melee locks starting facing despite idle aim changes")
	await ticks(15)
	check(not player.get("melee").active(), "Recovery ends at 0.38 seconds")
	player.step(input, DT)
	check(not player.get("melee").active(), "Cooldown prevents immediately repeating after recovery")
	player.weapons.select_weapon(2)
	player.step(input, DT)
	check(not player.get("melee").active(), "Switching weapon cannot bypass melee cooldown")
	await ticks(20)
	var air_x := player.position.x
	player.step(input, DT)
	await ticks(10)
	check(absf(player.position.x - air_x) < 0.1, "Second airborne attack has no lunge assistance")
	player.receive_damage(1, Vector2(-120, -50))
	check(not player.get("melee").active() and player.get("melee").cooldown > 0, "Damage cancels melee immediately without refunding cooldown")
	player.step(input, DT)
	check(not player.get("melee").active(), "Hurt stun has priority over V")
	player.get("melee").reset()
	player.hurt_stun = 0
	player.invulnerability = 0
	player.velocity = Vector2(300, -80)
	player.step(input, DT)
	await ticks(10)
	check(player.velocity == Vector2(300, -80), "Lunge leaves existing recoil velocity unchanged")
	player.get("melee").reset()
	player.velocity = Vector2.ZERO
	player.position = Vector2(100, 100)
	var wall := StaticBody2D.new()
	wall.position = Vector2(118, 75)
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(4, 100)
	shape.shape = rectangle
	wall.add_child(shape)
	world.add_child(wall)
	enemy.health = 120
	await physics_frame
	player.step(input, DT)
	await ticks(12)
	check(player.position.x <= 107.1, "Real collision prevents lunging through a solid wall")
	check(enemy.health == 120, "Close enemy across wall cannot be clawed through it")
	wall.free()
	player.melee.reset()
	player.position = Vector2(100, 100)
	enemy.position = Vector2(137, 100)
	enemy.facing_angle = 0
	enemy.state = ShieldEnemy.State.APPROACH
	enemy._sync_weakpoint()
	await physics_frame
	player.step(input, DT)
	await ticks(12)
	check(is_equal_approx(enemy.health, 120 - 35 * 1.8), "Rear claw retains shield enemy back multiplier")
	check(enemy.hit_flash > 0 and enemy.hurt_stun > 0, "Claw uses existing enemy hurt feedback")
	player.melee.reset()
	player.position = Vector2(100, 100)
	enemy.health = 120
	enemy.fixed_target = false
	enemy.state = ShieldEnemy.State.RECOVERY
	enemy._sync_weakpoint()
	enemy.weakpoint.position = enemy.hurtbox.position
	var weak_shape: RectangleShape2D = enemy.weakpoint.get_child(0).shape
	weak_shape.size = Vector2(30, 48)
	await physics_frame
	player.step(input, DT)
	await ticks(12)
	check(is_equal_approx(enemy.health, 120 - 35 * 2.5), "Overlapping exposed weakpoint and body take exactly one hit")
	enemy.free()
	player.melee.reset()
	player.weapons.select_weapon(1)
	var shotgun := player.weapons.current()
	shotgun.ammo = 1
	shotgun.start_reload()
	shotgun.tick(shotgun.data.reload_time + 0.1, true)
	var loaded := shotgun.ammo
	input.reload_pressed = true
	player.step(input, DT)
	check(not shotgun.reloading and shotgun.reload_elapsed == 0 and shotgun.ammo == loaded, "Claw cancels partial shell reload but keeps completed shells")
	await ticks(12)
	check(not shotgun.reloading and shotgun.ammo == loaded, "Claw does not silently restart or advance cancelled reload")
	input.reload_pressed = false
	player.melee.reset()
	player.health = 1
	player.invulnerability = 0
	player.step(input, DT)
	player.receive_damage(1, Vector2.ZERO)
	player.step(input, DT)
	check(player.health == 0 and not player.melee.active(), "Death cancels melee and rejects later V input")
	player.melee.reset()
	check(player.melee.cooldown == 0 and not player.melee.air_lunge_used and not player.melee.active(), "Respawn reset clears attack, cooldown and airborne usage")
	player.health = 5
	player.hurt_stun = 0
	player.velocity = Vector2.ZERO
	player.position = Vector2(100, 100)
	player.tuning.gravity = 1000
	var floor_body := StaticBody2D.new()
	floor_body.position = Vector2(200, 105)
	var floor_shape := CollisionShape2D.new()
	var floor_rect := RectangleShape2D.new()
	floor_rect.size = Vector2(500, 10)
	floor_shape.shape = floor_rect
	floor_body.add_child(floor_shape)
	world.add_child(floor_body)
	await ticks(3)
	player.melee.air_lunge_used = true
	await ticks(2)
	check(player.is_on_floor() and not player.melee.air_lunge_used, "Landing restores the next airborne lunge allowance")
	var ground_start := player.position.x
	player.step(input, DT)
	await ticks(12)
	check(absf(player.position.x - ground_start - 22) < 0.1 and player.is_on_floor(), "Ground claw also adds 22 pixels and keeps floor contact")
	floor_body.free()
	player.melee.reset()
	player.tuning.gravity = 0
	player.velocity = Vector2(3600, 0)
	player.position = Vector2(0, 100)
	var swept_enemy := RifleEnemy.new()
	swept_enemy.position = Vector2(355, 100)
	swept_enemy.facing_angle = PI
	world.add_child(swept_enemy)
	swept_enemy.set_physics_process(false)
	await physics_frame
	input.aim_world = Vector2(1000, 100)
	player.step(input, DT)
	await ticks(6)
	check(swept_enemy.health == 37, "Fast pre-existing recoil cannot tunnel the active claw past an intervening body")
	for facing in [-1.0, 1.0]:
		player.facing = facing
		for phase in 39:
			player.melee.elapsed = phase * 0.01
			var fitted := player.visual.claw_pose()
			var upper: float = PlayerVisual.RIGHT_SHOULDERS[0].distance_to(PlayerVisual.RIGHT_ELBOWS[0]) * PlayerVisual.ARM_SCALE
			var lower: float = PlayerVisual.RIGHT_ELBOWS[0].distance_to(PlayerVisual.RIGHT_WRISTS[0]) * PlayerVisual.ARM_SCALE
			check(absf(fitted.shoulder.distance_to(fitted.elbow) - upper) < 0.01 and absf(fitted.elbow.distance_to(fitted.wrist) - lower) < 0.01, "Claw pose keeps authored sleeve lengths and wrist registration %s/%s" % [facing, phase])
	await input_checks()
	world.free()
	print("CLAW STAGE RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func ticks(count: int) -> void:
	for i in count:
		await physics_frame
		player.step(InputFrame.new(), DT)

func input_checks() -> void:
	await process_frame
	var keyboard := KeyboardInput.new()
	KeyboardInput.install_actions()
	keyboard.sample(Vector2.RIGHT * 300)
	var event := InputEventKey.new()
	event.keycode = KEY_V
	event.physical_keycode = KEY_V
	event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	check(keyboard.sample(Vector2.RIGHT * 300).melee_pressed, "Actual V key event reaches InputFrame")
	await physics_frame
	await process_frame
	await physics_frame
	check(not keyboard.sample(Vector2.RIGHT * 300).melee_pressed, "Holding V does not request repeated attacks")
	keyboard.suppress()
	check(not keyboard.sample(Vector2.RIGHT * 300).melee_pressed, "Pause/focus input suppression rejects held V")
	event.pressed = false
	Input.parse_input_event(event.duplicate())
	Input.flush_buffered_events()
	keyboard.sample(Vector2.RIGHT * 300)
	await process_frame
	event.pressed = true
	Input.parse_input_event(event.duplicate())
	Input.flush_buffered_events()
	check(keyboard.sample(Vector2.RIGHT * 300).melee_pressed, "Release then repress rearms V after suppression")
	event.pressed = false
	Input.parse_input_event(event.duplicate())
	Input.flush_buffered_events()
