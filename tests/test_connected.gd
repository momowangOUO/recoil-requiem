extends SceneTree
var failures := 0
var checks := 0

func _initialize() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func frames(count: int) -> void:
	for i in count:
		await physics_frame
		await process_frame

func run() -> void:
	var source = load("res://scenes/rooms/connected_monastery.tscn").instantiate()
	var errors = preload("res://addons/recoil_map_editor/room_validator.gd").validate(source)
	check(errors.is_empty(), "Composed map editor validation: " + str(errors))
	source.free()
	var app = load("res://scenes/game.tscn").instantiate()
	root.add_child(app)
	var stage: CrimsonStage3D = app.stage
	var game := stage.game
	game.player.manual_control = true
	for enemy in game.enemies: enemy.set_physics_process(false)
	await frames(3)
	check(game.environment is ConnectedMonastery and game.environment.bounds.size.x == 4800, "Main scene is one 4800px room")
	check(game.environment.visual_sections.size() == 5 and game.enemies.size() == 8, "All sections and enemy encounters coexist")
	var world_id := game.world.get_instance_id()
	var player_id := game.player.get_instance_id()
	game.player.health = 3
	game.player.weapons.current().ammo = 2
	# Cross the four former map boundaries in both directions with the real body.
	for seam in [960.0, 1920.0, 2880.0, 3840.0]:
		for direction in [1.0, -1.0]:
			game.player.position = Vector2(seam - direction * 25, -50)
			game.player.velocity = Vector2(direction * 180, 0)
			for i in 24:
				var input := InputFrame.new()
				input.move.x = direction
				input.aim_world = game.player.aim_origin() + Vector2(100, 0)
				game.player.step(input, 1.0 / 60)
				await physics_frame
			check((game.player.position.x - seam) * direction > 0, "No old room wall at " + str(seam))
			check(game.world.get_instance_id() == world_id and game.player.get_instance_id() == player_id, "Crossing must preserve world and player identity")
			check(game.player.health == 3 and game.player.weapons.current().ammo == 2, "Crossing does not heal or grant ammo")
	# Check the physical walking/jumping route, not just absence of old walls.
	for route in [[Vector2(910, 352), Vector2(1010, 352)], [Vector2(1870, 352), Vector2(1970, 352)], [Vector2(2820, 192), Vector2(3100, 320)], [Vector2(3730, 352), Vector2(3890, 320)]]:
		for reverse in [false, true]:
			var start: Vector2 = route[1] if reverse else route[0]
			var finish: Vector2 = route[0] if reverse else route[1]
			game.player.position = start
			game.player.velocity = Vector2.ZERO
			var direction := signf(finish.x - start.x)
			for i in 240:
				var input := InputFrame.new()
				input.move.x = direction
				input.jump_pressed = game.player.is_on_floor()
				input.aim_world = game.player.aim_origin() + Vector2(100, 0)
				game.player.step(input, 1.0 / 60)
				await physics_frame
				if (game.player.position.x - finish.x) * direction >= 0: break
			check((game.player.position.x - finish.x) * direction >= 0, "Traversable connector %s to %s, stopped at %s" % [start, finish, game.player.position])
	for x in [300.0, 1600.0, 3100.0, 4500.0]:
		stage.camera_target = CrimsonStage3D.to_stage(Vector2(x, 250))
		stage.camera.position = stage.camera_target + Vector3(0, 1.18, 4.8)
		stage.camera.look_at(stage.camera_target)
		stage._update_actor_window()
		var point := Vector2(x, 250)
		var pixel := stage.simulation.canvas_transform * point
		var rendered := stage.actors.position + Vector3((pixel.x - 960) * 0.005, -(pixel.y - 544) * 0.005, 0)
		check(rendered.distance_to(CrimsonStage3D.to_stage(point)) < 0.001, "Rolling actor card aligns at " + str(x))
		check(stage.screen_to_world(stage.camera.unproject_position(rendered)).distance_to(point) < 0.02, "Aim remains accurate throughout full map")
	var action: RoomAction = game.environment.actions[0]
	game.environment.activate(action)
	game.checkpoint_position = Vector2(3232, 288)
	game.checkpoint_index = 3
	game.player.health = 0
	game._request_respawn()
	await frames(2)
	check(game.world.get_instance_id() == world_id and action.activated, "Checkpoint death retains world objectives")
	check(game.player.position == game.checkpoint_position and game.player.velocity == Vector2.ZERO and game.player.health == 5, "Death respawns with clean controller at checkpoint")
	game.reset_trial(3)
	game.player.manual_control = true
	check(game.world.get_instance_id() != world_id and game.checkpoint_index == 0 and game.projectiles.get_child_count() == 0, "Manual reset rebuilds the whole map cleanly")
	check(not game.environment.objectives_complete(), "Reset clears all required objectives")
	app.free()
	print("CONNECTED STAGE RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
