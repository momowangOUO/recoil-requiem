extends SceneTree

func _initialize() -> void: run.call_deferred()

func run() -> void:
	var app = load("res://scenes/game.tscn").instantiate()
	app.campaign_enabled = false # Legacy regression fixture; main F5 uses the campaign.
	root.add_child(app)
	var stage: CrimsonStage3D = app.stage
	stage.frozen_camera = true
	stage.game.player.manual_control = true
	for enemy in stage.game.enemies: enemy.set_physics_process(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	for section in 5:
		var x := 480 + section * 960
		var floor_y := 320.0
		for module in stage.game.environment.modules:
			if module.active and x >= module.position.x and x <= module.position.x + module.width:
				floor_y = minf(floor_y, module.position.y)
		stage.game.player.position = Vector2(x, floor_y)
		stage.game.player.set_physics_process(false)
		stage.game.overlay._notice.hide()
		stage.game.overlay._notice_timer = 0
		for distance in [4.8, 7.2]:
			stage.camera_target = CrimsonStage3D.to_stage(Vector2(x, 235))
			stage.camera.position = stage.camera_target + Vector3(0, 1.18, distance)
			stage.camera.look_at(stage.camera_target)
			stage.night.follow_camera(stage.camera.position)
			for frame in 4:
				await physics_frame
				await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://artifacts/environment_%d_%d.png" % [section, int(distance * 10)])
	# Close views of actual attachment points, including the depressed canal floor.
	for point in [Vector2(1440, 400), Vector2(4140, 224), Vector2(4736, 256)]:
		stage.game.player.position = point
		stage.camera_target = CrimsonStage3D.to_stage(point + Vector2(0, -40))
		stage.camera.position = stage.camera_target + Vector3(0, 1.18, 5.8)
		stage.camera.look_at(stage.camera_target)
		for frame in 4:
			await physics_frame
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/decor_contact_%d.png" % int(point.x))
	app.free()
	quit()
