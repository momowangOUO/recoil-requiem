extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var app = load("res://scenes/game.tscn").instantiate()
	app.campaign_enabled = false # Legacy regression fixture; main F5 uses the campaign.
	root.add_child(app)
	var stage: CrimsonStage3D = app.stage
	var player := stage.game.player
	player.manual_control = true
	player.set_physics_process(false)
	player.position = Vector2(80,352)
	for enemy in stage.game.enemies: enemy.set_physics_process(false)
	stage.frozen_camera = true
	stage.camera_target = CrimsonStage3D.to_stage(player.position+Vector2(0,-36))
	stage.camera.position = stage.camera_target+Vector3(0,1.18,3.8)
	stage.camera.look_at(stage.camera_target)
	stage._update_actor_window()
	for gun in [1,2]:
		player.weapons.configure(WeaponData.baselines(),gun)
		for angle in [75,90,105,270]:
			player.update_aim(player.aim_origin()+Vector2.from_angle(deg_to_rad(angle))*100)
			for progress in [-1.0,0.5]:
				var runtime := player.weapons.current()
				runtime.reloading = progress >= 0
				runtime.reload_elapsed = runtime.data.reload_time*maxf(0,progress)
				player.visual.pose = "idle"
				player.visual.frame = 0
				player.visual.queue_redraw()
				for i in 3:
					await physics_frame
					await process_frame
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://artifacts/aim_game_%d_%d_%d.png" % [gun+1,angle,int(progress*100)])
	app.free()
	quit()
