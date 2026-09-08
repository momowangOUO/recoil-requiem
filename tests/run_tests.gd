extends SceneTree

var failures: int = 0
var checks: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + message)
	else:
		print("PASS: " + message)

func run() -> void:
	var paths := ["res://scripts/core/weapon_data.gd", "res://scripts/core/weapon_runtime.gd", "res://scripts/player/player_controller.gd", "res://scripts/combat/shield_enemy.gd", "res://scenes/lab.tscn"]
	for path in paths:
		check(ResourceLoader.exists(path), "required component exists: " + path)
	if ResourceLoader.exists(paths[0]) and ResourceLoader.exists(paths[1]):
		await test_runtime()
	if ResourceLoader.exists(paths[2]):
		await test_player()
		await test_jump()
	if ResourceLoader.exists(paths[3]):
		await test_combat()
		await test_live_enemy()
	if ResourceLoader.exists(paths[4]):
		await test_lab()
	print("RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func test_runtime() -> void:
	KeyboardInput.install_actions()
	var data_script = load("res://scripts/core/weapon_data.gd")
	var runtime_script = load("res://scripts/core/weapon_runtime.gd")
	var defs: Array = data_script.baselines()
	var revolver = runtime_script.new(defs[0])
	check(revolver.try_fire(), "loaded revolver fires")
	check(revolver.ammo == 5, "one shot consumes one cartridge")
	check(not revolver.try_fire(), "cooldown prevents extra shots")
	revolver.tick(1.0 / 3.0, true)
	check(revolver.try_fire(), "revolver fires when cooldown expires")
	revolver.start_reload()
	check(not revolver.try_fire(), "reload blocks firing")
	revolver.tick(1.05, true)
	check(revolver.ammo == 6 and not revolver.reloading, "magazine reload completes")
	var shotgun = runtime_script.new(defs[1])
	shotgun.ammo = 0
	shotgun.start_reload()
	shotgun.tick(0.62, true)
	check(shotgun.ammo == 1 and shotgun.reloading, "shotgun loads one shell per interval")
	shotgun.cancel_reload()
	shotgun.tick(4.0, false)
	check(shotgun.ammo == 1 and not shotgun.reloading, "holstering retains loaded shell, no background reload")
	shotgun.start_reload()
	shotgun.tick(0.61, true)
	check(shotgun.ammo == 1, "cancelled partial shell progress is lost")
	shotgun.tick(0.01, true)
	check(shotgun.ammo == 2 and not shotgun.reloading, "second shell loads from full interval")
	var controller := WeaponController.new()
	controller.configure(defs, 0)
	check(controller.slots.size() == 6, "arsenal always exposes six numbered weapon slots")
	check(controller.slots[0] != null and controller.slots[1] != null and controller.slots[2] != null, "slots 1-3 contain the three prototype guns")
	check(controller.slots[3] == null and controller.slots[4] == null and controller.slots[5] == null, "slots 4-6 are explicit empty inventory slots")
	check(not "quick_slots" in controller, "weapon controller has no separate quick-gun concept")
	check(controller.has_method("select_weapon"), "weapon controller exposes centralized direct selection")
	for number in range(1, 7):
		check(InputMap.has_action("weapon_%d" % number), "keyboard action exists for weapon %d" % number)
	var f := InputFrame.new()
	f.fire_pressed = true
	controller.advance(0, f)
	f.fire_pressed = false
	f.reload_pressed = true
	controller.advance(0.1, f)
	f.reload_pressed = false
	f.weapon_slot_pressed = 1
	controller.advance(0.1, f)
	f.weapon_slot_pressed = 0
	controller.advance(0.1, f)
	check(controller.current().ammo == 5 and controller.current().reloading, "switching back restarts interrupted partial reload")
	check(controller.current().reload_elapsed == 0, "returning partial reload starts from zero progress")
	if controller.has_method("select_weapon"):
		controller.select_weapon(2)
		check(controller.current().data.id == &"smg", "number 3 directly selects SMG")
		controller.current().ammo = 7
		controller.current().cooldown = 0.25
		controller.select_weapon(0)
		controller.select_weapon(2)
		check(controller.current().ammo == 7 and controller.current().cooldown == 0.25, "direct switching preserves weapon ammo and cooldown")
		controller.select_weapon(5)
		check(controller.current().data.id == &"smg", "unassigned number slot leaves current weapon unchanged")
		f.weapon_slot_pressed = -1
		f.switch_pressed = true
		controller.advance(0, f)
		check(controller.current().data.id == &"revolver", "Q cycles slot 3 to the next occupied slot 1")
		controller.advance(0, f)
		check(controller.current().data.id == &"shotgun", "Q cycles slot 1 to occupied slot 2")
		controller.advance(0, f)
		check(controller.current().data.id == &"smg", "Q cycles through every occupied slot before wrapping")
		f.switch_pressed = false
	controller.free()

func frame_for(player: PlayerController, direction := Vector2.RIGHT) -> InputFrame:
	var frame := InputFrame.new()
	frame.aim_world = player.aim_origin() + direction * 100
	return frame

func make_player(parent: Node, at: Vector2, initial_weapon: int = 0) -> PlayerController:
	var player := PlayerController.new()
	# Historical acceptance measurements explicitly exercise the restorable GDD profile.
	player.tuning = PlayerTuning.gdd_baseline()
	player.position = at
	player.manual_control = true
	player.weapons.configure(WeaponData.baselines(), initial_weapon)
	parent.add_child(player)
	return player

func make_floor(parent: Node, rect: Rect2, layer: int = 1) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = rect.get_center()
	body.collision_layer = layer
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = rect.size
	shape.shape = rectangle
	body.add_child(shape)
	parent.add_child(body)
	return body

func test_player() -> void:
	var world := Node2D.new()
	root.add_child(world)
	make_floor(world, Rect2(-2000, 0, 4000, 32))
	var p := make_player(world, Vector2.ZERO)
	for index in 3:
		await physics_frame
		p.step(frame_for(p), 1.0 / 60)
	check(p.is_on_floor(), "fixture player grounded")
	var f := frame_for(p)
	f.move = Vector2(0, -1)
	for index in 60:
		await physics_frame
		p.step(f, 1.0 / 60)
	check(absf(p.position.y) < 0.2, "W alone cannot lift grounded player")
	f = frame_for(p, Vector2.RIGHT)
	f.move.x = -1
	for index in 10:
		await physics_frame
		f.aim_world = p.aim_origin() + Vector2.RIGHT * 100
		p.step(f, 1.0 / 60)
	check(p.velocity.x < 0 and p.aim_direction.x > 0.99, "walk left while aiming right")
	var previous_aim := p.aim_direction
	p.update_aim(p.aim_origin() + Vector2(-1, 1))
	check(p.aim_direction == previous_aim, "aim center deadzone retains last direction")
	p.free()
	p = make_player(world, Vector2.ZERO, 1)
	for index in 3:
		await physics_frame
		p.step(frame_for(p), 1.0 / 60)
	f = frame_for(p, Vector2.DOWN)
	f.fire_pressed = true
	p.step(f, 1.0 / 60)
	f.fire_pressed = false
	var height := 0.0
	for index in 75:
		await physics_frame
		f.aim_world = p.aim_origin() + Vector2.DOWN * 100
		p.step(f, 1.0 / 60)
		height = maxf(height, -p.position.y)
	check(height >= 140 and height <= 190, "shotgun physical rise within 140-190 px: %.2f" % height)
	check(p.weapons.current().ammo == 1, "seven pellets use one shell")
	world.free()
	var distances: Array[float] = []
	for mode in 3:
		world = Node2D.new()
		root.add_child(world)
		p = make_player(world, Vector2.ZERO, 2)
		f = frame_for(p, Vector2.DOWN)
		f.fire_held = mode > 0
		f.move.y = -1 if mode == 2 else 0
		for index in 120:
			await physics_frame
			f.aim_world = p.aim_origin() + Vector2.DOWN * 100
			p.step(f, 1.0 / 60)
		distances.append(p.position.y)
		world.free()
	check(distances[1] > 0 and distances[1] < distances[0] * 0.6, "SMG net descent < 60%% free fall: %s" % str(distances))
	check(distances[2] > 0, "SMG with W still descends")
	world = Node2D.new()
	root.add_child(world)
	make_floor(world, Rect2(-200, 128, 400, 32))
	var platform := make_floor(world, Rect2(-60, -16, 120, 8), 1024)
	platform.get_child(0).one_way_collision = true
	p = make_player(world, Vector2(0, 128), 1)
	for index in 3:
		await physics_frame
		p.step(frame_for(p), 1.0 / 60)
	f = frame_for(p, Vector2.DOWN)
	f.fire_pressed = true
	p.step(f, 1.0 / 60)
	f.fire_pressed = false
	for index in 80:
		await physics_frame
		f.aim_world = p.aim_origin() + Vector2.DOWN * 100
		p.step(f, 1.0 / 60)
	check(p.is_on_floor() and absf(p.position.y + 16) < 0.2, "shotgun crosses underside and lands on 144px one-way platform")
	f.drop_pressed = true
	p.step(f, 1.0 / 60)
	f.drop_pressed = false
	for index in 50:
		await physics_frame
		p.step(f, 1.0 / 60)
	check(p.is_on_floor() and absf(p.position.y - 128) < 0.2, "S drops through one-way platform and lands on solid floor")
	world.free()
	world = Node2D.new()
	root.add_child(world)
	make_floor(world, Rect2(-200, 0, 600, 32))
	make_floor(world, Rect2(136, -16, 64, 16))
	p = make_player(world, Vector2(120, 0))
	for index in 3:
		await physics_frame
		p.step(frame_for(p), 1.0 / 60)
	p.velocity.x = 100
	f = frame_for(p, Vector2.DOWN)
	f.move.x = 1
	f.fire_pressed = true
	p.step(f, 1.0 / 60)
	f.fire_pressed = false
	for index in 22:
		await physics_frame
		f.aim_world = p.aim_origin() + Vector2.DOWN * 100
		p.step(f, 1.0 / 60)
	check(p.position.x > 136 and p.position.y <= -15.9, "revolver traverses physical 16px step: position=%s velocity=%s" % [p.position, p.velocity])
	world.free()

func test_combat() -> void:
	var world := Node2D.new()
	root.add_child(world)
	for back in [false, true]:
		var enemy := ShieldEnemy.new()
		enemy.fixed_target = true
		enemy.facing_angle = 0
		world.add_child(enemy)
		enemy.set_physics_process(false)
		var shot := ShotContext.new()
		shot.damage = 24
		shot.source_position = Vector2(-100 if back else 100, -24)
		var count := 0
		while enemy.health > 0 and count < 40:
			enemy.receive_hit(shot, Vector2.ZERO)
			count += 1
		check(count == (3 if back else 34), "shield %s kill needs %d shots" % ["back" if back else "front", count])
		check(enemy.hurtbox.collision_layer == 0 and enemy.collision_layer == 0, "dead shield disables collision")
		enemy.free()
	var enemy := ShieldEnemy.new()
	enemy.fixed_target = true
	enemy.facing_angle = 0
	world.add_child(enemy)
	enemy.set_physics_process(false)
	var shot := ShotContext.new()
	shot.damage = 11
	shot.source_position = Vector2(100, -24)
	shot.direction = Vector2.LEFT
	shot.knockback = 520.0 / 7
	for index in 7:
		enemy.receive_hit(shot, Vector2.ZERO)
	check(absf(enemy.knockback_velocity.x + 520.0 / 1.5) < 0.01, "seven pellets share one 520/mass impulse")
	enemy.free()
	enemy = ShieldEnemy.new()
	enemy.position = Vector2(120, 0)
	enemy.fixed_target = true
	world.add_child(enemy)
	enemy.set_physics_process(false)
	var wall := make_floor(world, Rect2(80, -60, 2, 70))
	await physics_frame
	await physics_frame
	shot = ShotContext.new()
	shot.source_position = Vector2(40, -24)
	shot.muzzle_position = Vector2(60, -24)
	shot.damage = 24
	var bullet := LabProjectile.new()
	bullet.shot = shot
	world.add_child(bullet)
	bullet.set_physics_process(false)
	bullet.step(1.0 / 60)
	check(bullet.finished and enemy.health == 120, "1400px/s swept projectile hits 2px wall")
	await process_frame

	shot.muzzle_position = Vector2(110, -24)
	bullet = LabProjectile.new()
	bullet.shot = shot
	world.add_child(bullet)
	bullet.set_physics_process(false)
	bullet.step(1.0 / 60)
	check(bullet.finished and enemy.health == 120, "muzzle cannot fire through wall")
	await process_frame
	wall.free()
	enemy.fixed_target = false
	enemy.state = ShieldEnemy.State.RECOVERY
	enemy._sync_weakpoint()
	await physics_frame
	await physics_frame
	shot = ShotContext.new()
	shot.source_position = Vector2(180, -18)
	shot.muzzle_position = Vector2(166, -18)
	shot.direction = Vector2.LEFT
	shot.damage = 24
	bullet = LabProjectile.new()
	bullet.shot = shot
	world.add_child(bullet)
	bullet.set_physics_process(false)
	bullet.step(1.0 / 60)
	if not bullet.finished:
		bullet.step(1.0 / 60)
	check(absf(enemy.health - 60.0) < 0.01, "overlapping weakpoint/body resolves once at 2.5x")
	await process_frame
	world.free()

func test_live_enemy() -> void:
	var world := Node2D.new()
	root.add_child(world)
	make_floor(world, Rect2(-300, 0, 600, 32))
	var p := make_player(world, Vector2(60, 0))
	var enemy := ShieldEnemy.new()
	enemy.position = Vector2(100, 0)
	enemy.target = p
	world.add_child(enemy)
	enemy.set_physics_process(false)
	await physics_frame
	await physics_frame
	enemy._physics_process(1.0 / 60)
	check(enemy.state == ShieldEnemy.State.WINDUP, "live shield starts telegraphed attack in range")
	p.position.x = 140
	var ticks := 0
	while enemy.state == ShieldEnemy.State.WINDUP and ticks < 40:
		await physics_frame
		enemy._physics_process(1.0 / 60)
		ticks += 1
	check(ticks >= 27 and ticks <= 28 and is_equal_approx(enemy.facing_angle, PI), "windup lasts .45s and locks facing after player crosses behind")
	p.position = enemy.position + Vector2(-30, 0)
	ticks = 0
	while enemy.state == ShieldEnemy.State.ATTACK and ticks < 20:
		await physics_frame
		enemy._physics_process(1.0 / 60)
		ticks += 1
	check(p.health == 4 and ticks >= 9 and ticks <= 10, "shield attack deals one HP over .15s active phase")
	check(enemy.weakpoint_open(), "recovery opens weakpoint")
	p.receive_damage(1, Vector2.ZERO)
	check(p.health == 4, "player invulnerability prevents immediate repeated damage")
	p.position.x = enemy.position.x + 60
	ticks = 0
	while enemy.state == ShieldEnemy.State.RECOVERY and ticks < 60:
		await physics_frame
		enemy._physics_process(1.0 / 60)
		ticks += 1
	check(ticks >= 48 and ticks <= 49 and is_equal_approx(enemy.facing_angle, PI), ".8s recovery retains locked facing")
	await physics_frame
	enemy._physics_process(1.0 / 60)
	var turned := absf(angle_difference(PI, enemy.facing_angle))
	check(absf(turned - deg_to_rad(110.0 / 60.0)) < 0.0001, "shield turns at 110 degrees per second")
	for index in 34:
		await physics_frame
		p.step(frame_for(p), 1.0 / 60)
	p.receive_damage(1, Vector2.ZERO)
	check(p.health == 3, "player accepts damage after .55s invulnerability expires")
	world.free()

func test_lab() -> void:
	var lab = load("res://scenes/lab.tscn").instantiate()
	root.add_child(lab)
	await physics_frame
	await physics_frame
	var original_world = lab.world
	for index in 9:
		lab.reset_trial(index % 3)
		check(lab.projectiles.get_child_count() == 0 and lab.player.health == 5 and lab.elapsed == 0 and lab.player.velocity == Vector2.ZERO, "trial reset clears actors/projectiles/metrics %d" % index)
	check(not is_instance_valid(original_world), "previous trial container is destroyed")
	var config: Dictionary = lab.config.duplicate(true)
	config.player.gravity = 1200.0
	config.active_weapon = 1
	config.weapons[1].recoil_impulse = 800.0
	config.weapons[1].fire_rate = 1.0
	config.weapons[1].reload_time = 0.8
	lab.apply_config(config)
	check(lab.player.tuning.gravity == 1200 and lab.player.weapons.current().data.id == &"shotgun", "Apply rebuilds trial with runtime tuning and selected numbered slot")
	check(lab.player.weapons.current().data.recoil_impulse == 800 and lab.player.weapons.current().data.fire_rate == 1 and lab.player.weapons.current().data.reload_time == 0.8, "all three weapon tuning fields reach active runtime")
	check(PlayerTuning.new().gravity == 1500 and WeaponData.baselines()[1].recoil_impulse == 720, "runtime changes leave baselines immutable")
	lab.pause_trial()
	var position: Vector2 = lab.player.position
	var ammo: int = lab.player.weapons.current().ammo
	Input.action_press("fire")
	for index in 6:
		await physics_frame
	check(lab.player.position == position and lab.player.weapons.current().ammo == ammo, "paused simulation freezes physics and ammo")
	lab.resume_trial()
	for index in 6:
		await physics_frame
	check(lab.player.weapons.current().ammo == ammo, "held UI fire input is suppressed on resume")
	Input.action_release("fire")
	lab.restore_baseline()
	check(lab.player.tuning.gravity == 1500 and lab.config.active_weapon == 0, "Restore GDD restores baseline and slot 1")
	var old_player = lab.player
	lab.player.receive_damage(5, Vector2.ZERO)
	await process_frame
	await process_frame
	check(not is_instance_valid(old_player) and lab.player.health == 5, "actual player death rebuilds the current trial")
	lab.free()
	await process_frame

func test_jump() -> void:
	var probe := InputFrame.new()
	var has_jump := false
	for property in probe.get_property_list():
		if property.name == "jump_pressed":
			has_jump = true
	check(has_jump, "InputFrame exposes an independent jump press")
	if not has_jump:
		return
	var heights: Array[float] = []
	for combo in [false, true]:
		var world := Node2D.new()
		root.add_child(world)
		make_floor(world, Rect2(-2000, 0, 4000, 32))
		var p := make_player(world, Vector2.ZERO, 1)
		for tick in 3:
			await physics_frame
			p.step(frame_for(p), 1.0 / 60)
		var f := frame_for(p, Vector2.DOWN)
		f.set("jump_pressed", true)
		f.fire_pressed = combo
		p.step(f, 1.0 / 60)
		check(p.velocity.y < -400, "Space takes off immediately, combo=%s" % combo)
		f.set("jump_pressed", false)
		f.fire_pressed = false
		var rise := 0.0
		for tick in 100:
			await physics_frame
			f.aim_world = p.aim_origin() + Vector2.DOWN * 100
			p.step(f, 1.0 / 60)
			rise = maxf(rise, -p.position.y)
			if tick == 4:
				var vy := p.velocity.y
				f.set("jump_pressed", true)
				p.step(f, 1.0 / 60)
				check(p.velocity.y > vy, "extra airborne press cannot double jump")
				f.set("jump_pressed", false)
		heights.append(rise)
		check(p.is_on_floor(), "jump returns to floor without repeated auto-jumps")
		world.free()
	check(heights[0] > 55 and heights[0] < 80, "base jump rises about 74 px: %s" % heights[0])
	check(heights[1] > heights[0] + 180, "jump and shotgun combine without overwriting recoil: %s" % str(heights))
	for wait_ticks in [3, 10]:
		var world := Node2D.new()
		root.add_child(world)
		var floor_body := make_floor(world, Rect2(-200, 0, 400, 32))
		var p := make_player(world, Vector2.ZERO)
		for tick in 3:
			await physics_frame
			p.step(frame_for(p), 1.0 / 60)
		floor_body.free()
		for tick in wait_ticks:
			await physics_frame
			p.step(frame_for(p), 1.0 / 60)
		var f := frame_for(p)
		f.set("jump_pressed", true)
		p.step(f, 1.0 / 60)
		check((p.velocity.y < -400) == (wait_ticks == 3), "coyote window expires: %d ticks" % wait_ticks)
		world.free()
	var world := Node2D.new()
	root.add_child(world)
	make_floor(world, Rect2(-200, 0, 400, 32))
	var p := make_player(world, Vector2(0, -2))
	p.velocity.y = 180
	await physics_frame
	var f := frame_for(p)
	f.set("jump_pressed", true)
	p.step(f, 1.0 / 60)
	f.set("jump_pressed", false)
	await physics_frame
	p.step(f, 1.0 / 60)
	check(p.velocity.y < -400, "press shortly before landing buffers next jump")
	world.free()
	KeyboardInput.install_actions()
	var adapter := KeyboardInput.new()
	Input.action_release("jump")
	adapter.sample(Vector2.ZERO)
	Input.action_press("jump")
	await physics_frame
	check(adapter.sample(Vector2.ZERO).get("jump_pressed"), "Space action reaches real keyboard adapter")
	adapter.suppress()
	check(not adapter.sample(Vector2.ZERO).get("jump_pressed"), "held jump is suppressed after pause or reset")
	Input.action_release("jump")
