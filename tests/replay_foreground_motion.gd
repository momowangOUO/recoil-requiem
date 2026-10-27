extends SceneTree
## Continuous keyboard replay for near-layer motion; no teleport or invulnerability.
var app: Control
var failures := 0
var jump_ground_y := 0.0
var jump_player_y := 0.0
var idle_wall_x := 0.0

func _initialize() -> void: run.call_deferred()

func key(code: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = down
	Input.parse_input_event(event)

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/foreground_motion_" + label + ".png")

func run() -> void:
	root.size = Vector2i(1280,720)
	app = load("res://scenes/game.tscn").instantiate()
	root.add_child(app)
	app.chapter_staging.enabled = false
	var game = app.stage.game
	var front = app.stage.foreground
	for tick in 10: await physics_frame
	for tick in 420:
		app.mouse_screen = Vector2(200,90)
		if tick == 0: key(KEY_D,true)
		if tick == 30: key(KEY_D,false)
		if tick == 140: idle_wall_x = front.get_child(3).global_position.x
		if tick == 149:
			if not is_equal_approx(idle_wall_x, front.get_child(3).global_position.x):
				push_error("Stationary foreground drifts after camera has settled")
				failures += 1
			jump_ground_y = front.get_child(3).global_position.y
			jump_player_y = game.player.position.y
			await capture("grounded")
		if tick == 150: key(KEY_SPACE,true)
		if tick == 154: key(KEY_SPACE,false)
		if tick == 172:
			if game.player.position.y >= jump_player_y - 8:
				push_error("Replay did not produce a real jump")
				failures += 1
			if absf(front.get_child(3).global_position.y - jump_ground_y) > 0.02:
				push_error("Foreground rises with the jumping camera instead of keeping ground support")
				failures += 1
			await capture("jump")
		if tick == 240: key(KEY_A,true)
		if tick == 330:
			key(KEY_A,false)
			await capture("return")
		await physics_frame
		await process_frame
	key(KEY_D,false)
	key(KEY_A,false)
	key(KEY_SPACE,false)
	app.free()
	print("FOREGROUND MOTION STAGE RESULT: 420 continuous engine-input frames, %d failures" % failures)
	quit(1 if failures else 0)
