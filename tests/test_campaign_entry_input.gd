extends SceneTree
## Entry integration: continuous walking and root-viewport input, not direct talk calls.
var checks := 0
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func key(code: Key) -> void:
	for down in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = down
		root.push_input(event, true)

func settle() -> void:
	await process_frame
	await physics_frame

func run() -> void:
	var app = load("res://scenes/game.tscn").instantiate()
	root.add_child(app)
	var game = app.stage.game
	var session = game.campaign_session
	var player: PlayerController = game.player
	player.manual_control = true
	session.autosave = false
	# A new-game introduction can pause the scene; dismiss only that initial panel.
	await settle()
	if session.ui.is_panel_open(): session.close()
	var start: Vector2 = player.position
	var health := player.health
	for tick in 2400:
		await physics_frame
		var frame := InputFrame.new()
		frame.move.x = 1
		frame.aim_world = player.aim_origin() + Vector2.RIGHT * 100
		player.step(frame, 1.0 / 60.0)
		if player.position.x >= 3880: break
	check(start.distance_to(Vector2(1260,1120)) < 4, "Fresh campaign starts with carriage behind and the entrance stair in view")
	check(player.position.x >= 3880 and absf(player.position.y - 1408) < 4, "First NPC reached by continuous walking without jump, fire or teleport")
	check(player.health == health, "Walking to the first conversation does not take unavoidable entry damage")
	check(session.nearest().get("id", "") == "mara", "Walking arrival selects the actual first NPC")
	player.velocity = Vector2.ZERO
	for tick in 180:
		await physics_frame
		var rest := InputFrame.new()
		rest.aim_world = player.aim_origin() + Vector2.RIGHT * 100
		player.step(rest, 1.0 / 60.0)
	check(player.health == health and game.combat_timer <= 0, "First NPC allows three seconds to read the prompt before combat")
	key(KEY_E)
	await settle()
	check(session.has("met_mara") and session.ui.is_panel_open(), "Root viewport E opens first conversation and records meeting")
	check(paused and game.paused, "Conversation pauses actual combat")
	key(KEY_ESCAPE)
	await settle()
	check(not session.ui.is_panel_open() and not paused, "One Escape closes conversation exactly once")
	var progress: Dictionary = session.state.snapshot()
	key(KEY_J)
	await settle()
	check(session.ui.is_panel_open(), "Root viewport J opens journal")
	key(KEY_ESCAPE)
	await settle()
	key(KEY_M)
	await settle()
	check(session.ui.is_panel_open(), "Root viewport M opens map")
	key(KEY_ESCAPE)
	await settle()
	var after: Dictionary = session.state.snapshot()
	check(session.has("tutorial_map"), "Opening the map records its completed tutorial")
	after.facts.erase("tutorial_map")
	after.results.erase("tutorial_map")
	check(after == progress, "Journal/map input leaves narrative quest progress unchanged")
	session.close()
	app.free()
	print("CAMPAIGN ENTRY INPUT STAGE RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
