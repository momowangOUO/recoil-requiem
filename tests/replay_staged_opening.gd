extends SceneTree
## Bounded engine-input replay. No teleports, state edits, invulnerability or simulated victory.
var app: Control
var game: RecoilLab
var held := {}
var firing := false
var shots := 0
var deaths := 0
var resets := 0
var max_x := 0.0
var min_health := 5
var stagnant := 0
var last_position := Vector2.ZERO
var reached_vira := false
var frames := 0
var render_samples := {}
func _initialize() -> void: run.call_deferred()
func key(code: Key, down: bool) -> void:
	if held.get(code,false) == down: return
	held[code] = down
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = down
	Input.parse_input_event(event)
func mouse(down: bool) -> void:
	if firing == down: return
	firing = down
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = down
	event.position = app.mouse_screen
	Input.parse_input_event(event)
func release() -> void:
	for code in held.keys(): key(code,false)
	mouse(false)
func bind() -> void:
	resets += 1
	game.player.shot_fired.connect(func(_a,_b): shots += 1)
	game.player.died.connect(func(): deaths += 1)
func run() -> void:
	root.size = Vector2i(1280,720)
	app = load("res://scenes/game.tscn").instantiate()
	root.add_child(app)
	game = app.stage.game
	game.trial_reset.connect(bind)
	bind()
	for i in 12: await process_frame
	app.show_title()
	app.handle_flow_action("begin")
	var session = game.campaign_session
	for frame in 5400:
		frames = frame + 1
		var player = game.player
		if app.chapter_staging.active():
			release() # Let every introduction play in full, including arrival.
		elif session.ui.is_panel_open():
			release()
			key(KEY_E, frame % 60 == 0)
		elif game.paused:
			release()
			# A desktop focus loss can pause the native window during recording.
			# Use the same Esc menu/resume path as the player, never edit pause state.
			key(KEY_ESCAPE,frame % 60 == 0)
		else:
			key(KEY_ESCAPE,false)
			key(KEY_E,false)
			var target := "mara" if not session.has("met_mara") else "vira"
			var nearby: Dictionary = session.nearest()
			if nearby.get("id","") == target:
				release()
				key(KEY_E,frame % 30 == 0)
			else:
				var target_x: float = session.npc_actors[target].position.x
				key(KEY_D,player.position.x < target_x - 16)
				key(KEY_A,player.position.x > target_x + 16)
				var aim: Vector2 = player.aim_origin() + Vector2(180,0)
				var distance := 280.0
				var hostile := false
				for enemy in game.enemies:
					var d: float = enemy.position.distance_to(player.position)
					if enemy.state != ShieldEnemy.State.DEAD and d < distance:
						distance = d
						aim = enemy.position + Vector2(0,-24)
						hostile = true
				var motion := InputEventMouseMotion.new()
				motion.position = app.stage.camera.unproject_position(CrimsonStage3D.to_stage(aim)) / 2
				Input.parse_input_event(motion)
				mouse(hostile and frame % 24 == 0)
				key(KEY_V,hostile and distance < 75 and frame % 70 == 0)
				key(KEY_SPACE,(hostile and distance < 120 or stagnant > 90) and frame % 60 < 4)
				key(KEY_R,hostile and player.weapons.current().ammo == 0 and frame % 60 == 0)
			if player.position.distance_to(last_position) < 0.5: stagnant += 1
			else: stagnant = 0
			last_position = player.position
		max_x = maxf(max_x,player.position.x)
		min_health = mini(min_health,player.health)
		if frame % 600 == 0:
			print("STAGED OPENING frame=%d position=%s hp=%d mara=%s vira=%s cue=%s" % [frame,player.position,player.health,session.has("met_mara"),session.has("met_vira"),app.chapter_staging.current.get("id","")])
		if session.has("heard_mon.vira.luggage") and not session.ui.is_panel_open() and not app.chapter_staging.active():
			reached_vira = true
			break
		if deaths >= 3 or stagnant > 600: break
		await physics_frame
		await process_frame
		if DisplayServer.get_name() != "headless":
			# Movie output must remain live if the desktop occludes the game window.
			RenderingServer.force_draw(false,1.0/60)
			if frame % 600 == 0:
				var pixels := root.get_texture().get_image()
				render_samples[hash(pixels.get_data())] = true
	release()
	print("STAGED OPENING REPLAY RESULT: actual engine input; frames=%d shots=%d deaths=%d resets=%d max_x=%.1f min_health=%d arrival=%s mara=%s vira_dialogue_finished=%s final_position=%s" % [frames,shots,deaths,resets,max_x,min_health,session.has("stage_arrival"),session.has("met_mara"),reached_vira,game.player.position])
	app.free()
	var rendered := DisplayServer.get_name() == "headless" or render_samples.size() >= 3
	print("OPENING RENDER CHECK: distinct sampled frames=%d; verified=%s" % [render_samples.size(),rendered])
	quit(0 if reached_vira and rendered else 1)
