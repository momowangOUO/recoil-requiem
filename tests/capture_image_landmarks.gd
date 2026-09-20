extends SceneTree
## Review-only camera positions; this never changes the game's camera profile.

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var tag := "after"
	if "--before" in OS.get_cmdline_user_args(): tag = "before"
	var app = load("res://scenes/game.tscn").instantiate()
	root.add_child(app)
	var stage = app.stage
	stage.frozen_camera = true
	stage.residency_enabled = false
	stage.residency.clear()
	stage.game.set_physics_process(false)
	stage.game.player.set_physics_process(false)
	for enemy in stage.game.enemies: enemy.set_physics_process(false)
	app.stage_viewport.size = Vector2i(2048, 768)
	stage.camera.far = 400.0
	stage.camera.fov = 15.0
	var views := {
		"overview": {"at": Vector2(8192, 752), "distance": 242.0},
		"bell": {"at": Vector2(8200, -320), "distance": 72.0},
		"hall": {"at": Vector2(14360, -80), "distance": 72.0},
		"gatehouse": {"at": Vector2(2300, -80), "distance": 58.0}
	}
	for label in views:
		var view: Dictionary = views[label]
		stage.camera_target = CrimsonStage3D.to_stage(view.at)
		stage.camera.position = stage.camera_target + Vector3(0, 1.0, view.distance)
		stage.camera.look_at(stage.camera_target)
		for i in 4:
			await physics_frame
			await process_frame
		await RenderingServer.frame_post_draw
		app.stage_viewport.get_texture().get_image().save_png("res://artifacts/image_landmarks_%s_%s.png" % [tag, label])
	app.free()
	quit()
