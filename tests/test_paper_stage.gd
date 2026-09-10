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

func run() -> void:
	var room = load("res://scenes/crimson_slice.tscn").instantiate()
	room.connected_map = false
	root.add_child(room)
	room.player.manual_control = true
	await frames(3)
	check(room.visual_slice and room.preset == 3, "Production scene must enter the visual slice")
	check(not room.overlay.lab_navigation, "Old laboratory menu must be absent")
	check(room.environment.modules.size() == 5, "Room must include ground plus four height platforms")
	var stage = room.environment.stage
	stage.follow_camera(Vector2(160, 288))
	var old_far: Vector2 = stage.far_layer.position
	var old_mid: Vector2 = stage.mid_layer.position
	stage.follow_camera(Vector2(260, 288))
	check(stage.far_layer.position - old_far != stage.mid_layer.position - old_mid, "Layers must have different parallax")
	var collider = room.environment.modules[1].get_node("Collision").get_child(0)
	var original: Vector2 = collider.shape.size
	room.environment.set_greybox(true)
	check(collider.shape.size == original and PaperPlatform.TOP_DEPTH >= 6 and PaperPlatform.FACE_DEPTH >= 16, "Greybox must retain depth and exact physical bounds")
	room.environment.set_greybox(false)
	check(room.reticle.get_parent() is CanvasLayer, "Cursor must use independent screen canvas")
	room.player.position = Vector2(520, 224)
	room.enemy.position = Vector2(558, 224)
	room.enemy.fixed_target = true
	for i in 5:
		var idle := InputFrame.new()
		idle.aim_world = room.enemy.position + Vector2(0, -24)
		room.player.step(idle, 1.0 / 60.0)
		await frames(1)
	check(room.player.is_on_floor() and absf(room.player.position.y - 224) < 1, "Actor feet must land on the marked upper edge")
	var fire := InputFrame.new()
	fire.aim_world = room.enemy.position + Vector2(0, -24)
	fire.weapon_slot_pressed = 1
	fire.fire_pressed = true
	room.player.step(fire, 1.0 / 60.0)
	await frames(60)
	print("KNOCKDOWN hp=", room.enemy.health, " feet=", room.enemy.position)
	check(room.enemy.health < 120 and room.enemy.position.y > 224 + 48, "Actual shotgun pellets must push the shield off the high platform onto the safe floor")
	var down := InputFrame.new()
	down.aim_world = room.player.aim_origin() + Vector2(0, 120)
	down.weapon_slot_pressed = 0
	down.fire_pressed = true
	room.player.velocity = Vector2.ZERO
	room.player.step(down, 1.0 / 60.0)
	check(room.player.velocity.y < 0, "Downward shooting must lift the actor in the real room")
	room.pause_trial()
	var ammo: int = room.player.weapons.current().ammo
	var elapsed: float = room.elapsed
	await frames(5)
	check(room.elapsed == elapsed and room.player.weapons.current().ammo == ammo, "Pause must freeze world time and ammunition")
	room.resume_trial()
	for i in 5:
		room.reset_trial(3)
		room.player.manual_control = true
		await frames(1)
		check(room.projectiles.get_child_count() == 0 and room.enemy.health == 120 and room.player.velocity == Vector2.ZERO, "Reset must clear previous projectiles, damage and movement")
	check(room.get_children().filter(func(n): return n.name == "TrialWorld").size() == 1, "Only one room world may survive resets")
	room.free()
	print("PAPER STAGE RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
