extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/claw")
	var app = load("res://scenes/game.tscn").instantiate()
	app.campaign_enabled = false # Legacy regression fixture; main F5 uses the campaign.
	root.add_child(app)
	var stage: CrimsonStage3D = app.stage
	var game := stage.game
	stage.frozen_camera = true
	game.player.manual_control = true
	for enemy in game.enemies: enemy.set_physics_process(false)
	game.player.position = Vector2(438, 224)
	game.enemy.position = Vector2(479, 224)
	stage.camera_target = CrimsonStage3D.to_stage(Vector2(475, 201))
	stage.camera.position = stage.camera_target + Vector3(0, 1.18, 4.5)
	stage.camera.look_at(stage.camera_target)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	game.overlay._notice.hide()
	game.overlay._notice_timer = 0
	for direction in [1.0, -1.0]:
		game.player.melee.reset()
		game.player.position = Vector2(438 if direction > 0 else 512, 224)
		game.player.velocity = Vector2.ZERO
		game.enemy.health = 120
		game.enemy.facing_angle = PI if direction > 0 else 0
		game.enemy.position = Vector2(479, 224)
		var input := InputFrame.new()
		input.aim_world = game.player.aim_origin() + Vector2(direction * 100, 0)
		for i in 3:
			game.player.step(input, 1.0 / 60)
			await physics_frame
		input.melee_pressed = true
		for i in 25:
			game.player.step(input, 1.0 / 60)
			input.melee_pressed = false
			await physics_frame
			await process_frame
			await RenderingServer.frame_post_draw
			if i in [0, 3, 5, 7, 12, 23]:
				root.get_texture().get_image().save_png("res://artifacts/claw/%s_%02d.png" % ["right" if direction > 0 else "left", i])
				app.stage_viewport.get_texture().get_image().save_png("res://artifacts/claw/%s_%02d_native.png" % ["right" if direction > 0 else "left", i])
	app.free()
	quit()
