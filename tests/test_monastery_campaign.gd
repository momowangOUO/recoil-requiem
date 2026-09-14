extends SceneTree
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error(label)
func run() -> void:
	if "--campaign-render" in OS.get_cmdline_user_args():
		await render_campaign()
		return
	check(ResourceLoader.exists("res://scenes/rooms/monastery_campaign.tscn"), "Campaign scene exists")
	if failures:
		quit(1)
		return
	var env = load("res://scenes/rooms/monastery_campaign.tscn").instantiate()
	root.add_child(env)
	env.build(0)
	check(env.space_bounds.size() == 16, "Sixteen authored space bounds")
	check(env.bounds.size.x >= 12000 and env.bounds.size.y >= 1600, "Expanded layered world")
	check(env.checkpoints.size() >= 5, "Checkpoint coverage")
	var visited := {"mon_01": true}
	for iteration in 16:
		for link in env.connections:
			if not link.gate_id.is_empty(): continue
			if visited.has(link.from): visited[link.to] = true
			if visited.has(link.to): visited[link.from] = true
	check(visited.size() == 16, "All sixteen spaces connected without optional shortcuts")
	var encounters := {}
	for marker in env.enemy_spawns:
		encounters[marker.get_meta("encounter_id")] = true
	check(encounters.size() == 16, "Sixteen encounter groups")
	for id in ["gate_entry", "gate_west", "gate_east", "gate_return", "gate_departure"]:
		check(env.gates.has(id), "Physical gate " + id)
		env.set_gate_state(id, true)
		check(not env.gates[id].active, "Open gate removes collision " + id)
		env.set_gate_state(id, false)
		check(env.gates[id].active, "Closed gate restores collision " + id)
	for checkpoint in env.checkpoints:
		check(env.space_at(checkpoint.position) == checkpoint.space_id, "Checkpoint belongs to named space")
	for id in env.gates: env.set_gate_state(id, true)
	for shortcut in env.shortcut_points:
		check(env.shortcut_destination(shortcut.from) == shortcut.to, "Freight shortcut outbound " + shortcut.gate_id)
		check(env.shortcut_destination(shortcut.to) == shortcut.from, "Freight shortcut return " + shortcut.gate_id)
		env.set_gate_state(shortcut.gate_id, false)
		check(env.shortcut_destination(shortcut.from) == Vector2.INF, "Locked shortcut unavailable " + shortcut.gate_id)
		env.set_gate_state(shortcut.gate_id, true)
	var player := PlayerController.new()
	player.manual_control = true
	player.tuning = PlayerTuning.responsive()
	player.weapons.configure(WeaponData.baselines(), 0)
	root.add_child(player)
	for ramp in [Vector2(800, 1840), Vector2(4400, 1840), Vector2(8000, 1840), Vector2(2400, 1120), Vector2(6000, 1120), Vector2(9600, 1120)]:
		player.position = ramp + Vector2(-30, -2)
		player.velocity = Vector2.ZERO
		for tick in 900:
			await physics_frame
			var input := InputFrame.new()
			input.move.x = 1
			input.jump_pressed = player.is_on_floor()
			input.aim_world = player.aim_origin() + Vector2.RIGHT * 100
			player.step(input, 1.0 / 60)
			if player.position.x > ramp.x + 1450: break
		check(player.position.x > ramp.x + 1450 and player.position.y < ramp.y - 650, "Real controller ascends stair " + str(ramp) + " ended " + str(player.position))
	for route in [Vector3(1800, 11800, 400), Vector3(11800, 1800, 400), Vector3(100, 11900, 1120), Vector3(11900, 100, 1120), Vector3(500, 11800, 1840), Vector3(11800, 500, 1840)]:
		player.position = Vector2(route.x, route.z - 2)
		player.velocity = Vector2.ZERO
		var direction := signf(route.y - route.x)
		for tick in 5000:
			await physics_frame
			var input := InputFrame.new()
			input.move.x = direction
			input.jump_pressed = player.is_on_floor() and route.z == 1840
			input.aim_world = player.aim_origin() + Vector2.RIGHT * 100
			player.step(input, 1.0 / 60)
			if (player.position.x - route.y) * direction >= 0: break
		check((player.position.x - route.y) * direction >= 0, "Real controller gallery/recovery traversal " + str(route) + " ended " + str(player.position))
	env.set_gate_state("gate_departure", false)
	player.position = Vector2(11000, 398)
	player.velocity = Vector2.ZERO
	for tick in 90:
		await physics_frame
		var input := InputFrame.new()
		input.move.x = 1
		input.jump_pressed = player.is_on_floor()
		input.aim_world = player.aim_origin() + Vector2.RIGHT * 100
		player.step(input, 1.0 / 60)
	check(player.position.x < 11040, "Departure gate blocks the complete body before the chapel")
	env.set_gate_state("gate_departure", true)
	for tick in 90:
		await physics_frame
		var input := InputFrame.new()
		input.move.x = 1
		input.aim_world = player.aim_origin() + Vector2.RIGHT * 100
		player.step(input, 1.0 / 60)
	check(player.position.x > 11080, "Departure gate permits passage after opening")
	player.position = Vector2(11720, 1118)
	player.velocity = Vector2.ZERO
	for tick in 1400:
		await physics_frame
		var input := InputFrame.new()
		input.jump_pressed = player.is_on_floor()
		input.aim_world = player.aim_origin() + Vector2.RIGHT * 100
		player.step(input, 1.0 / 60)
		if player.position.y <= 400: break
	check(player.position.y <= 400, "Rear maintenance shaft returns to chapel without ammunition")
	for tick in 500:
		await physics_frame
		var input := InputFrame.new()
		input.drop_pressed = player.is_on_floor()
		input.aim_world = player.aim_origin() + Vector2.RIGHT * 100
		player.step(input, 1.0 / 60)
		if player.position.y >= 1119: break
	check(player.position.y >= 1119 and player.position.y <= 1121, "Rear maintenance shaft descends to mon_16 recovery road")
	player.queue_free()
	print("STAGE RESULT: monastery campaign failures=%d" % failures)
	env.queue_free()
	quit(1 if failures else 0)

func render_campaign() -> void:
	var app = load("res://scenes/game.tscn").instantiate()
	root.add_child(app)
	var stage: CrimsonStage3D = app.stage
	var game = stage.game
	game.campaign_session.autosave = false
	# Automated render windows can lose OS focus to another fixture.
	# Production focus handling is retained; only this isolated renderer disconnects it.
	for connection in game.get_window().focus_exited.get_connections():
		if connection.callable.get_object() == game:
			game.get_window().focus_exited.disconnect(connection.callable)
	game.set_physics_process(false) # Render fixture isolates camera from combat activation.
	check(game.environment.get("campaign") == true, "Main scene selects campaign")
	game.player.manual_control = true
	stage._room_reset()
	for enemy in game.enemies: enemy.set_physics_process(false)
	for sample in [Vector3(3500, 1120, 1), Vector3(8400, 400, 2), Vector3(7200, 1840, 3)]:
		game.player.position = Vector2(sample.x, sample.y)
		game.player.velocity = Vector2.ZERO
		stage.camera_target = CrimsonStage3D.to_stage(game.player.position + Vector2(0, -56))
		for weapon_index in 3:
			game.player.weapons.select_weapon(weapon_index)
			check(game.player.weapons.active_slot == weapon_index, "Render fixture selects numbered weapon")
			for far_view in [false, true]:
				app.mouse_screen = Vector2(320, 180) if far_view else Vector2(160, 90)
				stage._update_camera(10.0)
				for tick in 60:
					app.mouse_screen = Vector2(320, 180) if far_view else Vector2(160, 90)
					await physics_frame
					game.player.visual.update_pose(1.0 / 60)
					await process_frame
				check(absf(stage.actors.position.y + (sample.y - 56) * CrimsonStage3D.PIXEL) < 0.1, "Actor crop follows campaign layer")
				print("CAMERA layer=",sample.z," gun=",weapon_index," far=",far_view," distance=",stage.camera_distance," pointer=",app.mouse_screen," paused=",game.paused)
				check(absf(stage.camera_distance - (stage.camera_profile().far if far_view else stage.camera_profile().near)) < 0.05, "Weapon camera reaches requested dolly distance")
				await RenderingServer.frame_post_draw
				app.stage_viewport.get_texture().get_image().save_png("res://artifacts/monastery_layer_%d_weapon_%d_%s.png" % [int(sample.z), weapon_index, "far" if far_view else "near"])
	print("STAGE RESULT: monastery campaign render failures=%d" % failures)
	app.queue_free()
	quit(1 if failures else 0)

