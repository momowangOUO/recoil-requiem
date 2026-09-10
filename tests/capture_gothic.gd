extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var app = load("res://scenes/game.tscn").instantiate()
	root.add_child(app)
	var stage: CrimsonStage3D = app.stage
	var game := stage.game
	stage.frozen_camera = true
	game.player.manual_control = true
	for enemy in game.enemies: enemy.set_physics_process(false)
	game.player.position = Vector2(438, 224)
	game.enemy.position = Vector2(510, 224)
	stage.camera_target = CrimsonStage3D.to_stage(Vector2(475, 201))
	stage.camera.position = stage.camera_target + Vector3(0, 1.18, 4.5)
	stage.camera.look_at(stage.camera_target)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	game.reticle.screen_position_source = func(): return Vector2(170, 72)
	for slot in 3:
		game.player.weapons.select_weapon(slot)
		for angle in [0, -45, -90, 45, 90, 180]:
			game.player.update_aim(game.player.aim_origin() + Vector2.from_angle(deg_to_rad(angle)) * 100)
			game.player.visual.queue_redraw()
			game.overlay._notice.hide()
			game.overlay._notice_timer = 0
			for i in 3:
				await physics_frame
				await process_frame
			await RenderingServer.frame_post_draw
			app.stage_viewport.get_texture().get_image().save_png("res://artifacts/gothic_%d_%d.png" % [slot, angle])
			if slot == 0 and angle == 0: root.get_texture().get_image().save_png("res://artifacts/gothic_full.png")
		var weapon := game.player.weapons.current()
		weapon.ammo = 0
		weapon.start_reload()
		for progress in [0.0, 0.5, 0.95]:
			weapon.reload_elapsed = weapon.data.reload_time * progress
			game.player.update_aim(game.player.aim_origin() + Vector2.RIGHT * 100)
			game.player.visual.queue_redraw()
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://artifacts/gothic_reload_%d_%d.png" % [slot, int(progress * 100)])
		weapon.cancel_reload()
		weapon.ammo = weapon.data.magazine_size
	game.player.update_aim(game.player.aim_origin() + Vector2.RIGHT * 100)
	game.player.receive_damage(1, Vector2(-230, -150))
	game.player.visual.update_pose(0)
	var shot := ShotContext.new()
	shot.source_position = game.player.aim_origin()
	shot.direction = Vector2.RIGHT
	shot.damage = 24
	shot.knockback = 180
	game.enemy.receive_hit(shot, game.enemy.position + Vector2(0, -24))
	game.enemy.visual._physics_process(0)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/gothic_hit.png")
	for x in [950, 1910, 2870, 3830, 4500]:
		game.player.hit_flash = 0
		game.player.hurt_stun = 0
		game.player.invulnerability = 0
		game.player.visual.material.set_shader_parameter("hit_flash", 0.0)
		game.player.visual.position = Vector2.ZERO
		game.player.visual.queue_redraw()
		game.player.position = Vector2(x, 192 if x == 2870 else 320)
		stage.camera_target = CrimsonStage3D.to_stage(Vector2(x, 260))
		stage.camera.position = stage.camera_target + Vector3(0, 1.18, 6.0)
		stage.camera.look_at(stage.camera_target)
		for i in 3: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/connected_%d.png" % x)
	app.free()
	quit()
