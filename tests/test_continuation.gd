extends "res://tests/run_tests.gd"

func frames(count: int) -> void:
	for i in count:
		await physics_frame
		await process_frame

func travel(player: PlayerController, destination: Vector2, jump := false, boost := false) -> bool:
	for tick in 150:
		var f := frame_for(player, Vector2.DOWN)
		var dx := destination.x - player.position.x
		f.move.x = clampf(dx / 10, -1, 1)
		f.jump_pressed = jump and tick == 0
		f.fire_pressed = boost and tick == 0
		player.step(f, 1.0 / 60)
		await frames(1)
		if absf(dx) < 3 and absf(player.position.y - destination.y) < 3 and player.is_on_floor(): return true
	print("ROUTE STOP ", player.position, " expected ", destination)
	return false

func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	root.push_input(event, true)
	event = InputEventKey.new()
	event.physical_keycode = code
	root.push_input(event, true)

func leave_room(game: RecoilLab) -> bool:
	var index := game.room_index
	for tick in 180:
		var f := frame_for(game.player)
		f.move.x = 1
		game.player.step(f, 1.0 / 60)
		await frames(1)
		if game.room_index != index: return true
	return false

func run() -> void:
	var app = load("res://scenes/game.tscn").instantiate()
	root.add_child(app)
	var game: RecoilLab = app.stage.game
	game.room_index = 2
	game.reset_trial(3)
	game.player.manual_control = true
	for guard in game.enemies: guard.fixed_target = true
	await frames(3)
	check(not game.environment.exit_open, "tower door starts locked by alarm objective")
	check(not game.environment.get_node("Gameplay/ReturnBridge").active, "return bridge starts retracted with no collision")
	check(await travel(game.player, Vector2(105, 400)), "tower has safe approach before the first stone stair")
	var route_ok := true
	for step in [Vector2(160, 368), Vector2(240, 336), Vector2(320, 304), Vector2(400, 272), Vector2(480, 240), Vector2(560, 208), Vector2(640, 176)]:
		route_ok = await travel(game.player, step, true) and route_ok
		if step.y > 176: route_ok = await travel(game.player, step + Vector2(25, 0)) and route_ok
	check(route_ok, "ordinary jump route climbs every solid stair without upward phasing or firing")
	check(await travel(game.player, Vector2(736, 176)), "bell rope is reachable on foot from the top landing")
	key(KEY_E)
	await frames(3)
	check(game.environment.exit_open and game.environment.objectives_complete(), "E silences bell and opens exit without mandatory enemy extermination")
	check(game.environment.get_node("Gameplay/ReturnBridge").active, "bell action deploys return bridge and collider")
	check(app.stage.alarm_light.light_energy == 0, "silencing bell stops red alarm light")
	var action_count: int = app.stage.action_visuals.size()
	check(await travel(game.player, Vector2(836, 240)), "bell landing leads down to the unlocked tower door")
	check(await leave_room(game), "tower exit loads the archive using actual walking input")
	game.room_index = 2
	game.reset_trial(3)
	game.player.manual_control = true
	for guard in game.enemies: guard.fixed_target = true
	await frames(3)
	check(not game.environment.exit_open and not game.environment.get_node("Gameplay/ReturnBridge").active and app.stage.action_visuals.size() == action_count, "checkpoint reset restores switches, bridge and visual count")
	check(await travel(game.player, Vector2(96, 400)), "entry record is reachable")
	key(KEY_E)
	await frames(2)
	check(game.reading and game.paused and game.journal.size() == 1, "E opens record, journals it and pauses the world")
	var elapsed := game.elapsed
	await frames(8)
	check(game.elapsed == elapsed, "reading freezes simulation time")
	key(KEY_E)
	await frames(2)
	check(not game.paused and not game.reading, "E closes record and resumes")
	game.room_index = 3
	game.reset_trial(3)
	game.player.manual_control = true
	await frames(3)
	check(game.enemies.is_empty() and not game.environment.exit_open, "archive is a respite, gated by discovery rather than combat")
	var archive_route := await travel(game.player, Vector2(150, 352))
	archive_route = await travel(game.player, Vector2(220, 320), true) and archive_route
	archive_route = await travel(game.player, Vector2(265, 320)) and archive_route
	archive_route = await travel(game.player, Vector2(340, 288), true) and archive_route
	check(archive_route, "archive main record reachable using low ordinary jumps")
	key(KEY_E)
	await frames(2)
	check(game.environment.exit_open and game.journal.has("TransferLedger"), "reading transfer ledger opens passage and records story")
	key(KEY_ESCAPE)
	await frames(2)
	check(not game.paused, "Escape closes the story card")
	var reading_route := await travel(game.player, Vector2(377, 288))
	reading_route = await travel(game.player, Vector2(432, 256), true) and reading_route
	reading_route = await travel(game.player, Vector2(457, 256)) and reading_route
	reading_route = await travel(game.player, Vector2(520, 224), true) and reading_route
	check(reading_route, "archive stairs route around solid shelves rather than through their underside")
	check(await travel(game.player, Vector2(632, 224)), "optional sealed shelf has a visible launch point")
	check(await travel(game.player, Vector2(720, 144), true, true), "one revolver jump-shot reaches the optional high letter shelf")
	key(KEY_E)
	await frames(2)
	check(game.journal.has("HiddenLetter"), "optional recoil route rewards an additional story record")
	key(KEY_E)
	check(await travel(game.player, Vector2(640, 224)), "secret shelf has a safe drop back to the main route")
	check(await travel(game.player, Vector2(700, 320)), "opened archive bridge leads onto the east shelf")
	check(await travel(game.player, Vector2(836, 352)), "archive shelf has an unobstructed descent to the exit")
	check(await leave_room(game), "archive exit loads the garden using actual walking input")
	game.room_index = 4
	game.reset_trial(3)
	game.player.manual_control = true
	for guard in game.enemies: guard.fixed_target = true
	await frames(3)
	var west_route := await travel(game.player, Vector2(73, 320))
	for step in [Vector2(128, 288), Vector2(208, 256), Vector2(288, 224)]:
		west_route = await travel(game.player, step, true) and west_route
		if step.y > 224: west_route = await travel(game.player, step + Vector2(25, 0)) and west_route
	west_route = await travel(game.player, Vector2(352, 224)) and west_route
	check(west_route, "west sluice is accessible up solid stone steps")
	key(KEY_E)
	await frames(2)
	check(not game.environment.exit_open and game.environment.get_node("Gameplay/CanalBridge").active, "first sluice lowers only the west bridge and keeps final door locked")
	check(await travel(game.player, Vector2(592, 400)), "west balcony has a safe descent into dry canal")
	game.player.health = 3
	key(KEY_E)
	await frames(2)
	check(game.player.health == 5, "optional canal supply restores two health cells")
	game.player.health = 4
	key(KEY_E)
	await frames(2)
	check(game.player.health == 4, "consumed supply cannot be used twice")
	var east_route := await travel(game.player, Vector2(601, 400))
	east_route = await travel(game.player, Vector2(656, 368), true) and east_route
	east_route = await travel(game.player, Vector2(720, 344), true) and east_route
	east_route = await travel(game.player, Vector2(745, 344)) and east_route
	east_route = await travel(game.player, Vector2(784, 320), true) and east_route
	east_route = await travel(game.player, Vector2(832, 288), true) and east_route
	east_route = await travel(game.player, Vector2(896, 256), true) and east_route
	east_route = await travel(game.player, Vector2(912, 256)) and east_route
	check(east_route, "canal recovery route reaches east sluice without passing through stone")
	key(KEY_E)
	await frames(3)
	check(game.environment.exit_open and game.environment.get_node("Gameplay/EastBridge").active, "both sluices open the transfer gate while guards may remain alive")
	check(await travel(game.player, Vector2(944, 320)), "right balcony has a physical drop beside stone to the final gate")
	check(game.slice_complete and game.completed_rooms.has(4), "actual final gate completes the slice exactly once")
	game.pause_trial()
	var completed: bool = game.environment.objectives_complete()
	game.interact()
	check(game.environment.objectives_complete() == completed, "pause rejects world interactions")
	game.resume_trial()
	# Once both sluices are open, the restored central walkway is continuous.
	game.player.position = Vector2(224, 320)
	game.player.velocity = Vector2.ZERO
	await frames(2)
	var bridge_min_y := 320.0
	var bridge_max_y := 320.0
	for tick in 260:
		var f := frame_for(game.player)
		f.move.x = 1
		game.player.step(f, 1.0 / 60)
		bridge_min_y = minf(bridge_min_y, game.player.position.y)
		bridge_max_y = maxf(bridge_max_y, game.player.position.y)
		await frames(1)
		if game.player.position.x > 780: break
	check(game.player.position.x > 780 and absf(bridge_max_y - bridge_min_y) < 2, "both sluices restore a continuous walkable return route")
	key(KEY_M)
	await frames(2)
	check(game.reading and game.overlay._story_title.text.contains("当前路线"), "M opens the room route using the native story panel")
	key(KEY_M)
	key(KEY_J)
	await frames(2)
	check(game.paused and game.overlay._story_body.text.contains("守钟人"), "J keeps previously discovered records across rooms")
	check(game.overlay._story_scroll.get_v_scroll_bar().max_value > game.overlay._story_scroll.size.y, "long journal has a scrollable clipped body instead of overlapping close prompt")
	key(KEY_J)
	# Isolate physical underside behavior with actual controller, not flags alone.
	for one_way in [false, true]:
		var fixture := Node2D.new()
		root.add_child(fixture)
		var platform := PaperPlatform.new()
		platform.position = Vector2(100, 200)
		platform.width = 160
		platform.one_way = one_way
		fixture.add_child(platform)
		var player := make_player(fixture, Vector2(180, 300))
		player.velocity.y = -650
		var highest := 300.0
		await frames(2)
		for tick in 24:
			player.step(frame_for(player), 1.0 / 60)
			highest = minf(highest, player.position.y)
			await frames(1)
		check(highest < 200 if one_way else highest >= 244, "open grating permits upward passage; stone blocks the player's head")
		player.position = Vector2(180, 200)
		player.velocity = Vector2.ZERO
		for tick in 3:
			player.step(frame_for(player), 1.0 / 60)
			await frames(1)
		for tick in 20:
			var down := frame_for(player)
			down.drop_pressed = tick == 0
			player.step(down, 1.0 / 60)
			await frames(1)
		check(player.position.y > 230 if one_way else absf(player.position.y - 200) < 1, "S drops only through open grating, never solid stone")
		fixture.free()
	var ledge_world := Node2D.new()
	root.add_child(ledge_world)
	make_floor(ledge_world, Rect2(0, 352, 112, 20))
	var lure := make_player(ledge_world, Vector2(240, 352))
	var sentry := ShieldEnemy.new()
	sentry.position = Vector2(60, 352)
	sentry.target = lure
	ledge_world.add_child(sentry)
	await frames(120)
	check(sentry.position.x < 100 and sentry.position.y < 354, "approaching shield sentry does not blindly walk off a ledge")
	sentry.knockback_velocity.x = 400
	await frames(40)
	check(sentry.position.y > 370, "player knockback can still dislodge a sentry")
	ledge_world.free()
	app.free()
	print("CONTINUATION STAGE RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
