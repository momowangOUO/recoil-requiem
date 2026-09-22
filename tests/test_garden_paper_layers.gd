extends SceneTree
## Real-scene garden art check. Run with --campaign-test; GPU also saves review views.
var checks := 0
var failures := 0

func _initialize() -> void: run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func run() -> void:
	if not "--campaign-test" in OS.get_cmdline_user_args():
		quit(2)
		return
	var app = load("res://scenes/game.tscn").instantiate()
	root.add_child(app)
	var stage: CrimsonStage3D = app.stage
	stage.frozen_camera = true
	stage.residency_enabled = false
	stage.residency.clear()
	stage.game.player.set_physics_process(false)
	var walls := stage.scenery.find_children("GardenPaintedFacade", "MeshInstance3D", true, false)
	check(walls.size() == 1, "Garden has one authored continuous facade instead of a bare frame")
	var panes := stage.scenery.find_children("GardenLayeredWindow*Glass", "Sprite3D", true, false)
	check(panes.size() == 5, "Five actual authored garden bays occupy separate recessed layers")
	for pane in panes:
		check(pane.texture.resource_path.ends_with("garden_facade_v2.png"), "Garden glass uses its matching authored crop")
		check(pane.position.z < float(pane.get_meta("wall_z")), "Glass is behind the actual wall cutout")
		check(is_equal_approx(pane.scale.x, pane.scale.y), "Glass crop retains its source proportions")
	check(stage.scenery.find_children("GardenFacadeFooting", "MeshInstance3D", true, false).size() == 1, "Paper wall has a real footing on F04")
	var roofs := stage.scenery.find_children("B10TrueSlopedCanopy", "MeshInstance3D", true, false)
	check(roofs.size() == 1, "Authored greenhouse keeps one real sloping roof")
	for foot: MeshInstance3D in stage.scenery.find_children("GardenColumnFoot*", "MeshInstance3D", true, false):
		var bottom := foot.position.y + foot.get_aabb().position.y
		check(absf(bottom + 14.24) < 0.01, "Canopy column footing meets its actual F04 support")
	if not walls.is_empty():
		var wall: MeshInstance3D = walls[0]
		check(wall.get_aabb().end.z < -1.2, "Garden wall remains behind gameplay and rear floor edge")
		check(absf(wall.get_aabb().position.y + 14.24) < 0.02, "Facade base meets the F04 floor elevation")
		check(absf(wall.get_aabb().size.x / wall.get_aabb().size.y - 2132.0 / 681.0) < 0.001, "Complete greenhouse preserves generated illustration proportions")
		check(wall.find_children("*", "CollisionObject3D", true, false).is_empty(), "Garden illustration creates no invisible gameplay obstacle")
	for distance in [3.8, 7.2]:
		stage.game.player.position = Vector2(10800, 1424)
		stage.camera_target = CrimsonStage3D.to_stage(stage.game.player.position + Vector2(0,-52))
		stage.camera.position = stage.camera_target + Vector3(0.12, 1.18, distance)
		stage.camera.look_at(stage.camera_target)
		stage.foreground.reset_ground_anchor()
		stage.foreground.follow_camera(stage.camera)
		stage.residency.update_at(stage.game.player.position)
		for frame in 5:
			await physics_frame
			await process_frame
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			app.stage_viewport.get_texture().get_image().save_png("res://artifacts/garden_layers_%s.png" % str(distance))
	stage.game.reset_trial(3)
	for frame in 3: await process_frame
	check(stage.scenery.find_children("GardenPaintedFacade", "MeshInstance3D", true, false).size() == 1, "Reset does not duplicate garden facades")
	check(stage.scenery.find_children("GardenLayeredWindow*Glass", "Sprite3D", true, false).size() == 5, "Reset does not duplicate garden panes")
	app.free()
	print("GARDEN PAPER LAYERS STAGE RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
