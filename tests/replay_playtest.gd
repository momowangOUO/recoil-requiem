extends SceneTree
## Scripted engine-event replay, not native OS or manual keyboard/mouse input.
## Production KeyboardInput and automatic player physics remain active throughout.

var lab: RecoilLab
var game_viewport: SubViewport
var results: Array = []
var captures: Array = []
var failures := 0
var ticks := 0
var aim := Vector2.DOWN
var fixed_aim := false
var aim_target := Vector2.ZERO

func _initialize() -> void:
	call_deferred("run")

func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func mouse(pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = game_viewport.get_mouse_position()
	Input.parse_input_event(event)

func point_mouse() -> void:
	var target := aim_target if fixed_aim else lab.player.aim_origin() + aim * 100.0
	var event := InputEventMouseMotion.new()
	event.position = lab.get_canvas_transform() * target
	event.global_position = event.position
	# SubViewport event coordinates are independent of the native desktop pointer.
	game_viewport.push_input(event, true)

func frames(count: int) -> void:
	for i in count:
		point_mouse()
		await physics_frame
		await process_frame
		ticks += 1

func check(label: String, passed: bool, data: Dictionary = {}) -> void:
	data.merge({"scenario": label, "passed": passed, "replay_tick": ticks})
	results.append(data)
	if not passed:
		failures += 1
	print(("PASS " if passed else "FAIL ") + label + " " + JSON.stringify(data))

func setup(index: int, initial_weapon: int, at: Vector2) -> void:
	for code in [KEY_A, KEY_D, KEY_W, KEY_S, KEY_R, KEY_Q, KEY_SPACE, KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6]:
		key(code, false)
	mouse(false)
	fixed_aim = false
	aim = Vector2.DOWN
	lab.config.active_weapon = initial_weapon
	lab.config.target_mode = true
	lab.reset_trial(index)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# Fixture setup only: all subsequent movement, recoil and hits use live simulation.
	lab.player.position = at
	lab.player.velocity = Vector2.ZERO
	lab.player.start_y = at.y
	lab.camera_center = at + Vector2(0, -50)
	lab._update_camera(1.0)
	await frames(3)

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	picture.resize(1280, 720, Image.INTERPOLATE_NEAREST)
	var path := "res://artifacts/replay_" + label + ".png"
	var error := picture.save_png(path)
	check("capture_" + label, error == OK, {"path": path})
	captures.append(path)

func run() -> void:
	var original_accumulation := Input.use_accumulated_input
	var original_mouse_mode := Input.mouse_mode
	Input.use_accumulated_input = false
	root.title = "RECOIL REQUIEM Replay QA"
	var container := TextureRect.new()
	container.size = Vector2(320, 180)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(container)
	game_viewport = SubViewport.new()
	game_viewport.size = Vector2i(320, 180)
	game_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(game_viewport)
	container.texture = game_viewport.get_texture()
	lab = load("res://scenes/lab.tscn").instantiate()
	game_viewport.add_child(lab)
	# Keep replay independent of desktop focus without bypassing gameplay input.
	for connection in root.focus_exited.get_connections():
		root.focus_exited.disconnect(connection.callable)
	await setup(0, 1, Vector2(80, 320))
	key(KEY_A, true)
	aim = Vector2.RIGHT
	await frames(8)
	check("A_move_left_mouse_aim_right", lab.player.velocity.x < 0 and lab.player.aim_direction.x > 0.99,
		{"start_feet": [80, 320], "velocity_x": lab.player.velocity.x, "aim_x": lab.player.aim_direction.x})
	key(KEY_A, false)
	await setup(0, 1, Vector2(80, 320))
	mouse(true)
	await frames(1)
	mouse(false)
	await frames(23)
	await capture("shotgun_hop")
	await frames(51)
	check("mouse_down_shotgun_hop", lab.player.max_rise >= 180 and lab.player.max_rise <= 220 and lab.player.weapons.current().ammo == 1,
		{"start_feet": [80, 320], "max_rise_px": lab.player.max_rise, "ammo": lab.player.weapons.current().ammo})
	key(KEY_Q, true)
	await frames(1)
	key(KEY_Q, false)
	check("Q_cycles_slot_2_to_slot_3", lab.player.weapons.current().data.id == &"smg", {"weapon": str(lab.player.weapons.current().data.id)})

	await setup(1, 0, Vector2(300, 280))
	aim = Vector2.RIGHT
	mouse(true)
	await frames(1)
	mouse(false)
	key(KEY_R, true)
	await frames(1)
	key(KEY_R, false)
	var reload_y := lab.player.position.y
	var began_reload := lab.player.weapons.current().reloading
	await frames(30)
	var during_reload := lab.player.weapons.current().reloading
	var fall := lab.player.position.y - reload_y
	await frames(35)
	check("R_reload_during_fall", began_reload and during_reload and fall > 100 and lab.player.weapons.current().ammo == 6,
		{"start_feet": [300, 280], "fall_first_half_second_px": fall, "ammo_after_reload": lab.player.weapons.current().ammo})

	var descent: Array = []
	for firing in [false, true]:
		await setup(1, 2, Vector2(300, 280))
		var start := lab.player.position.y
		mouse(firing)
		await frames(60)
		if firing:
			await capture("smg_descent")
		await frames(60)
		mouse(false)
		descent.append({"firing": firing, "drop_px": lab.player.position.y - start, "ammo": lab.player.weapons.current().ammo})
	check("SMG_mouse_down_120_ticks", descent[1].drop_px > 0 and descent[1].drop_px < descent[0].drop_px * 0.6 and descent[1].ammo <= 1,
		{"start_feet": [300, 280], "duration_seconds": 2.0, "trials": descent})

	await setup(0, 1, Vector2(480, 320))
	key(KEY_D, true)
	await frames(8)
	aim = Vector2.DOWN
	mouse(true)
	await frames(1)
	mouse(false)
	await frames(28)
	await capture("gap_crossing")
	await frames(33)
	key(KEY_D, false)
	check("160px_gap_D_and_shotgun", lab.player.position.x >= 681 and lab.player.is_on_floor() and absf(lab.player.position.y - 320) < 0.2,
		{"start_feet": [480, 320], "gap_world_x": [512, 672], "end_feet": [lab.player.position.x, lab.player.position.y]})

	var damage: Array = []
	for back in [false, true]:
		await setup(2, 0, Vector2(490 if back else 280, 320))
		fixed_aim = true
		aim_target = lab.enemy.position + Vector2(0, -26)
		await frames(1)
		mouse(true)
		await frames(1)
		mouse(false)
		await frames(12)
		damage.append(120.0 - lab.enemy.health)
	check("directional_projectile_front_vs_back", absf(damage[0] - 3.6) < 0.01 and absf(damage[1] - 43.2) < 0.01,
		{"target_mode": true, "enemy_feet": [384, 320], "enemy_facing": "left", "player_front_feet": [280, 320], "player_back_feet": [490, 320], "damage_front_back": damage})
	await setup(0, 0, Vector2(80, 320))
	aim = Vector2.RIGHT
	key(KEY_SPACE, true)
	await frames(15)
	await capture("space_jump")
	await frames(65)
	check("Space_jump_hold_does_not_repeat", lab.player.max_rise >= 40 and lab.player.max_rise <= 55 and lab.player.is_on_floor(), {"rise_px": lab.player.max_rise})
	key(KEY_SPACE, false)
	await setup(0, 1, Vector2(80, 320))
	key(KEY_SPACE, true)
	mouse(true)
	await frames(1)
	key(KEY_SPACE, false)
	mouse(false)
	await frames(30)
	await capture("jump_recoil_combo")
	await frames(80)
	check("Space_plus_shotgun_controlled_lift", lab.player.max_rise > 90 and lab.player.max_rise < 190 and lab.player.weapons.current().ammo == 1, {"rise_px": lab.player.max_rise})
	await setup(0, 0, Vector2(80, 320))
	aim = Vector2.RIGHT
	mouse(true)
	await frames(1)
	mouse(false)
	key(KEY_R, true)
	await frames(1)
	key(KEY_R, false)
	await frames(5)
	await capture("reload_early")
	await frames(26)
	await capture("reload_middle")
	await frames(25)
	await capture("reload_late")
	await frames(10)
	check("reload_feedback_completes_with_weapon", lab.player.weapons.current().progress() < 0 and "READY" in lab.overlay._reload_status.text, {"ammo": lab.player.weapons.current().ammo})
	await setup(0, 2, Vector2(720, 320))
	aim = Vector2.RIGHT
	key(KEY_D, true)
	await frames(10)
	mouse(true)
	await frames(24)
	await capture("run_fire_grip")
	check("run_while_firing_retains_forward_control", lab.player.velocity.x > 0 and lab.player.is_on_floor(), {"vx": lab.player.velocity.x})
	key(KEY_D, false)
	mouse(false)
	await frames(5)
	check("release_run_stops_feet_and_motion", absf(lab.player.velocity.x) < 1 and lab.player.visual.pose == "idle", {"vx": lab.player.velocity.x})
	await setup(0, 0, Vector2(800, 320))
	aim = Vector2.RIGHT
	key(KEY_A, true)
	await frames(12)
	await capture("backpedal")
	check("backpedal_animation_runs_in_reverse", lab.player.velocity.x < 0 and lab.player.facing > 0 and lab.player.visual.animation_time < 0)
	key(KEY_A, false)
	await setup(0, 0, Vector2(720, 320))
	key(KEY_3, true)
	await frames(1)
	key(KEY_3, false)
	check("number_3_selects_SMG", lab.player.weapons.current().data.id == &"smg")
	aim = Vector2.RIGHT
	mouse(true)
	await frames(7)
	mouse(false)
	var smg_ammo := lab.player.weapons.current().ammo
	key(KEY_1, true)
	await frames(1)
	key(KEY_1, false)
	check("number_1_selects_revolver", lab.player.weapons.current().data.id == &"revolver")
	key(KEY_3, true)
	await frames(1)
	key(KEY_3, false)
	check("number_switch_preserves_SMG_ammo", lab.player.weapons.current().data.id == &"smg" and lab.player.weapons.current().ammo == smg_ammo, {"smg_ammo": smg_ammo})
	key(KEY_6, true)
	await frames(1)
	key(KEY_6, false)
	check("empty_number_6_keeps_current_weapon", lab.player.weapons.current().data.id == &"smg")
	await capture("number_weapon_switch")
	key(KEY_Q, true)
	await frames(1)
	key(KEY_Q, false)
	check("Q_cycles_slot_3_to_slot_1", lab.player.weapons.current().data.id == &"revolver")
	key(KEY_Q, true)
	await frames(1)
	key(KEY_Q, false)
	check("Q_cycles_slot_1_to_slot_2", lab.player.weapons.current().data.id == &"shotgun")
	var summary := {"method": "scripted_event_replay", "native_or_manual_input": false,
		"event_route": "Input.parse_input_event for InputEventKey (physical and logical codes) and InputEventMouseButton; rendered SubViewport.push_input(local=true) for InputEventMouseMotion",
		"physics": "production KeyboardInput adapter and automatic 60 Hz player physics", "display_server": DisplayServer.get_name(),
		"fixture_notes": "Actual lab scene in a standalone 320x180 SubViewport displayed through a TextureRect to isolate injected cursor coordinates from native desktop pointer. Each scenario resets preset and sets reported starting feet position with zero velocity, then settles for three frames. Fixed-target mode isolates directional damage. Window focus pause callback disconnected; mouse mode visible for replay. No direct InputFrame, player.step or receive_hit calls.",
		"checks": results, "failures": failures, "captures": captures}
	var filename := "res://artifacts/replay_headless.json" if DisplayServer.get_name() == "headless" else "res://artifacts/replay_results.json"
	var file := FileAccess.open(filename, FileAccess.WRITE)
	file.store_string(JSON.stringify(summary, "\t") + "\n")
	file.close()
	print("REPLAY RESULT: %d checks, %d failures" % [results.size(), failures])
	for code in [KEY_A, KEY_D, KEY_W, KEY_S, KEY_R, KEY_Q, KEY_SPACE, KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6]:
		key(code, false)
	mouse(false)
	Input.flush_buffered_events()
	Input.use_accumulated_input = original_accumulation
	Input.mouse_mode = original_mouse_mode
	lab.audio.stop_all()
	for voice in lab.audio.voices:
		voice.stream = null
	lab.audio.sounds.clear()
	container.texture = null
	container.free()
	game_viewport.free()
	lab = null
	game_viewport = null
	# Headless fixed-fps simulation outruns the real audio thread. Give stopped
	# playback objects one bounded wall-clock drain before engine shutdown.
	var drain_until := Time.get_ticks_msec() + 250
	while Time.get_ticks_msec() < drain_until:
		await process_frame
	quit(1 if failures else 0)
