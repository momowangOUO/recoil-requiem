extends "res://tests/run_tests.gd"
const Validator = preload("res://addons/recoil_map_editor/room_validator.gd")

func frames(count: int) -> void:
	for i in count:
		await physics_frame
		await process_frame

func run() -> void:
	for path in RecoilLab.CAMPAIGN_ROOMS:
		var room = load(path).instantiate()
		check(Validator.validate(room).is_empty(), "authored map validates: " + path)
		var invalid := RoomMarker.new()
		invalid.kind = RoomMarker.Kind.SPAWN
		room.get_node("Gameplay").add_child(invalid)
		check(not Validator.validate(room).is_empty(), "editor rejects duplicate and unsupported spawn")
		room.free()
	var app = load("res://scenes/game.tscn").instantiate()
	app.campaign_enabled = false # Legacy regression fixture; main F5 uses the campaign.
	root.add_child(app)
	var game: RecoilLab = app.stage.game
	game.connected_map = false
	game.reset_trial(3)
	game.player.manual_control = true
	await frames(3)
	game.enemy.fixed_target = true
	var lethal := ShotContext.new()
	lethal.damage = 10000
	lethal.source_position = game.enemy.position + Vector2(-100, -24)
	lethal.direction = Vector2.RIGHT
	game.enemy.receive_hit(lethal, game.enemy.position)
	game.player.position = game.environment.exit_position
	game.player.step(frame_for(game.player), 1.0 / 60)
	await frames(4)
	check(game.room_index == 1, "clearing east court and reaching its door loads the next room")
	game.player.manual_control = true
	check(game.enemies.size() == 2 and game.enemies[1] is RifleEnemy, "gallery spawns shield plus new riflewoman from editable markers")
	check(app.stage.shadow_cards.size() == 3, "3D presentation creates one contact shadow per actor")
	check(game.environment.modules.size() == 9, "gallery contains upper crossing and lower recovery route")
	game.enemies[0].fixed_target = true
	game.enemies[0].receive_hit(lethal, game.enemies[0].position)
	check(not game.environment.exit_open, "one remaining riflewoman keeps the exit closed")
	var rifle := game.enemies[1] as RifleEnemy
	var artwork := rifle.get_node("RifleArtwork") as RifleVisual
	rifle.fixed_target = true
	var idle_before := artwork.idle_time
	await frames(30)
	check(artwork.sheet == 2 and artwork.idle_time > idle_before + 0.4, "riflewoman plays authored breathing frames while guarding")
	rifle.fixed_target = false
	rifle.state_time = 0
	rifle.target = game.player
	game.player.position = Vector2(584, 240)
	game.player.velocity = Vector2.ZERO
	game.player.step(frame_for(game.player), 1.0 / 60)
	await frames(40)
	check(rifle.state == ShieldEnemy.State.WINDUP and rifle.attack_count == 0, "riflewoman gives visible windup before dealing damage")
	await frames(31)
	var locked := rifle.locked_direction
	game.player.position.y -= 90
	await frames(10)
	check(rifle.locked_direction.is_equal_approx(locked), "final windup locks aim rather than following a dodge")
	await frames(12)
	check(rifle.attack_count == 1 and game.player.health == 5, "dodging the locked shot avoids damage and only one shot is fired")
	check(rifle.state == ShieldEnemy.State.RECOVERY, "riflewoman exposes a reload recovery after her shot")
	var clock := rifle.state_time
	game.pause_trial()
	await frames(8)
	check(rifle.state_time == clock, "pause freezes the new enemy attack clock")
	game.resume_trial()
	# Aim straight at a stationary target: hitscan must hurt exactly once.
	game.player.position = Vector2(584, 240)
	game.player.velocity = Vector2.ZERO
	game.player.step(frame_for(game.player), 1.0 / 60)
	await frames(2)
	rifle.locked_direction = Vector2.LEFT
	rifle.facing_angle = PI
	rifle._enter(ShieldEnemy.State.ATTACK)
	await frames(5)
	check(game.player.health == 4, "rifle shot damages player when the locked path intersects her")
	# A thin wall must stop the same shot.
	game.player.invulnerability = 0
	var cover := make_floor(game.world, Rect2(609, 180, 2, 64))
	await frames(2)
	rifle._enter(ShieldEnemy.State.ATTACK)
	await frames(5)
	check(game.player.health == 4, "thin solid cover stops enemy rifle hitscan")
	cover.position.x += 21
	await frames(2)
	rifle._enter(ShieldEnemy.State.ATTACK)
	await frames(5)
	check(game.player.health == 4, "a wall between rifle body and muzzle also blocks the shot")
	rifle.receive_hit(lethal, rifle.position)
	check(game.environment.exit_open and rifle.state == ShieldEnemy.State.DEAD, "defeating both enemies opens the gallery exit")
	check(rifle.hurtbox.collision_layer == 0, "dead riflewoman cannot intercept further projectiles")
	await frames(45)
	check(artwork.sheet == 1 and artwork.frame == 3, "riflewoman settles on the authored final death pose")
	# Verify the recovery route using actual input frames, without teleporting through it.
	game.reset_trial(3)
	game.player.manual_control = true
	for guard in game.enemies: guard.fixed_target = true
	var jumped := false
	var reached_lower := false
	for tick in 420:
		var f := frame_for(game.player, Vector2.DOWN)
		f.move.x = 1 if game.player.position.x < 850 else 0
		reached_lower = reached_lower or game.player.position.y > 380
		if game.player.is_on_floor() and game.player.position.x > 564 and not jumped:
			f.jump_pressed = true
			f.fire_pressed = true
			jumped = true
		game.player.step(f, 1.0 / 60)
		await frames(1)
	check(reached_lower and game.player.position.x > 820 and game.player.is_on_floor(), "actual controls traverse the lower recovery route back to east floor")
	for i in 3:
		game.reset_trial(3)
		game.player.manual_control = true
		await frames(2)
		check(game.room_index == 1 and game.enemies.size() == 2 and game.enemies[1].health == 72 and game.projectiles.get_child_count() == 0, "checkpoint reset recreates gallery without stale combat state")
	app.free()
	print("CAMPAIGN STAGE RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
