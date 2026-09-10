extends SceneTree

var failures := 0
var checks := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func frames(count: int) -> void:
	for i in count:
		await physics_frame
		await process_frame

func key(code: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = down
	Input.parse_input_event(event)

func run() -> void:
	var app = load("res://scenes/game.tscn").instantiate()
	root.add_child(app)
	var stage: CrimsonStage3D = app.stage
	var game := stage.game
	await frames(4)
	check(app.stage_viewport.size == Vector2i(640, 360), "Game world must retain the upgraded 640x360 pixel rendering")
	check(game.overlay.get_viewport() == root and stage.camera.get_viewport() != root, "Sharp HUD must render separately from the pixel world")
	check(stage.camera.projection == Camera3D.PROJECTION_PERSPECTIVE, "Main view must use real perspective")
	check(game.player is CharacterBody2D and stage.simulation.disable_3d, "Gameplay physics and recoil must remain 2D")
	for at in [Vector2(200, 300), Vector2(500, 200), Vector2(780, 240)]:
		stage.camera_target = CrimsonStage3D.to_stage(at)
		stage.camera.position = stage.camera_target + Vector3(0.25, 1.18, 5.2)
		stage.camera.look_at(stage.camera_target)
		for offset in [Vector2(-60, -20), Vector2(40, 50), Vector2(0, -60)]:
			var point: Vector2 = at + offset
			var screen := stage.camera.unproject_position(CrimsonStage3D.to_stage(point))
			check(stage.screen_to_world(screen).distance_to(point) < 0.02, "Perspective aim must round-trip to the exact 2D gameplay plane")
	var old_root_size := root.size
	root.size = Vector2i(1440, 900)
	await frames(2)
	var point := Vector2(500, 240)
	var screen := stage.camera.unproject_position(CrimsonStage3D.to_stage(point))
	check(stage.screen_to_world(screen).distance_to(point) < 0.02, "Window resize must not affect world aim projection")
	root.size = old_root_size
	# Main-canvas coordinates are logical 320x180; only the world is sampled at 2x.
	var aim_point := Vector2(540, 236)
	var aim_pixel := stage.camera.unproject_position(CrimsonStage3D.to_stage(aim_point))
	var motion := InputEventMouseMotion.new()
	motion.position = aim_pixel / CrimsonStage3D.RENDER_SCALE
	motion.global_position = motion.position
	root.push_input(motion, true)
	print("CURSOR logical=", root.get_mouse_position(), " injected=", motion.position, " got=", stage.mouse_world(), " expected=", aim_point)
	check(stage.mouse_world().distance_to(aim_point) < 0.05, "Main UI cursor must map to the supersampled 3D combat plane")
	stage.set_greybox(true)
	var mesh_count := stage.scenery.get_child_count()
	stage.set_greybox(false)
	check(stage.scenery.get_child_count() == mesh_count, "Greybox must preserve the same 3D stage, depth and lights")
	game.reset_trial(3)
	game.projected_aim = func(): return game.player.aim_origin() + Vector2(120, 0)
	await frames(4)
	var start: Vector2 = game.player.position
	key(KEY_D, true)
	await frames(24)
	key(KEY_D, false)
	check(game.player.position.x > start.x + 20, "Native InputMap actions must reach the nested 2D controller")
	key(KEY_A, true)
	await frames(24)
	key(KEY_A, false)
	check(game.player.velocity.x < 0 and game.player.aim_direction.x > 0, "Retreat left while aiming right must remain independent")
	key(KEY_SPACE, true)
	await frames(1)
	key(KEY_SPACE, false)
	check(game.player.velocity.y < 0, "Existing Space jump must survive the presentation change")
	key(KEY_ESCAPE, true)
	await frames(1)
	key(KEY_ESCAPE, false)
	check(game.paused, "Pause input must reach the nested simulation exactly once")
	var before: Vector2 = game.player.position
	var camera_before: Vector3 = stage.camera.position
	await frames(5)
	check(game.player.position == before and stage.camera.position == camera_before, "Pause must freeze player and 3D camera")
	key(KEY_ESCAPE, true)
	await frames(1)
	key(KEY_ESCAPE, false)
	check(not game.paused, "Resume input must work while simulation is paused")
	for i in 3:
		game.reset_trial(3)
		await frames(1)
	check(stage.find_children("CrimsonMonasteryGeometry", "Node3D", false, false).size() == 1, "Reset must replace, not accumulate, 3D room geometry")
	check(app.find_children("AimUI", "CanvasLayer", false, false).size() == 1, "Reset must not leak screen-space cursors")
	app.free()
	await frames(2)
	print("3D STAGE RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
