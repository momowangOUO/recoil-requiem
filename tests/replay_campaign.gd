extends SceneTree
## Continuous engine keyboard/mouse replay: no teleports, invulnerability or damage cheats.
var app: Control
var game: RecoilLab
var shots := 0
var deaths := 0
var reset_count := 0
var max_x := 0.0
var min_health := 5
func _initialize() -> void: run.call_deferred()
func key(code: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = down
	Input.parse_input_event(event)
func mouse(down: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = down
	event.position = app.mouse_screen
	Input.parse_input_event(event)
func bind() -> void:
	reset_count += 1
	game.player.shot_fired.connect(func(_a,_b): shots+=1)
	game.player.died.connect(func(): deaths+=1)
func run() -> void:
	root.size = Vector2i(1280,720)
	app = load("res://scenes/game.tscn").instantiate()
	root.add_child(app)
	game = app.stage.game
	game.trial_reset.connect(bind)
	bind()
	for i in 5: await process_frame
	key(KEY_D,true)
	for frame in 960:
		var at: Vector2 = game.player.aim_origin() + Vector2(150,0)
		var distance := 350.0
		for enemy in game.enemies:
			var d: float = enemy.position.distance_to(game.player.position)
			if enemy.state != ShieldEnemy.State.DEAD and d < distance:
				distance = d
				at = enemy.position + Vector2(0,-24)
		app.mouse_screen = app.stage.camera.unproject_position(CrimsonStage3D.to_stage(at)) / 2
		if frame % 60 == 0: key(KEY_SPACE,true)
		if frame % 60 == 4: key(KEY_SPACE,false)
		if frame % 24 == 0: mouse(true)
		if frame % 24 == 1: mouse(false)
		if frame == 240: key(KEY_3,true)
		if frame == 241: key(KEY_3,false)
		if frame == 270: mouse(true)
		if frame == 420: mouse(false)
		if frame == 450: key(KEY_R,true)
		if frame == 451: key(KEY_R,false)
		if frame % 90 == 30: key(KEY_V,true)
		if frame % 90 == 31: key(KEY_V,false)
		if frame == 600:
			key(KEY_D,false)
			key(KEY_A,true)
		if frame == 720:
			key(KEY_A,false)
			key(KEY_D,true)
		max_x = maxf(max_x,game.player.position.x)
		min_health = mini(min_health,game.player.health)
		await physics_frame
		await process_frame
	key(KEY_D,false)
	key(KEY_A,false)
	mouse(false)
	print("CAMPAIGN REPLAY STAGE RESULT: engine input, 960 physics frames; shots=%d deaths=%d resets=%d max_x=%.1f min_health=%d" % [shots,deaths,reset_count,max_x,min_health])
	app.free()
	quit()
