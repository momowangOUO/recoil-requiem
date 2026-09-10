extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	for i in count:
		await physics_frame
		await process_frame

func capture(name: String) -> void:
	await frames(6)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/" + name + ".png")

func run() -> void:
	var app = load("res://scenes/game.tscn").instantiate()
	root.add_child(app)
	var stage: CrimsonStage3D = app.stage
	var game := stage.game
	game.connected_map = false
	for index in [2, 3, 4]:
		game.room_index = index
		game.reset_trial(3)
		game.player.manual_control = true
		for guard in game.enemies: guard.set_physics_process(false)
		stage.frozen_camera = true
		stage.camera_target = CrimsonStage3D.to_stage(Vector2(480, 235))
		stage.camera.position = stage.camera_target + Vector3(0.25, 1.6, 13.5)
		stage.camera.look_at(stage.camera_target)
		await capture("continuation_%d_overview" % index)
		var target: Vector2 = [Vector2(708, 176), Vector2(352, 288), Vector2(352, 224)][index - 2]
		game.player.position = target
		game.player.update_aim(target + Vector2(100, -26))
		var input := InputFrame.new()
		input.aim_world = target + Vector2(100, -26)
		game.player.step(input, 1.0 / 60)
		stage.camera_target = CrimsonStage3D.to_stage(target + Vector2(0, -55))
		stage.camera.position = stage.camera_target + Vector3(0.12, 1.18, 5.5)
		stage.camera.look_at(stage.camera_target)
		await capture("continuation_%d_detail" % index)
		if index == 3:
			game.show_story("被涂改的转运名单", game.environment.actions[0].description)
			await capture("continuation_record")
			game.resume_trial()
		else:
			for action in game.environment.actions:
				if action.required: game.environment.activate(action)
			game._update_exit()
			await capture("continuation_%d_open" % index)
	game.room_index = 0
	game.reset_trial(3)
	game.player.manual_control = true
	for guard in game.enemies: guard.set_physics_process(false)
	stage.camera_target = CrimsonStage3D.to_stage(Vector2(375, 235))
	stage.camera.position = stage.camera_target + Vector3(0.22, 1.18, 7.2)
	stage.camera.look_at(stage.camera_target)
	await capture("stone_and_open_grating")
	app.free()
	quit()
