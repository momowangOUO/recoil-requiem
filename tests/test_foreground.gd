extends SceneTree
var failures := 0
var checks := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func run() -> void:
	var app = load("res://scenes/game.tscn").instantiate()
	root.add_child(app)
	var stage: CrimsonStage3D = app.stage
	stage.frozen_camera = true
	stage.game.player.set_physics_process(false)
	var walls := stage.scenery.get_node("NearForeground").get_children()
	var worst := {}
	var foot_clear := true
	for wall in walls: worst[wall.name] = 2.0
	# Every supported route height, including lower routes under raised platforms.
	for x in range(32, 4800, 32):
		var heights: Array[float] = []
		for module in stage.game.environment.modules:
			if x >= module.position.x and x <= module.position.x + module.width:
				heights.append(module.position.y)
		for floor_y in heights:
			for rise in [0.0, 80.0, 160.0]:
				for distance in [3.8, 4.4, 4.8, 5.2, 6.3, 7.2]:
					for yaw in [-0.32, 0.0, 0.32]:
						var target := CrimsonStage3D.to_stage(Vector2(clampf(x, 150, 4650), clampf(floor_y - rise - minf(52, distance * 10), -20, 350)))
						stage.camera.position = target + Vector3(yaw, 1.18, distance)
						stage.camera.look_at(target)
						for wall in walls:
							if absf(wall.position.x + wall.width * 0.5 - target.x) > 5.0: continue
							if stage.camera.is_position_behind(wall.position) or stage.camera.is_position_behind(wall.position + Vector3(wall.width, 0, 0)): continue
							var left: Vector2 = stage.camera.unproject_position(wall.position + Vector3(0, 0, 0.23))
							var right: Vector2 = stage.camera.unproject_position(wall.position + Vector3(wall.width, 0, 0.23))
							if maxf(left.x, right.x) < 0 or minf(left.x, right.x) > 640: continue
							worst[wall.name] = minf(worst[wall.name], minf(left.y, right.y) / 360.0)
							var foot: Vector2 = stage.camera.unproject_position(CrimsonStage3D.to_stage(Vector2(x, floor_y - rise)))
							if foot.x >= minf(left.x, right.x) and foot.x <= maxf(left.x, right.x):
								foot_clear = foot_clear and minf(left.y, right.y) > foot.y + 4.0
	for wall in walls:
		print("WALL ", wall.name, " highest screen fraction=", worst[wall.name])
		# Native HUD occupies y=0..36 and 290..360 in world-render coordinates.
		check(worst[wall.name] >= (36.0 + 254.0 * 0.80) / 360.0, "Wall must remain in bottom fifth of unobscured gameplay at every weapon distance and route height: " + str(wall.name))
		check(wall.position.z - 0.23 > 0.675, "Wall geometry is outside the playable platform front face")
	check(walls.filter(func(wall): return wall.end_pier).size() == 2, "Exactly two attached short piers")
	check(foot_clear, "Wall tops leave standing and airborne feet clear across all sampled routes")
	stage.camera.position = Vector3(1.4, -1.8, 7.2)
	stage.camera.look_at(Vector3(1.4, -2.98, 0))
	var near_point: Vector3 = walls[0].position
	var far_point := Vector3(near_point.x, near_point.y, 0)
	var near_before := stage.camera.unproject_position(near_point)
	var far_before := stage.camera.unproject_position(far_point)
	stage.camera.position.x += 0.2
	check(absf(stage.camera.unproject_position(near_point).x - near_before.x) > absf(stage.camera.unproject_position(far_point).x - far_before.x), "Near wall has stronger real translational parallax than gameplay plane")
	app.free()
	print("FOREGROUND STAGE RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
