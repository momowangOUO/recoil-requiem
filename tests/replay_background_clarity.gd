extends SceneTree
## Continuous physics/input and camera springs inside each authored slice.
const SLICES := {"Tower":Vector2(9592,932.8), "Gate":Vector2(2100,294), "Hall":Vector2(13880,1424), "Archive":Vector2(6800,880), "Garden":Vector2(10800,1424)}
var checks := 0
var failures := 0
func _initialize() -> void: run.call_deferred()
func key(code: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = down
	Input.parse_input_event(event)
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func run() -> void:
	if not "--campaign-test" in OS.get_cmdline_user_args(): quit(2); return
	var app = load("res://scenes/game.tscn").instantiate()
	root.add_child(app)
	var stage: CrimsonStage3D = app.stage
	var player = stage.game.player
	stage.residency_enabled = false
	stage.residency.clear()
	for enemy in stage.game.enemies: enemy.set_physics_process(false)
	DirAccess.make_dir_recursive_absolute("res://artifacts/background_clarity_motion")
	for id in SLICES:
		if "--archive-only" in OS.get_cmdline_user_args() and id != "Archive": continue
		if "--garden-only" in OS.get_cmdline_user_args() and id != "Garden": continue
		# Teleport only between independent fixtures; no transform/camera resets
		# during any of the following 240 consecutive engine-input frames.
		player.position = SLICES[id]
		player.velocity = Vector2.ZERO
		app.mouse_screen = Vector2(200,90)
		for settle in 30: await physics_frame
		var initial_x: float = player.position.x
		var jump_y := 0.0
		var jumped := false
		var sheet: Image
		if DisplayServer.get_name() != "headless": sheet = Image.create(1920,720,false,Image.FORMAT_RGBA8)
		for tick in 240:
			var phase := tick % 80
			if phase == 0: key([KEY_1,KEY_2,KEY_3][tick/80],true)
			if phase == 2: key([KEY_1,KEY_2,KEY_3][tick/80],false)
			if tick == 5: key(KEY_D,true)
			if tick == 30: key(KEY_D,false)
			if tick == 85: jump_y = player.position.y; key(KEY_SPACE,true)
			if tick == 90: key(KEY_SPACE,false)
			if tick > 85 and tick < 120: jumped = jumped or player.position.y < jump_y - 8
			if tick == 165: key(KEY_A,true)
			if tick == 190: key(KEY_A,false)
			app.mouse_screen = Vector2(200 if phase < 35 else 319,90)
			await physics_frame
			await process_frame
			if phase in [29,79]:
				check(stage.camera_distance >= stage.camera_profile().near - 0.4 and stage.camera_distance <= stage.camera_profile().far + 0.4, "Weapon camera spring remains in its configured range")
				if sheet != null:
					await RenderingServer.frame_post_draw
					var pixels: Image = app.stage_viewport.get_texture().get_image()
					pixels.convert(Image.FORMAT_RGBA8)
					sheet.blit_rect(pixels,Rect2i(0,0,640,360),Vector2i((tick/80)*640,0 if phase == 29 else 360))
			if tick == 30: check(player.position.x > initial_x + 8, "Actual continuous input moves through " + id)
		check(jumped, "Actual physics jump changes camera height in " + id)
		if sheet != null: sheet.save_png("res://artifacts/background_clarity_motion/%s.png" % id)
	for code in [KEY_A,KEY_D,KEY_SPACE,KEY_1,KEY_2,KEY_3]: key(code,false)
	app.free()
	print("BACKGROUND CLARITY MOTION STAGE RESULT: %d continuous input frames, %d checks, %d failures" % [240 if "--archive-only" in OS.get_cmdline_user_args() or "--garden-only" in OS.get_cmdline_user_args() else 1200, checks,failures])
	quit(1 if failures else 0)
