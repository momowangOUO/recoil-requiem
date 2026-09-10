extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var room = load("res://scenes/crimson_slice.tscn").instantiate()
	root.add_child(room)
	room.player.manual_control = true
	room.set_physics_process(false)
	room.enemy.set_physics_process(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	for view in ["entry", "combat", "greybox"]:
		room.player.position = Vector2(80, 352) if view == "entry" else Vector2(446, 224)
		room.player.update_aim(Vector2(580, room.player.position.y - 26))
		room.enemy.position = Vector2(528, 224)
		room.camera.position = Vector2(180, 292) if view == "entry" else Vector2(490, 240)
		room.camera.force_update_scroll()
		room.environment.stage.follow_camera(room.camera.position)
		room.environment.set_greybox(view == "greybox")
		room.overlay.update_hud({"preset": 3, "title": "CRIMSON MONASTERY", "inventory": room.player.weapons.inventory_snapshot(), "measurement": false, "health": 5, "ammo": 6, "magazine": 6})
		for i in 4:
			await physics_frame
			await process_frame
		await RenderingServer.frame_post_draw
		var picture := root.get_texture().get_image()
		picture.resize(320, 180, Image.INTERPOLATE_NEAREST)
		picture.save_png("res://artifacts/paper_%s_native.png" % view)
		picture.resize(1280, 720, Image.INTERPOLATE_NEAREST)
		picture.save_png("res://artifacts/paper_%s.png" % view)
	room.free()
	quit()
