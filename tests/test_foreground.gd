extends SceneTree
var failures := 0
var checks := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func clear_pixel(screen: Vector2, wall: Node3D, camera: Camera3D, source: Image) -> bool:
	var origin := camera.project_ray_origin(screen)
	var ray := camera.project_ray_normal(screen)
	for sprite: Sprite3D in wall.get_children():
		var hit := origin + ray * ((sprite.global_position.z-origin.z) / ray.z)
		var local := sprite.to_local(hit)
		var pixel := Vector2(local.x,-local.y) / sprite.pixel_size + sprite.region_rect.size * 0.5
		if Rect2(Vector2.ZERO,sprite.region_rect.size).has_point(pixel):
			pixel += sprite.region_rect.position
			if source.get_pixel(int(pixel.x),int(pixel.y)).a > 0.5: return false
	return true
func run() -> void:
	var app = load("res://scenes/game.tscn").instantiate()
	app.campaign_enabled = false # Legacy regression fixture; main F5 uses the campaign.
	root.add_child(app)
	var stage: CrimsonStage3D = app.stage
	stage.frozen_camera = true
	stage.game.player.set_physics_process(false)
	var walls := stage.scenery.get_node("NearForeground").get_children()
	var worst := {}
	var foot_clear := true
	var source := preload("res://assets/environments/crimson/foreground_embankment_v2.png").get_image()
	var bottom_clear := true
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
							var card: Sprite3D = wall.get_node("AuthoredNearSilhouette")
							var depth := card.region_rect.size.y * card.pixel_size
							var bottom := stage.camera.unproject_position(wall.position + Vector3(wall.width * 0.5, -depth, 0))
							bottom_clear = bottom_clear and bottom.y > 360
							var foot: Vector2 = stage.camera.unproject_position(CrimsonStage3D.to_stage(Vector2(x, floor_y - rise)))
							if foot.x >= minf(left.x, right.x) and foot.x <= maxf(left.x, right.x):
								# Test actual authored alpha, not the empty space above a broken contour.
								for offset in [4.0,-12.0,-26.0]:
									var clear := clear_pixel(foot+Vector2(0,offset),wall,stage.camera,source)
									if foot_clear and not clear: print("ACTOR OCCLUSION ", wall.name, " x=", x, " y=", floor_y, " distance=", distance)
									foot_clear = foot_clear and clear
	for wall in walls:
		print("WALL ", wall.name, " highest screen fraction=", worst[wall.name])
		check(worst[wall.name] >= 0.63, "Wall contour stays in lower 37% of full viewport: " + str(wall.name))
		check(wall.position.z - 0.23 > 0.675, "Wall geometry is outside the playable platform front face")
	check(walls.filter(func(wall): return wall.end_pier).size() == 2, "Exactly two attached short piers")
	check(foot_clear, "Wall tops leave standing and airborne feet clear across all sampled routes")
	check(bottom_clear, "Foreground wall bottom remains beyond viewport throughout camera sweep")
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
