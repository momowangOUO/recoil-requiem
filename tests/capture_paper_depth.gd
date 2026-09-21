extends SceneTree
## Close GPU review of the wall opening, inner reveal, glass and sill layers.

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var app = load("res://scenes/game.tscn").instantiate()
	root.add_child(app)
	var stage: CrimsonStage3D = app.stage
	stage.frozen_camera = true
	stage.foreground.visible = false
	stage.game.player.set_physics_process(false)
	var views := {
		"gatehouse": {"at": Vector2(2200, 1120), "prefix": "B01LayeredWindow"},
		"gallery": {"at": Vector2(5200, 688), "prefix": "GalleryLayeredWindow"},
		"hall": {"at": Vector2(14300, 1424), "prefix": "B12LayeredWindow"},
	}
	for label in views:
		var view: Dictionary = views[label]
		stage.camera_target = CrimsonStage3D.to_stage(view.at)
		stage.residency.update_at(view.at)
		for frame in 3:
			await physics_frame
			await process_frame
		var panes := stage.scenery.find_children(view.prefix + "*Glass", "Sprite3D", true, false)
		if panes.is_empty():
			push_error("Missing layered window for " + label)
			continue
		var target: Vector3 = panes[0].global_position
		stage.camera_target = target
		stage.camera.position = target + Vector3(0.42, 0.16, 4.4)
		stage.camera.look_at(target)
		for frame in 4:
			await process_frame
			await RenderingServer.frame_post_draw
		app.stage_viewport.get_texture().get_image().save_png("res://artifacts/paper_depth_%s.png" % label)
	app.free()
	quit()
