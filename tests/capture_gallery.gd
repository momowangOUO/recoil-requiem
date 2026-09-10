extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var app = load("res://scenes/game.tscn").instantiate()
	root.add_child(app)
	var stage: CrimsonStage3D = app.stage
	var game := stage.game
	game.room_index = 1
	game.reset_trial(3)
	stage.frozen_camera = true
	game.player.manual_control = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	for guard in game.enemies:
		guard.set_physics_process(false)
	var rifle: RifleEnemy = game.enemies[1]
	for view in ["overview", "aim", "reload", "death"]:
		game.player.position = Vector2(600, 240)
		game.player.update_aim(Vector2(700, 210))
		rifle.position = Vector2(700, 240)
		rifle.facing_angle = PI
		rifle.state = ShieldEnemy.State.WINDUP if view == "aim" else ShieldEnemy.State.RECOVERY
		rifle.locked_direction = Vector2.LEFT
		rifle.state_time = 0.7
		if view == "death": rifle.state = ShieldEnemy.State.DEAD
		rifle.queue_redraw()
		stage.camera_target = CrimsonStage3D.to_stage(Vector2(496, 258) if view == "overview" else Vector2(650, 226))
		stage.camera.position = stage.camera_target + Vector3(0.22, 1.3, 7.5 if view == "overview" else 4.8)
		stage.camera.look_at(stage.camera_target)
		game.overlay._notice.hide()
		game.overlay._notice_timer = 0
		for i in (50 if view == "death" else 5):
			await physics_frame
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/gallery_%s.png" % view)
		app.stage_viewport.get_texture().get_image().save_png("res://artifacts/gallery_%s_native.png" % view)
	# Same camera, floor and lighting: compare all three character art sets.
	game.player.position = Vector2(580, 240)
	game.player.update_aim(Vector2(1000, 214))
	game.enemies[0].position = Vector2(640, 240)
	game.enemies[0].facing_angle = 0
	rifle.position = Vector2(704, 240)
	rifle.state = ShieldEnemy.State.APPROACH
	rifle.facing_angle = 0
	rifle.queue_redraw()
	stage.camera_target = CrimsonStage3D.to_stage(Vector2(645, 211))
	stage.camera.position = stage.camera_target + Vector3(0, 1.18, 5.5)
	stage.camera.look_at(stage.camera_target)
	for i in 6:
		await physics_frame
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/character_lineup_v3.png")
	# Render the actual smooth weapon-camera behavior at neutral and edge pointer.
	stage.frozen_camera = false
	for slot in 3:
		game.player.weapons.select_weapon(slot)
		for edge in [false, true]:
			app.mouse_screen = Vector2(319 if edge else 160, 90)
			for i in 110:
				await physics_frame
				await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://artifacts/camera_%d_%s.png" % [slot, "edge" if edge else "near"])
	app.free()
	quit()
