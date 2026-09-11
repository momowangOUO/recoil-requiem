extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/aim_sweep")
	var stage := Node2D.new()
	root.add_child(stage)
	var background := ColorRect.new()
	background.size = Vector2(320,180)
	background.color = Color("111722")
	stage.add_child(background)
	var actors: Array[PlayerController] = []
	for i in 6:
		var player := PlayerController.new()
		player.manual_control = true
		player.weapons.configure(WeaponData.baselines(),i%3)
		player.position = Vector2(54+(i%3)*106,72+(i/3)*90)
		stage.add_child(player)
		player.set_physics_process(false)
		actors.append(player)
		var label := Label.new()
		label.text = "%d / %s" % [i%3+1,"AIM" if i<3 else "RELOAD"]
		label.position = Vector2(20+(i%3)*106,77+(i/3)*90)
		label.add_theme_font_size_override("font_size",7)
		stage.add_child(label)
	for degree in 360:
		for i in actors.size():
			var player := actors[i]
			player.update_aim(player.aim_origin()+Vector2.from_angle(deg_to_rad(degree))*100)
			player.visual.pose = "idle"
			player.visual.frame = 0
			if i >= 3:
				var runtime := player.weapons.current()
				runtime.ammo = runtime.data.magazine_size-1
				runtime.reloading = true
				runtime.reload_elapsed = runtime.data.reload_time*(degree%120)/120.0
			player.visual.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		if degree % 3 == 0:
			var picture := root.get_texture().get_image()
			picture.resize(640,360,Image.INTERPOLATE_NEAREST)
			picture.save_png("res://artifacts/aim_sweep/%03d.png" % degree)
	stage.free()
	quit()
