extends SceneTree
## Visual fixture: isolates body frames, mirroring, vertical aiming and reload hands.

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var stage := Node2D.new()
	root.add_child(stage)
	var background := ColorRect.new()
	background.size = Vector2(320, 180)
	background.color = Color("111722")
	stage.add_child(background)
	var cases := []
	for gun in 3:
		for facing in [deg_to_rad(75), deg_to_rad(105)]:
			for progress in [-1.0, 0.5, 0.9]:
				cases.append(["%d / %d%%" % [gun+1, progress*100], "idle", 0, facing, gun, progress])
	for i in cases.size():
		var example: Array = cases[i]
		var player := PlayerController.new()
		player.manual_control = true
		player.weapons.configure(WeaponData.baselines(), int(example[4]))
		player.position = Vector2(26 + (i % 6) * 53, 45 + (i / 6) * 60)
		stage.add_child(player)
		player.update_aim(player.aim_origin() + Vector2.from_angle(example[3]) * 100)
		player.visual.pose = example[1]
		player.visual.frame = example[2]
		if example[5] >= 0:
			var runtime := player.weapons.current()
			runtime.ammo -= 1
			runtime.start_reload()
			runtime.reload_elapsed = runtime.data.reload_time * example[5]
		player.visual.queue_redraw()
		var label := Label.new()
		label.text = example[0]
		label.add_theme_font_size_override("font_size", 7)
		label.add_theme_color_override("font_color", Color("6cddd3"))
		label.position = Vector2((i % 6) * 53 + 3, 48 + (i / 6) * 60)
		stage.add_child(label)
	for i in 5:
		await process_frame
	await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	picture.resize(1280, 720, Image.INTERPOLATE_NEAREST)
	var error := picture.save_png("res://artifacts/downward_hands.png")
	print("CHARACTER RIG CAPTURE: ", "PASS" if error == OK else "FAIL")
	stage.free()
	quit(0 if error == OK else 1)
