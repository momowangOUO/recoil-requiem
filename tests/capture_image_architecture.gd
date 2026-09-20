extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var app = load("res://scenes/game.tscn").instantiate()
	root.add_child(app)
	var stage = app.stage
	var game = stage.game
	stage.frozen_camera = true
	game.player.manual_control = true
	game.player.set_physics_process(false)
	var views := {"station": Vector2(700,1120), "station_carriage": Vector2(1260,1120), "s02": Vector2(3400,1268), "cargo": Vector2(4200,2280), "pump": Vector2(7100,2632), "gallery": Vector2(5200,688), "garden": Vector2(10500,1424), "hall": Vector2(13800,1424), "hall_stores": Vector2(13000,2720), "underpass": Vector2(5840,1540), "bell_underpass": Vector2(9680,1540), "tower_open_stair": Vector2(9592,932.8)}
	var tower_only := "--tower-only" in OS.get_cmdline_user_args()
	if tower_only: views = {"tower_open_stair": views.tower_open_stair}
	var station_only := "--station-only" in OS.get_cmdline_user_args()
	if station_only: views = {"station_carriage": views.station_carriage}
	var setdress_only := "--setdress-only" in OS.get_cmdline_user_args()
	if setdress_only: views = {"station_carriage": views.station_carriage, "cargo": views.cargo, "hall_stores": views.hall_stores}
	for label in views:
		game.player.position = views[label]
		game.player.update_aim(game.player.position + Vector2(100,-26))
		stage.camera_target = CrimsonStage3D.to_stage(game.player.position + Vector2(0,-58))
		stage.camera.position = stage.camera_target + Vector3(0.12,1.18,5.2)
		stage.camera.look_at(stage.camera_target)
		stage.residency.update_at(game.player.position)
		for i in 5:
			await physics_frame
			await process_frame
		await RenderingServer.frame_post_draw
		app.stage_viewport.get_texture().get_image().save_png("res://artifacts/image_arch_%s.png" % label)
	if tower_only or station_only or setdress_only:
		app.free()
		quit()
		return
	var foreground_views := {"station": Vector2(700, 1120), "gallery": Vector2(5200, 688),
		"tower": Vector2(9592, 932), "garden": Vector2(10500, 1424),
		"hall": Vector2(13800, 1424), "lower_hall": Vector2(13000, 2720)}
	for label in foreground_views:
		for distance in [3.8, 7.2]:
			game.player.position = foreground_views[label]
			stage.camera_target = CrimsonStage3D.to_stage(game.player.position + Vector2(0, -minf(52, distance * 10)))
			stage.camera.position = stage.camera_target + Vector3(0.12, 1.18, distance)
			stage.camera.look_at(stage.camera_target)
			stage.foreground.call("follow_camera", stage.camera)
			stage.residency.update_at(game.player.position)
			for i in 5:
				await physics_frame
				await process_frame
			await RenderingServer.frame_post_draw
			app.stage_viewport.get_texture().get_image().save_png("res://artifacts/image_foreground_%s_%s.png" % [label, str(distance)])
	game.player.position = Vector2(5200, 688)
	stage.camera_target = CrimsonStage3D.to_stage(game.player.position + Vector2(0, -52))
	stage.camera.position = stage.camera_target + Vector3(0.12, 1.18, 5.2)
	stage.camera.look_at(stage.camera_target)
	stage.foreground.call("follow_camera", stage.camera)
	stage.residency.update_at(game.player.position)
	for i in 5:
		await physics_frame
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/image_paperboard_full_1280.png")
	app.free()
	quit()

