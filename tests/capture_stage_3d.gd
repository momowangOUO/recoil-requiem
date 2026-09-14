extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var app = load("res://scenes/game.tscn").instantiate()
	app.campaign_enabled = false # Legacy regression fixture; main F5 uses the campaign.
	root.add_child(app)
	var stage = app.stage
	var game = stage.game
	stage.frozen_camera = true
	game.player.manual_control = true
	game.enemy.set_physics_process(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	for view in ["entry", "combat", "greybox", "angle"]:
		game.player.position = Vector2(80, 352) if view == "entry" else Vector2(438, 224)
		game.player.update_aim(Vector2(600, game.player.position.y - 26))
		game.enemy.position = Vector2(532, 224)
		stage.camera_target = CrimsonStage3D.to_stage(Vector2(170, 292) if view == "entry" else Vector2(490, 222))
		stage.camera.position = stage.camera_target + Vector3(0.32 if view == "angle" else 0, CrimsonStage3D.CAMERA_RISE, CrimsonStage3D.CAMERA_DISTANCE)
		stage.camera.look_at(stage.camera_target)
		stage.set_greybox(view == "greybox")
		game.overlay._notice.hide()
		game.overlay._notice_timer = 0
		for i in 5:
			await physics_frame
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/stage3d_%s.png" % view)
		app.stage_viewport.get_texture().get_image().save_png("res://artifacts/stage3d_%s_world_native.png" % view)
	app.free()
	quit()
