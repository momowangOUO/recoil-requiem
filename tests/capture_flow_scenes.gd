extends SceneTree

func _initialize() -> void: run.call_deferred()

func run() -> void:
	if "--campaign-test" not in OS.get_cmdline_user_args():
		quit(2)
		return
	var app = load("res://scenes/game.tscn").instantiate()
	root.add_child(app)
	var stage = app.stage
	stage.frozen_camera = true
	stage.game.player.set_physics_process(false)
	var views := {"01_arrival":Vector2(1260,1120), "02_stair":Vector2(1638,1024),
		"03_guard":Vector2(2750,1120), "04_mara":Vector2(3870,1408), "05_lift":Vector2(6340,1408),
		"06_cooperation":Vector2(8030,1696), "07_pump":Vector2(7190,2632),
		"08_workshop":Vector2(4830,1408), "09_departure":Vector2(11430,1424),
		"10_celine":Vector2(12080,1424), "11_vira":Vector2(15360,1424), "12_return":Vector2(3870,1408)}
	for label in views:
		if label == "12_return": stage.game.campaign_session.event("vira_dead")
		var at: Vector2 = views[label]
		stage.game.player.position = at
		stage.game.player.update_aim(at + Vector2(100,-10))
		stage.camera_target = CrimsonStage3D.to_stage(at + Vector2(0,-58))
		stage.camera.position = stage.camera_target + Vector3(0.12,1.18,5.2)
		stage.camera.look_at(stage.camera_target)
		stage.residency.update_at(at)
		stage.foreground.call("follow_camera", stage.camera)
		for frame in 6:
			await physics_frame
			await process_frame
		await RenderingServer.frame_post_draw
		app.stage_viewport.get_texture().get_image().save_png("res://artifacts/flow_%s.png" % label)
	app.free()
	quit()
