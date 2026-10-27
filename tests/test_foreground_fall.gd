extends "res://tests/test_image_paper_layers.gd"
## Continuous high drop with real move_and_slide and the production camera update.
## A dedicated collision layer supplies a repeatable landing without changing the map.

func run() -> void:
	root.size = Vector2i(1280, 720)
	var app = load("res://scenes/game.tscn").instantiate()
	root.add_child(app)
	var stage: CrimsonStage3D = app.stage
	var player := stage.game.player
	# This fixture owns its motion; desktop key presses must not pause the capture.
	app.set_process_input(false)
	stage.set_process_input(false)
	stage.game.set_process_input(false)
	for connection in root.focus_exited.get_connections():
		root.focus_exited.disconnect(connection.callable)
	stage.set_physics_process(false)
	stage.game.set_physics_process(false)
	player.set_physics_process(false)
	player.collision_mask = 1 << 19
	var floor_body := StaticBody2D.new()
	floor_body.collision_layer = 1 << 19
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(3000, 20)
	collision.shape = shape
	floor_body.add_child(collision)
	floor_body.position = Vector2(700, 1450)
	stage.simulation.add_child(floor_body)
	var front = stage.foreground
	var cards: Array = front.cards
	await physics_frame
	for weapon_index in 3:
		player.weapons.select_weapon(weapon_index)
		for far_view in [false, true]:
			for viewport_width in [640, 840]:
				app.stage_viewport.size = Vector2i(viewport_width, 360)
				app.mouse_screen = Vector2(319, 90) if far_view else Vector2(160, 90)
				player.position = Vector2(700, 350)
				player.velocity = Vector2.ZERO
				stage.camera_target = CrimsonStage3D.to_stage(player.position + Vector2(0, -52))
				stage.camera_distance = stage.camera_profile().far if far_view else stage.camera_profile().near
				front.reset_ground_anchor()
				var landed := false
				var landing_tick := -1
				var bad_frames := 0
				var lost_player_frames := 0
				var settled_y := 0.0
				var previous_camera_y := 0.0
				for tick in 280:
					await physics_frame
					# The later jump reverses vertical motion after a high-speed landing.
					if tick == 220: player.velocity.y = -280
					player.velocity.y = minf(player.velocity.y + 980.0 / 60.0, 900)
					# Match the stage parent updating before its gameplay child, then
					# inspect the frame that actually renders the player's new position.
					stage._physics_process(1.0 / 60.0)
					player.move_and_slide()
					if tick > 0:
						check(absf(stage.camera.position.y - previous_camera_y) < 0.2,
							"Fast-fall framing stays continuous, including landing and reversal")
					previous_camera_y = stage.camera.position.y
					if player.is_on_floor() and not landed:
						landed = true
						landing_tick = tick
					var size := Vector2(app.stage_viewport.size)
					var readable := true
					for fraction in [0.15, 0.5, 0.85]:
						readable = readable and _alpha_at_any(cards, _plane_hit(stage.camera, size * Vector2(fraction, 0.72))) < 0.1
					var head := stage.camera.unproject_position(CrimsonStage3D.to_stage(player.position + Vector2(0, -18)))
					var feet := stage.camera.unproject_position(CrimsonStage3D.to_stage(player.position))
					if not Rect2(Vector2.ZERO, size).has_point(head) or not Rect2(Vector2.ZERO, size).has_point(feet):
						lost_player_frames += 1
					if Rect2(Vector2.ZERO, size).has_point(head):
						readable = readable and _alpha_at_any(cards, _plane_hit(stage.camera, head)) < 0.1
					if not readable: bad_frames += 1
					for fraction in [0.0, 0.5, 1.0]:
						check(_base_reaches(cards, _plane_hit(stage.camera, size * Vector2(fraction, 0.995))), "High drop never exposes a detached bottom")
						if tick == 190:
							check(_alpha_at_any(cards, _plane_hit(stage.camera, size * Vector2(fraction, 0.995))) > 0.5, "Settled lower edge: gun=%d far=%s width=%d x=%s base=%s camera=%s" % [weapon_index,far_view,viewport_width,fraction,cards[3].position,stage.camera.position])
					if tick == 190: settled_y = cards[3].position.y
					if tick == 219:
						check(absf(cards[3].position.y - settled_y) < 0.005, "Foreground does not keep catching up after the camera settles")
					if weapon_index == 0 and not far_view and viewport_width == 640 and tick in [65, 95, 135, 190, 235] and DisplayServer.get_name() != "headless":
						await process_frame
						await RenderingServer.frame_post_draw
						root.get_texture().get_image().save_png("res://artifacts/foreground_fall_%d.png" % tick)
				check(landed and landing_tick > 60, "Fixture makes a continuous high drop and landing")
				check(lost_player_frames == 0, "Camera keeps the whole player in frame during fall/landing/reversal: %d lost frames" % lost_player_frames)
				check(bad_frames == 0, "Fast fall/landing/reversal clear the lower gameplay area: gun %d far=%s width=%d, %d obscured frames" % [weapon_index, far_view, viewport_width, bad_frames])
	app.free()
	print("FOREGROUND FALL STAGE RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
