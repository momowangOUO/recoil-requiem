extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var app = load("res://scenes/game.tscn").instantiate()
	root.add_child(app)
	var stage: CrimsonStage3D = app.stage
	stage.frozen_camera = true
	stage.game.player.set_physics_process(false)
	for enemy in stage.game.enemies: enemy.set_physics_process(false)
	for frame in 180:
		var t := frame / 179.0
		var jump := sin(clampf((t - 0.3) / 0.4, 0, 1) * PI) * 80
		var point := Vector2(80 + t * 180, 352 - jump)
		stage.game.player.position = point
		stage.camera_target = CrimsonStage3D.to_stage(point + Vector2(0, -52))
		stage.camera.position = stage.camera_target + Vector3(0.16, 1.18, 7.2)
		stage.camera.look_at(stage.camera_target)
		stage._update_actor_window()
		stage.night.follow_camera(stage.camera.position)
		await process_frame
		if frame in [0, 60, 90, 150]:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://artifacts/foreground_motion_%d.png" % frame)
	app.free()
	quit()
