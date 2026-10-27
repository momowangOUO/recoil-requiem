class_name RecoilLab
extends Node2D

const TITLES := ["RECOIL STEP", "DESCENT", "BLIND SIDE", "CRIMSON MONASTERY"]
@export var visual_slice := false
var campaign_enabled := false
var campaign_session: Node
var connected_map := true
var checkpoint_position := Vector2.ZERO
var checkpoint_index := 0
var fall_anchor := Vector2.ZERO
var fall_surface: Node2D
var fall_recoveries := 0
signal trial_reset
var presentation_host: Node
var projected_aim: Callable
var aim_ui: CanvasLayer
var slice_complete := false
const CAMPAIGN_ROOMS := ["res://scenes/rooms/crimson_environment.tscn", "res://scenes/rooms/bell_gallery.tscn", "res://scenes/rooms/bell_tower.tscn", "res://scenes/rooms/forbidden_archive.tscn", "res://scenes/rooms/rose_court.tscn"]
var journal: Dictionary = {}
var reading := false
const ROOM_NAMES := ["东庭", "钟楼外廊", "警钟塔", "禁书室", "血蔷薇庭院"]
const ROOM_TEXT := {"exit_open": "通路已打开，前往出口", "health_full": "生命已满，血瓶留在这里。", "complete": "转运门已打开 · 本次样段结束", "connected_route": "东庭、外廊、警钟塔、禁书室与庭院连成一张地图，可沿原路返回。\n死亡后回到最近到达的检查点；已开启的机关和已击败的敌人保留。Backspace 重置整张地图。\nJ 查看已发现的线索。", "editor_connected": "打开整张修道院地图"}
var visited_rooms: Dictionary = {}
var completed_rooms: Dictionary = {}
var room_index := 0
var editor_room_path := ""
var enemies: Array[ShieldEnemy] = []
var greybox := false
var config: Dictionary
var definitions: Array
var input_adapter := KeyboardInput.new()
var overlay := LabOverlay.new()
var combat_timer := 0.0
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
var hit_display_time := 0.0
var camera_center := Vector2.ZERO
var shake_time: float = 0
var reset_pending := false
var rng := RandomNumberGenerator.new()
var paused := false
var last_reload := false
var alarm_countdown := 0.0
var reticle: LabReticle

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	KeyboardInput.install_actions()
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--room="):
			editor_room_path = argument.trim_prefix("--room=")
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
	# The player-facing host owns focus pause; its hidden lab must not pause again.
	if presentation_host == null or not presentation_host.has_method("handle_flow_action"):
		get_window().focus_exited.connect(func(): pause_trial())
	if campaign_enabled and visual_slice and editor_room_path.is_empty():
		campaign_session = preload("res://scripts/campaign/campaign_session.gd").new()
		add_child(campaign_session)
		campaign_session.setup(self)
	reset_trial(3 if visual_slice else 0)

static func baseline_config() -> Dictionary:
	var weapons: Array = []
	for definition in WeaponData.baselines():
		weapons.append(definition.to_dict())
	return {"player": PlayerTuning.gdd_baseline().to_dict(), "weapons": weapons, "active_weapon": 0, "measurement": true, "shake": false, "target_mode": false, "turn_speed": 110.0}

static func responsive_config() -> Dictionary:
	var result := baseline_config()
	result.player = PlayerTuning.responsive().to_dict()
	# Current low-jump profile uses stronger weapon recoil; GDD stays recoverable.
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
	combat_timer = 0.0
	if is_instance_valid(overlay) and is_instance_valid(overlay.combat):
		overlay.combat.messages.clear()
		overlay.combat.area = ""
		overlay.combat.quiet = 0.0
	reset_pending = false
	preset = 3 if visual_slice else clampi(index, 0, 2)
	slice_complete = false
	alarm_countdown = 0.0
	hit_display_time = 0.0
	if visual_slice and editor_room_path.is_empty(): visited_rooms[room_index] = true
	get_tree().paused = false
	paused = false
	reading = false
	overlay.hide_story()
	overlay.hide_panel()
	audio.stop_all()
	if is_instance_valid(aim_ui) and presentation_host != null:
		aim_ui.free()
	if is_instance_valid(world):
		world.free()
	enemy = null
	enemies.clear()
	world = Node2D.new()
	world.name = "TrialWorld"
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(world)
	var room_path: String = editor_room_path if not editor_room_path.is_empty() else CAMPAIGN_ROOMS[room_index]
	if visual_slice and connected_map and editor_room_path.is_empty(): room_path = "res://scenes/rooms/connected_monastery.tscn"
	if campaign_session != null: room_path = "res://scenes/rooms/image_monastery.tscn"
	environment = load(room_path).instantiate() if visual_slice else LabEnvironment.new()
	world.add_child(environment)
	environment.build(preset)
	checkpoint_position = environment.spawn
	checkpoint_index = 0
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
	if overlay.combat != null: player.weapons.equipment_result.connect(overlay.combat.result)
	player.input_source = func(): return input_adapter.sample(projected_aim.call() if projected_aim.is_valid() else get_global_mouse_position())
	player.shot_fired.connect(_fire)
	player.died.connect(_request_respawn)
	player.hurt.connect(_player_hurt)
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
	if campaign_session != null:
		campaign_session.bind_world()
	elif visual_slice:
		for marker in environment.enemy_spawns:
			var guard: ShieldEnemy = RifleEnemy.new() if marker.kind == RoomMarker.Kind.RIFLE else ShieldEnemy.new()
			guard.position = marker.position
			guard.fixed_target = config.target_mode
			guard.turn_speed = config.turn_speed
			guard.hit_received.connect(_enemy_hit)
			guard.defeated.connect(_enemy_defeated)
			world.add_child(guard)
			enemies.append(guard)
		enemy = enemies[0] if not enemies.is_empty() else null
		_update_exit()
	elif preset == 2:
		enemy = ShieldEnemy.new()
		enemy.position = Vector2(512, 224) if visual_slice else Vector2(384, 320)
		enemy.target = null if visual_slice else player
		enemy.fixed_target = config.target_mode
		enemy.turn_speed = config.turn_speed
		enemy.hit_received.connect(_enemy_hit)
		enemy.defeated.connect(_enemy_defeated)
		world.add_child(enemy)
		enemies.append(enemy)
	if environment is CrimsonEnvironment:
		environment.stage.add_actor(player)
		if campaign_session == null:
			for guard in enemies:
				environment.stage.add_actor(guard)
		environment.set_greybox(greybox)
	fall_anchor = player.position
	fall_surface = null
	fall_recoveries = 0
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
	overlay.show_notice(environment.objective_hint if visual_slice else hints[preset])
	print("TRIAL %d RESET weapon_slot=%d gravity=%.1f" % [preset + 1, player.weapons.active_slot + 1, player.tuning.gravity])
	trial_reset.emit()

func _request_reset() -> void:
	if not reset_pending:
		reset_pending = true
		reset_trial.call_deferred(preset)

func _request_respawn() -> void:
	if campaign_session != null:
		campaign_session.state.restore_checkpoint()
		_request_reset()
		return
	if not environment is ConnectedMonastery:
		_request_reset()
		return
	if not reset_pending:
		reset_pending = true
		_respawn.call_deferred()

func _respawn() -> void:
	reset_pending = false
	player.melee.reset()
	player.position = checkpoint_position
	player.velocity = Vector2.ZERO
	player.health = 5
	player.invulnerability = 0.55
	player.clear_jump_buffer()
	player.drop_time = 0
	player.hurt_stun = 0
	player.hit_flash = 0
	player.flash_time = 0
	player.coyote_time = 0
	player.air_lift_age = 0
	player.air_lift_started = false
	player.start_y = checkpoint_position.y
	player.max_rise = 0
	player.weapons.configure(definitions, player.weapons.active_slot)
	for projectile in projectiles.get_children(): projectile.free()
	for effect in world.get_children():
		if effect is HurtFX or effect is ImpactFX: effect.free()
	input_adapter.suppress()
	shake_time = 0

func _recover_campaign_fall() -> bool:
	if not environment is ImageMonastery or reset_pending or player.health <= 0: return false
	var space := player.get_world_2d().direct_space_state
	var foot := space.intersect_ray(PhysicsRayQueryParameters2D.create(player.position-Vector2(0,2),player.position+Vector2(0,10),1|1024))
	if player.is_on_floor() and not foot.is_empty():
		var surface: Node = foot.collider.get_parent()
		if surface.get_meta("route_surface",false) and not str(surface.name).begins_with("Luggage"):
			var ends := Vector2(surface.position.x, surface.position.x + (surface.width if surface is PaperPlatform else surface.end_offset.x))
			if player.position.x >= minf(ends.x,ends.y)+12 and player.position.x <= maxf(ends.x,ends.y)-12:
				fall_anchor = player.position
				fall_surface = surface
	if player.velocity.y <= 0 or player.position.y < fall_anchor.y+96: return false
	var below := space.intersect_ray(PhysicsRayQueryParameters2D.create(player.position-Vector2(0,2),Vector2(player.position.x,environment.bounds.end.y+24),1|1024))
	if not below.is_empty(): return false
	if not is_instance_valid(fall_surface): return false
	# A missed local landing preserves combat, ammunition and quest progress.
	player.position = fall_anchor
	player.velocity = Vector2.ZERO
	player.drop_time = 0
	player.set_collision_mask_value(11,true)
	player.clear_jump_buffer()
	player.coyote_time = 0
	player.melee.cancel()
	fall_recoveries += 1
	return true

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
	reading = false
	overlay.hide_story()
	get_tree().paused = false
	input_adapter.suppress()
	overlay.hide_panel()
	reticle.show()
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN

func _input(event: InputEvent) -> void:
	if campaign_session != null and campaign_session.handle_input(event):
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_E:
				if reading: resume_trial()
				elif not paused and visual_slice: interact()
				get_viewport().set_input_as_handled()
			KEY_J:
				if reading: resume_trial()
				elif not paused and visual_slice:
					show_story("调查笔记", "\n\n".join(journal.values()) if not journal.is_empty() else "尚未找到记录。靠近书页标记后按 E 阅读。")
				get_viewport().set_input_as_handled()
			KEY_M:
				if reading: resume_trial()
				elif not paused and visual_slice: show_route()
				get_viewport().set_input_as_handled()
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
			var direction := 1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -1
			if overlay.combat != null and overlay.combat.reverse_wheel: direction = -direction
			input_adapter.wheel_steps.append(direction)

func _physics_process(delta: float) -> void:
	if paused or not is_instance_valid(player):
		return
	elapsed += delta
	combat_timer = maxf(0, combat_timer - delta)
	if overlay.combat != null: input_adapter.view_toggle = overlay.combat.view_toggle
	hit_display_time = maxf(0, hit_display_time - delta)
	if hit_display_time == 0: last_hit = ""
	shake_time = maxf(0, shake_time - delta)
	_recover_campaign_fall()
	_update_camera(delta)
	if player.position.y > environment.bounds.end.y + 96:
		_request_respawn()
	var weapon := player.weapons.current()
	config.active_weapon = player.weapons.active_slot
	if weapon.reloading and not last_reload:
		audio.play("reload")
	last_reload = weapon.reloading
	var hit_text := last_hit
	if campaign_session != null:
		campaign_session.step(delta)
		var nearby: Dictionary = campaign_session.nearest()
		if not nearby.is_empty(): hit_text = "[E] " + str(campaign_session.Data.NAMES.get(nearby.id, "调查 / 操作"))
	if visual_slice and campaign_session == null:
		if environment.alarm_active():
			alarm_countdown -= delta
			if alarm_countdown <= 0:
				audio.play("bell")
				alarm_countdown = 3.2
		for guard in enemies:
			if guard.state != ShieldEnemy.State.DEAD and player.position.distance_to(guard.position) < (520 if guard is RifleEnemy else 180):
				guard.target = player
		if environment.exit_open and player.position.distance_to(environment.exit_position) < 32 and player.is_on_floor() and not slice_complete:
			slice_complete = true
			if editor_room_path.is_empty(): completed_rooms[room_index] = true
			if not environment is ConnectedMonastery and editor_room_path.is_empty() and room_index + 1 < CAMPAIGN_ROOMS.size():
				room_index += 1
				_request_reset()
			else:
				overlay.show_notice(ROOM_TEXT.complete)
		if hit_text.is_empty():
			hit_text = ROOM_TEXT.exit_open if environment.exit_open else environment.progress_text()
		var nearby := nearby_action()
		if nearby != null: hit_text = "[E] " + nearby.title
		if environment is ConnectedMonastery:
			var region := clampi(int(player.position.x / 960), 0, 4)
			visited_rooms[region] = true
			for index in range(checkpoint_index + 1, environment.checkpoints.size()):
				if player.is_on_floor() and player.position.distance_to(environment.checkpoints[index]) < 38:
					checkpoint_position = environment.checkpoints[index]
					checkpoint_index = index
	if preset == 1:
		hit_text = "DROP %.0f PX   TIME %.2f S" % [player.position.y - environment.spawn.y, elapsed]
	var hud_title: String = environment.room_title if visual_slice else TITLES[preset]
	var objective := ""
	if visual_slice and campaign_session == null:
		var done := 0
		var total := 0
		for action in environment.actions:
			if action.required:
				total += 1
				done += int(action.activated)
		objective = CombatHud.COPY.data.objective % [done,total]
	if environment is ConnectedMonastery: hud_title += " · " + ROOM_NAMES[clampi(int(player.position.x / 960), 0, 4)]
	overlay.update_hud({"preset": room_index if visual_slice else preset, "title": hud_title, "health": player.health, "velocity": player.velocity, "height": player.max_rise, "weapon_name": weapon.data.display_name, "weapon_id": weapon.data.id, "per_shell": weapon.data.per_shell, "active_slot": player.weapons.active_slot, "inventory": player.weapons.inventory_snapshot(), "ammo": weapon.ammo, "magazine": weapon.data.magazine_size, "reload_progress": weapon.progress(), "last_hit": hit_text, "time": elapsed, "measurement": config.measurement, "cycle_order": player.weapons.cycle_slots(), "viewing": input_adapter.view_active, "combat": combat_timer > 0, "objective": objective})
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
		_update_exit()
		overlay.show_notice(ROOM_TEXT.exit_open if environment.exit_open else environment.progress_text())
	else:
		overlay.show_notice("AEGIS DOWN / BACKSPACE TO REPLAY")

func _update_exit() -> void:
	if campaign_session != null: return
	if not environment is CrimsonEnvironment: return
	var clear := true
	for guard in enemies:
		if guard.state != ShieldEnemy.State.DEAD: clear = false
	environment.exit_open = environment.objectives_complete() and (clear or not environment.require_clear)
	environment.queue_redraw()

func nearby_action() -> RoomAction:
	if not environment is CrimsonEnvironment or not player.is_on_floor(): return null
	var nearest: RoomAction
	var distance := 38.0
	for action in environment.actions:
		if action.activated and action.kind != RoomAction.Kind.NOTE: continue
		var d := player.position.distance_to(action.position)
		if d >= distance: continue
		var query := PhysicsRayQueryParameters2D.create(player.position + Vector2(0, -18), action.position + Vector2(0, -18), 1)
		if not player.get_world_2d().direct_space_state.intersect_ray(query).is_empty(): continue
		nearest = action
		distance = d
	return nearest

func interact() -> void:
	if paused or reset_pending: return
	var action := nearby_action()
	if action == null: return
	if action.kind == RoomAction.Kind.SUPPLY:
		if player.health >= 5:
			overlay.show_notice(ROOM_TEXT.health_full)
			return
		player.health = mini(5, player.health + 2)
	environment.activate(action)
	_update_exit()
	if action.kind == RoomAction.Kind.SWITCH:
		audio.play("lever")
		if not environment.alarm_active(): audio.stop_key("bell")
	if action.kind == RoomAction.Kind.NOTE:
		journal[action.action_id] = action.title + "\n" + action.description
		show_story(action.title, action.description)
	else:
		overlay.show_notice(action.description if not action.description.is_empty() else "ACTIVATED")

func show_story(title: String, content: String) -> void:
	pause_trial()
	reading = true
	overlay.hide_panel()
	overlay.show_story(title, content)

func show_route() -> void:
	if not editor_room_path.is_empty():
		show_story("地图预览", "当前正在单独预览编辑器地图。\n房间目标：" + environment.objective_hint)
		return
	var lines := PackedStringArray()
	for index in ROOM_NAMES.size():
		var current := clampi(int(player.position.x / 960), 0, 4) if environment is ConnectedMonastery else room_index
		var status := "当前" if index == current else ("已通过" if completed_rooms.has(index) else ("已到达" if visited_rooms.has(index) else "未到达"))
		lines.append("%d  %s · %s" % [index + 1, ROOM_NAMES[index], status])
	lines.append("\n" + ROOM_TEXT.connected_route if environment is ConnectedMonastery else "\n沿东门前进；每间房都是检查点。\n记录与高处支路可选，J 查看已发现的线索。")
	show_story("猩红修道院 · 当前路线", "\n".join(lines))

func _fire(context: ShotContext, data: WeaponData) -> void:
	combat_timer = 3.0
	reticle.shot_time = 0.35
	if is_instance_valid(overlay.combat): overlay.combat.shot_time = 0.35
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

func _player_hurt() -> void:
	combat_timer = 3.0
	_hurt_effect(player.aim_origin(), player.last_hit_direction, false)
	shake_time = 0.07

func _hurt_effect(point: Vector2, direction: Vector2, shield: bool) -> void:
	var effect := HurtFX.new()
	effect.position = point
	effect.direction = direction
	effect.shield = shield
	world.add_child(effect)

func _enemy_hit(result: Dictionary) -> void:
	combat_timer = 3.0
	_hurt_effect(result.point, result.get("direction", Vector2.RIGHT), result.zone == "FRONT")
	last_hit = "%s  %.1f DMG  /  %.1f HP" % [result.zone, result.damage, result.hp]
	hit_display_time = 1.5
	audio.play("weak" if result.zone in ["BACK", "WEAK"] else "hit")

func _impact(point: Vector2, tint: Color) -> void:
	var effect := ImpactFX.new()
	effect.position = point
	effect.tint = tint
	world.add_child(effect)
