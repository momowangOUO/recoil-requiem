extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var app = load("res://scenes/game.tscn").instantiate()
	app.campaign_enabled = false # Legacy regression fixture; main F5 uses the campaign.
	root.add_child(app)
	var stage: CrimsonStage3D = app.stage
	stage.frozen_camera = true
	stage.game.player.set_physics_process(false)
	for enemy in stage.game.enemies: enemy.set_physics_process(false)
	for wall in stage.scenery.get_node("NearForeground").get_children():
		var point := Vector2((wall.position.x + wall.width * 0.5) * 100, 0)
		for module in stage.game.environment.modules:
			if point.x >= module.position.x and point.x <= module.position.x + module.width:
				point.y = maxf(point.y, module.position.y)
		stage.game.player.position = point
		stage.game.overlay._notice.hide()
		stage.game.overlay._notice_timer = 0
		for distance in [3.8, 4.4, 4.8, 5.2, 6.3, 7.2]:
			stage.camera_target = CrimsonStage3D.to_stage(point + Vector2(0, -minf(52, distance * 10)))
			stage.camera_target.y = maxf(stage.camera_target.y, -3.5)
			stage.camera.position = stage.camera_target + Vector3(0, 1.18, distance)
			stage.camera.look_at(stage.camera_target)
			stage._update_actor_window()
			stage.night.follow_camera(stage.camera.position)
			for frame in 3: await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://artifacts/wall_%s_%d.png" % [wall.name, int(distance * 10)])
	app.free()
	quit()
