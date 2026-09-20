extends SceneTree
## GPU review fixture for the authored combat art at the supported window sizes.

func _initialize() -> void:
	run.call_deferred()

func settle(frames := 4) -> void:
	for i in frames:
		await physics_frame
		await process_frame

func capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/ui_v2_combat_%s.png" % label)

func run() -> void:
	root.size = Vector2i(1280, 720)
	var app = load("res://scenes/game.tscn").instantiate()
	app.campaign_enabled = false
	root.add_child(app)
	var stage: CrimsonStage3D = app.stage
	var player := stage.game.player
	player.manual_control = true
	player.set_physics_process(false)
	player.position = Vector2(220,352)
	for enemy in stage.game.enemies: enemy.set_physics_process(false)
	stage.frozen_camera = true
	stage.camera_target = CrimsonStage3D.to_stage(player.position+Vector2(0,-52))
	stage.camera.position = stage.camera_target+Vector3(0.16,1.18,7.2)
	stage.camera.look_at(stage.camera_target)
	stage._update_actor_window()
	stage.game.reticle.screen_position_source = func(): return Vector2(205,95)
	await settle(8)
	for dimensions in [Vector2i(960,540), Vector2i(1280,720), Vector2i(1920,1080), Vector2i(2560,1080)]:
		root.size = dimensions
		for slot in 3:
			player.weapons.select_weapon(slot)
			await settle(4)
			await capture("%d_%d_slot_%d_idle" % [dimensions.x, dimensions.y, slot+1])
			var weapon := player.weapons.current()
			weapon.ammo = maxi(1, int(weapon.data.magazine_size / 3))
			stage.game.reticle.shot_time = 0.1
			stage.game.overlay.combat.shot_time = 0.1
			await capture("%d_%d_slot_%d_shot" % [dimensions.x, dimensions.y, slot+1])
			weapon.start_reload()
			weapon.tick(weapon.data.reload_time * 0.4, true)
			await settle(2)
			await capture("%d_%d_slot_%d_reload" % [dimensions.x, dimensions.y, slot+1])
			weapon.cancel_reload()
		stage.game.input_adapter.view_toggle = true
		stage.game.input_adapter.view_active = true
		await settle(5)
		await capture("%d_%d_wheel" % [dimensions.x, dimensions.y])
		stage.game.input_adapter.view_active = false
	app.free()
	print("UI V2 COMBAT CAPTURE COMPLETE: 40 screenshots")
	quit()
