extends SceneTree
var checks := 0
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func run() -> void:
	if not "--campaign-test" in OS.get_cmdline_user_args(): quit(2); return
	var app = load("res://scenes/game.tscn").instantiate()
	root.add_child(app)
	var stage: CrimsonStage3D = app.stage
	stage.frozen_camera = true
	stage.residency_enabled = false
	stage.residency.clear()
	stage.game.player.set_physics_process(false)
	var expected := 0
	for stair in stage.game.environment.stairs:
		var id: String = stair.get_meta("structural_id", str(stair.name))
		var walls := stage.scenery.find_children(id + "ContinuousRearFoundation", "MeshInstance3D", true, false)
		if id.begins_with("Luggage"):
			check(walls.is_empty() and stage.scenery.find_children(id + "LoadingSkid", "MeshInstance3D", true, false).size() == 1, "Movable cargo ramp uses a shallow wooden skid instead of a tall foundation")
			continue
		if stair.one_way:
			check(walls.is_empty(), "Open metal stair keeps its intentionally open underside: " + id)
			continue
		expected += 1
		check(walls.size() == 1, "Solid stair owns a continuous retaining wall: " + id)
		var close_walls := stage.scenery.find_children(id + "CloseStairBackwall", "MeshInstance3D", true, false)
		check(close_walls.size() == 1, "Solid stair has actor-density near masonry: " + id)
		if not close_walls.is_empty():
			var material: StandardMaterial3D = close_walls[0].material_override
			check(material.albedo_texture.get_size() == Vector2(112,384), "Presentation mode keeps the pure masonry crop, not the complete facade atlas")
			check(material.get_meta("authored_texture") == material.albedo_texture, "Material restoration preserves the same cropped source")
			check(float(close_walls[0].get_meta("height_above_flight", 999)) <= 64, "Stair backing stays a low retaining wall instead of hiding the landmark")
			check(stage.scenery.find_children(id + "RetainingCoping", "MeshInstance3D", true, false).size() == 1, "Retaining wall ends with an authored structural coping")
		if walls.is_empty(): continue
		var bounds: AABB = walls[0].global_transform * walls[0].get_aabb()
		var bottom := maxf(3520.0, maxf(stair.position.y, stair.position.y + stair.end_offset.y) + stair.stair_depth + 80.0)
		check(absf(bounds.position.y + bottom * 0.01) < 0.001 and bounds.end.z < -2.5, "Retaining wall continues below its road behind glass and gameplay: " + id)
		for t in [0.05, 0.5, 0.95]:
			var at: Vector2 = stair.position + stair.end_offset * t
			var supported := bounds.has_point(Vector3(at.x * 0.01, -(at.y + stair.stair_depth + 50) * 0.01, -3.0))
			for pier: MeshInstance3D in stage.scenery.find_children(id + "ArcadeFoundation*", "MeshInstance3D", true, false):
				supported = supported or (pier.global_transform * pier.get_aabb()).has_point(Vector3(at.x * 0.01, -(at.y + stair.stair_depth + 50) * 0.01, -3.0))
			check(supported, "Stair interval is carried by a wall or the station arcade pier/lintel: " + id)
	var details := stage.scenery.find_children("*CloseStory*Wall", "MeshInstance3D", true, false)
	check(details.size() > 20, "Near-ground building surfaces use authored detail modules")
	for wall in details:
		check(is_equal_approx(float(wall.get_meta("logical_per_texel", 99)), 0.5), "Near facade uses actor-compositor density instead of enlarging a whole tower")
		check(absf(wall.get_aabb().position.y + float(wall.get_meta("ground_y")) * 0.01) < 0.001, "Detailed facade reaches its actual ground elevation")
		check(wall.material_override.texture_filter == BaseMaterial3D.TEXTURE_FILTER_NEAREST, "Authored facade keeps nearest sampling")
		check(wall.find_children("*", "CollisionObject3D", true, false).is_empty(), "Visual density improvement does not introduce collision")
	for location in [{"name":"entry", "at":Vector2(700,1120)}, {"name":"gate_stair", "at":Vector2(3400,1268)}, {"name":"gallery", "at":Vector2(5200,688)}, {"name":"stores", "at":Vector2(13000,2720)}]:
		for distance in [3.8, 7.2]:
			stage.game.player.position = location.at
			stage.camera_target = CrimsonStage3D.to_stage(location.at + Vector2(0,-52))
			stage.camera.position = stage.camera_target + Vector3(0.12,1.18,distance)
			stage.camera.look_at(stage.camera_target)
			for frame in 3: await process_frame
			if DisplayServer.get_name() != "headless":
				await RenderingServer.frame_post_draw
				app.stage_viewport.get_texture().get_image().save_png("res://artifacts/architecture_grounding_%s_%s.png" % [location.name,str(distance)])
	stage.game.reset_trial(3)
	for frame in 3: await process_frame
	check(stage.scenery.find_children("*ContinuousRearFoundation", "MeshInstance3D", true, false).size() == expected, "Reset keeps exactly one retaining wall per solid stair")
	app.free()
	print("ARCHITECTURE GROUNDING STAGE RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
