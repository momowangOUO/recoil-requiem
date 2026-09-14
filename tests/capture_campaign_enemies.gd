extends SceneTree
const Enemy := preload("res://scripts/combat/campaign_enemy.gd")
func _initialize() -> void: run.call_deferred()
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/campaign_enemies")
	var app = load("res://scenes/game.tscn").instantiate()
	root.add_child(app)
	var stage: CrimsonStage3D = app.stage
	var game := stage.game
	stage.frozen_camera = true
	game.player.manual_control = true
	for enemy in game.enemies:
		enemy.set_physics_process(false)
		enemy.hide()
	var floor_y: float = game.environment.spawn.y
	game.player.position = Vector2(420,floor_y)
	game.player.update_aim(game.player.aim_origin()+Vector2.RIGHT*100)
	stage.camera_target = CrimsonStage3D.to_stage(Vector2(480,floor_y-23))
	stage.camera.position = stage.camera_target+Vector3(0,1.18,4.5)
	stage.camera.look_at(stage.camera_target)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	for kind in ["charger","grenadier","flyer","support","elite","boss"]:
		var enemy := Enemy.new()
		enemy.archetype = kind
		enemy.position = Vector2(510,floor_y)
		enemy.target = game.player
		game.world.add_child(enemy)
		enemy.set_physics_process(false)
		enemy.artwork.set_physics_process(false)
		for facing in [0.0,PI]:
			enemy.facing_angle = facing
			for frame in 8:
				enemy.artwork.frame = frame
				enemy.artwork.queue_redraw()
				for i in 2: await process_frame
				await RenderingServer.frame_post_draw
				var suffix := "%s_%s_%d" % [kind,"right" if facing==0 else "left",frame]
				app.stage_viewport.get_texture().get_image().save_png("res://artifacts/campaign_enemies/%s_native.png"%suffix)
				if frame in [0,4,7]: root.get_texture().get_image().save_png("res://artifacts/campaign_enemies/%s.png"%suffix)
		enemy.free()
	app.free()
	quit()
