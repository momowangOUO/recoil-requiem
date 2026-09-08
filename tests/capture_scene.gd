extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func snapshot(path: String) -> void:
	await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	picture.resize(1280, 720, Image.INTERPOLATE_NEAREST)
	picture.save_png(path)
	print("CAPTURE " + path)

func run() -> void:
	var lab = load("res://scenes/lab.tscn").instantiate()
	root.add_child(lab)
	for index in 3:
		lab.reset_trial(index)
		lab.player.manual_control = true
		if is_instance_valid(lab.enemy):
			lab.enemy.set_physics_process(false)
		for frame in 12:
			await process_frame
		await snapshot("res://artifacts/preset_%d.png" % (index + 1))
	lab.pause_trial()
	for frame in 12:
		await process_frame
	await snapshot("res://artifacts/tuning_panel.png")
	lab.free()
	quit()
