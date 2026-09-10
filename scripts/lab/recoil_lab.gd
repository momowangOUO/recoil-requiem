class_name RecoilLab
extends Node2D

const TITLES := ["RECOIL STEP", "DESCENT", "BLIND SIDE", "CRIMSON MONASTERY"]
@export var visual_slice := false
signal trial_reset
var presentation_host: Node
var projected_aim: Callable
var aim_ui: CanvasLayer
var slice_complete := false
var greybox := false
var config: Dictionary
var definitions: Array
var input_adapter := KeyboardInput.new()
var overlay := LabOverlay.new()
var audio := LabAudio.new()
var camera := Camera2D.new()
var world: Node2D
var environment: LabEnvironment
var projectiles: Node2D
var player: PlayerController
var enemy: ShieldEnemy
var preset: int = 0
var elapsed: float = 0
var last_hit := ""
var camera_center := Vector2.ZERO
var shake_time: float = 0
var reset_pending := false
var rng := RandomNumberGenerator.new()
var paused := false
var last_reload := false
var reticle: LabReticle

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	KeyboardInput.install_actions()
	config = responsive_config()
	if visual_slice:
		config.measurement = false
	overlay.lab_navigation = not visual_slice
	add_child(camera)
	add_child(audio)
	(presentation_host if presentation_host != null else self).add_child(overlay)
	overlay.setup(config)
	overlay.resume_requested.connect(resume_trial)
	overlay.apply_requested.connect(apply_config)
	overlay.baseline_requested.connect(restore_baseline)
	overlay.responsive_requested.connect(restore_responsive)
	overlay.preset_requested.connect(reset_trial)
	overlay.reset_requested.connect(func(): reset_trial(preset))
	get_window().focus_exited.connect(func(): pause_trial())
	reset_trial(3 if visual_slice else 0)

static func baseline_config() -> Dictionary:
	var weapons: Array = []
	for definition in WeaponData.baselines():
		weapons.append(definition.to_dict())
	return {"player": PlayerTuning.gdd_baseline().to_dict(), "weapons": weapons, "active_weapon": 0, "measurement": true, "shake": false, "target_mode": false, "turn_speed": 110.0}

static func responsive_config() -> Dictionary:
	var result := baseline_config()
	result.player = PlayerTuning.responsive().to_dict()
	# Preserve launch heights and SMG slow-fall under the faster gravity profile.
	for i in 3:
		result.weapons[i].recoil_impulse = [450.0, 950.0, 160.0][i]
	return result

func restore_responsive() -> void:
	config = responsive_config()
	reset_trial(preset)
	overlay.show_notice("RESPONSIVE MOVEMENT RESTORED")

func apply_config(values: Dictionary) -> void:
	config = values.duplicate(true)
	var tuning := PlayerTuning.new()
	tuning.apply_dict(config.player)
	config.player = tuning.to_dict()
	if config.measurement:
		config.shake = false
	config.active_weapon = clampi(int(config.get("active_weapon", 0)), 0, WeaponController.SLOT_COUNT - 1)
	reset_trial(preset)
	overlay.show_notice("TUNING APPLIED / NEW TRIAL")

func restore_baseline() -> void:
	config = baseline_config()
	reset_trial(preset)
	overlay.show_notice("GDD BASELINE RESTORED")

func reset_trial(index: int) -> void:
	reset_pending = false
	preset = 3 if visual_slice else clampi(index, 0, 2)
	slice_complete = false
	get_tree().paused = false
	paused = false
	overlay.hide_panel()
	audio.stop_all()
	if is_instance_valid(aim_ui) and presentation_host != null:
		aim_ui.free()
	if is_instance_valid(world):
		world.free()
	enemy = null
	world = Node2D.new()
	world.name = "TrialWorld"
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(world)
	environment = load("res://scenes/rooms/crimson_environment.tscn").instantiate() if visual_slice else LabEnvironment.new()
	world.add_child(environment)
	environment.build(preset)
	projectiles = Node2D.new()
	projectiles.name = "Projectiles"
	world.add_child(projectiles)
	definitions = WeaponData.baselines()
	for i in definitions.size():
		definitions[i].apply_dict(config.weapons[i])
	player = PlayerController.new()
	player.position = environment.spawn
	player.tuning.apply_dict(config.player)
	player.weapons.configure(definitions, int(config.get("active_weapon", 0)))
	player.input_source = func(): return input_adapter.sample(projected_aim.call() if projected_aim.is_valid() else get_global_mouse_position())
	player.shot_fired.connect(_fire)
	player.died.connect(_request_reset)
	player.hurt.connect(func(): overlay.show_notice("HIT / %d HP" % player.health))
	world.add_child(player)
	reticle = LabReticle.new()
	reticle.player = player
	reticle.measurement = config.measurement
	if presentation_host != null and presentation_host.has_method("get_aim_screen"):
		reticle.screen_position_source = presentation_host.get_aim_screen
	aim_ui = CanvasLayer.new()
	aim_ui.name = "AimUI"
	aim_ui.layer = 20
	(presentation_host if presentation_host != null else world).add_child(aim_ui)
	aim_ui.process_mode = Node.PROCESS_MODE_PAUSABLE
	aim_ui.add_child(reticle)
	if preset in [2, 3]:
		enemy = ShieldEnemy.new()
		enemy.position = Vector2(512, 224) if visual_slice else Vector2(384, 320)
		enemy.target = null if visual_slice else player
		enemy.fixed_target = config.target_mode
		enemy.turn_speed = config.turn_speed
		enemy.hit_received.connect(_enemy_hit)
		enemy.defeated.connect(_enemy_defeated)
		world.add_child(enemy)
	if environment is CrimsonEnvironment:
		environment.stage.add_actor(player)
		environment.stage.add_actor(enemy)
		environment.set_greybox(greybox)
	camera_center = player.position + Vector2(0, -50)
	_update_camera(1.0)
	elapsed = 0
	last_hit = ""
	shake_time = 0
	last_reload = false
	rng.seed = 20260908
	input_adapter.suppress()
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
	var hints := ["SPACE JUMP + AIM DOWN / FIRE TO BOOST", "3: HYMN   |   S DROP   |   FIRE DOWN TO SLOW FALL", "JUMP + RECOIL / CROSS BEHIND THE SHIELD", "CLEAR THE GUARD / REACH THE EAST DOOR"]
	overlay.show_notice(hints[preset])
	print("TRIAL %d RESET weapon_slot=%d gravity=%.1f" % [preset + 1, player.weapons.active_slot + 1, player.tuning.gravity])
	trial_reset.emit()

func _request_reset() -> void:
	if not reset_pending:
		reset_pending = true
		reset_trial.call_deferred(preset)

func pause_trial() -> void:
	if paused or not is_instance_valid(player):
		return
	paused = true
	player.clear_jump_buffer()
	get_tree().paused = true
	input_adapter.suppress()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	overlay.show_panel(config)
	reticle.hide()
	queue_redraw()

func resume_trial() -> void:
	paused = false
	get_tree().paused = false
	input_adapter.suppress()
	overlay.hide_panel()
	reticle.show()
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_ESCAPE, KEY_TAB:
				if paused:
					resume_trial()
				else:
					pause_trial()
				get_viewport().set_input_as_handled()
			KEY_F1, KEY_F2, KEY_F3:
				if not visual_slice:
					reset_trial.call_deferred(int(event.physical_keycode - KEY_F1))
				get_viewport().set_input_as_handled()
			KEY_F6:
				if visual_slice:
					greybox = not greybox
					environment.set_greybox(greybox)
					overlay.show_notice("PAPER STAGE / GREYBOX" if greybox else "PAPER STAGE / TEXTURES")
			KEY_BACKSPACE:
				if not paused:
					_request_reset()
			KEY_F11:
				get_window().mode = Window.MODE_WINDOWED if get_window().mode == Window.MODE_EXCLUSIVE_FULLSCREEN else Window.MODE_EXCLUSIVE_FULLSCREEN
	if event is InputEventMouseButton and event.pressed and not paused:
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			input_adapter.wheel_switch = true

func _physics_process(delta: float) -> void:
	if paused or not is_instance_valid(player):
		return
	elapsed += delta
	shake_time = maxf(0, shake_time - delta)
	_update_camera(delta)
	if player.position.y > environment.bounds.end.y + 96:
		_request_reset()
	var weapon := player.weapons.current()
	config.active_weapon = player.weapons.active_slot
	if weapon.reloading and not last_reload:
		audio.play("reload")
	last_reload = weapon.reloading
	var hit_text := last_hit
	if visual_slice:
		if enemy.state != ShieldEnemy.State.DEAD and player.position.distance_to(enemy.position) < 180:
			enemy.target = player
		if enemy.state == ShieldEnemy.State.DEAD and player.position.x > 872 and player.is_on_floor() and not slice_complete:
			slice_complete = true
			overlay.show_notice("ROOM CLEARED / BACKSPACE TO REPLAY")
		if hit_text.is_empty():
			hit_text = "EAST DOOR OPEN" if environment.exit_open else "CLEAR GUARD / EAST DOOR"
	if preset == 1:
		hit_text = "DROP %.0f PX   TIME %.2f S" % [player.position.y - environment.spawn.y, elapsed]
	overlay.update_hud({"preset": preset, "title": TITLES[preset], "health": player.health, "velocity": player.velocity, "height": player.max_rise, "weapon_name": weapon.data.display_name, "weapon_id": weapon.data.id, "per_shell": weapon.data.per_shell, "active_slot": player.weapons.active_slot, "inventory": player.weapons.inventory_snapshot(), "ammo": weapon.ammo, "magazine": weapon.data.magazine_size, "reload_progress": weapon.progress(), "last_hit": hit_text, "time": elapsed, "measurement": config.measurement})
	queue_redraw()

func _update_camera(delta: float) -> void:
	if presentation_host != null:
		camera.enabled = false
		return
	var desired := player.position + Vector2(player.aim_direction.x * PaperStage.LOOK_AHEAD, -50)
	var rect := environment.bounds
	desired.x = clampf(desired.x, rect.position.x + 160, rect.end.x - 160)
	desired.y = clampf(desired.y, rect.position.y + 90, rect.end.y - 90)
	camera_center = camera_center.lerp(desired, 1 - exp(-delta / 0.10))
	camera.position = camera_center.round()
	camera.offset = Vector2.ZERO
	if config.shake and not config.measurement and shake_time > 0:
		camera.offset = Vector2(sin(elapsed * 160), cos(elapsed * 210)).round() * 2
	camera.force_update_scroll()
	if environment is CrimsonEnvironment:
		environment.stage.follow_camera(camera.position)

func _enemy_defeated() -> void:
	if environment is CrimsonEnvironment:
		environment.exit_open = true
		environment.queue_redraw()
		overlay.show_notice("GUARD DOWN / EAST DOOR OPEN")
	else:
		overlay.show_notice("AEGIS DOWN / BACKSPACE TO REPLAY")

func _fire(context: ShotContext, data: WeaponData) -> void:
	audio.play(str(data.id))
	if data.id == &"shotgun":
		shake_time = 0.08
	var spread := data.spread_degrees
	if data.id == &"smg":
		spread = lerpf(4, 7, 1.0 - float(player.weapons.current().ammo) / data.magazine_size)
	for index in data.pellet_count:
		var shot := ShotContext.new()
		shot.source_position = context.source_position
		shot.muzzle_position = context.muzzle_position
		var angle := rng.randf_range(-spread * 0.5, spread * 0.5)
		shot.direction = context.direction.rotated(deg_to_rad(angle))
		shot.damage = context.damage
		shot.knockback = context.knockback
		shot.speed = context.speed
		shot.color = context.color
		var projectile := LabProjectile.new()
		projectile.shot = shot
		projectile.impact.connect(_impact)
		projectiles.add_child(projectile)

func _enemy_hit(result: Dictionary) -> void:
	last_hit = "%s  %.1f DMG  /  %.1f HP" % [result.zone, result.damage, result.hp]
	audio.play("weak" if result.zone in ["BACK", "WEAK"] else "hit")

func _impact(point: Vector2, tint: Color) -> void:
	var effect := ImpactFX.new()
	effect.position = point
	effect.tint = tint
	world.add_child(effect)
