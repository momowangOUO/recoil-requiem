extends SceneTree
func _initialize() -> void: run.call_deferred()
func capture(label: String) -> void:
	for i in 3:
		await physics_frame
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/combat_hud_%s.png" % label)
func run() -> void:
	var app = load("res://scenes/game.tscn").instantiate()
	app.campaign_enabled = false # Legacy regression fixture; main F5 uses the campaign.
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
	await capture("idle")
	player.weapons.current().ammo = 2
	var input := InputFrame.new()
	input.aim_world = player.aim_origin()+Vector2(200,0)
	input.fire_pressed = true
	player.step(input,1.0/60)
	await capture("shot")
	for i in 30: await physics_frame
	await capture("rest")
	player.weapons.current().start_reload()
	player.weapons.current().tick(0.5,true)
	await capture("reload")
	stage.game.overlay.combat.ui_scale = 2.0
	stage.game.input_adapter.view_toggle = true
	stage.game.input_adapter.view_active = true
	await capture("scale2")
	app.free()
	quit()
