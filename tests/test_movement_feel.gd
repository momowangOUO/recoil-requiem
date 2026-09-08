extends "res://tests/run_tests.gd"
## Measures live controller behavior; desired grip fixes are regression gates.

func make_player(parent: Node, at: Vector2, initial_weapon: int = 0) -> PlayerController:
	var player := super.make_player(parent, at, initial_weapon)
	player.tuning = PlayerTuning.responsive()
	var config := RecoilLab.responsive_config()
	var definitions := WeaponData.baselines()
	for i in 3:
		definitions[i].apply_dict(config.weapons[i])
	player.weapons.configure(definitions, initial_weapon)
	return player

func run() -> void:
	var samples := {}
	var lift_world := Node2D.new()
	root.add_child(lift_world)
	var lift_player := make_player(lift_world, Vector2.ZERO, 1)
	var lift_input := frame_for(lift_player, Vector2.DOWN)
	lift_input.fire_pressed = true
	lift_player.velocity.y = -545
	await physics_frame
	lift_player.step(lift_input, 1.0 / 60)
	var first_lift := -lift_player.last_recoil.y
	check(-lift_player.velocity.y < 720, "jump-speed plus shotgun remains below air lift ceiling")
	lift_input.fire_pressed = false
	for tick in 90:
		await physics_frame
		lift_player.step(frame_for(lift_player, Vector2.DOWN), 1.0 / 60)
	lift_player.velocity.y = -545
	lift_input = frame_for(lift_player, Vector2.DOWN)
	lift_input.fire_pressed = true
	lift_player.step(lift_input, 1.0 / 60)
	check(-lift_player.last_recoil.y < first_lift * 0.25, "same-airtime lift fades even after firing cooldown ends")
	samples.first_and_late_lift = [first_lift, -lift_player.last_recoil.y]
	lift_world.free()
	var world := Node2D.new()
	root.add_child(world)
	var p := make_player(world, Vector2.ZERO)
	for tick in 120:
		await physics_frame
		var f := frame_for(p)
		f.move.x = 1
		p.step(f, 1.0 / 60)
	samples.air_input_speed_2s = p.velocity.x
	check(p.velocity.x <= 230, "air input alone cannot accelerate to recoil speeds")
	var start := p.position.x
	for tick in 60:
		await physics_frame
		p.step(frame_for(p), 1.0 / 60)
	samples.air_release_speed_1s = p.velocity.x
	samples.air_release_distance_1s = p.position.x - start
	check(p.velocity.x < 120, "releasing air movement slows drift")
	world.free()
	var jumps: Array = []
	for old_profile in [true, false]:
		world = Node2D.new()
		root.add_child(world)
		make_floor(world, Rect2(-2000, 0, 4000, 32))
		p = make_player(world, Vector2.ZERO)
		if old_profile:
			p.tuning = PlayerTuning.gdd_baseline()
		for tick in 3:
			await physics_frame
			p.step(frame_for(p), 1.0 / 60)
		var f := frame_for(p)
		f.jump_pressed = true
		await physics_frame
		p.step(f, 1.0 / 60)
		var duration := 1
		f.jump_pressed = false
		while not p.is_on_floor() and duration < 120:
			await physics_frame
			p.step(f, 1.0 / 60)
			duration += 1
		jumps.append({"height": p.max_rise, "airtime": duration / 60.0})
		world.free()
	samples.jumps_old_new = jumps
	check(jumps[1].airtime <= jumps[0].airtime * 0.9, "responsive jump lands at least 10 percent sooner")
	check(absf(jumps[1].height - jumps[0].height) < 8, "faster gravity preserves ordinary jump height")
	var drops: Array = []
	for mode in 3:
		world = Node2D.new()
		root.add_child(world)
		p = make_player(world, Vector2.ZERO, 2)
		for tick in 120:
			await physics_frame
			var f := frame_for(p, Vector2.DOWN)
			f.fire_held = mode > 0
			f.move.y = -1 if mode == 2 else 0
			p.step(f, 1.0 / 60)
		drops.append(p.position.y)
		world.free()
	samples.free_smg_smg_w = drops
	check(drops[1] > 0 and drops[1] < drops[0] * 0.6, "responsive SMG still slows fall below 60 percent")
	check(drops[2] > 0, "responsive SMG plus W still has net descent")
	world = Node2D.new()
	root.add_child(world)
	p = make_player(world, Vector2.ZERO, 1)
	var flight := frame_for(p, Vector2.LEFT)
	flight.move.x = 1
	flight.fire_pressed = true
	await physics_frame
	p.step(flight, 1.0 / 60)
	check(p.velocity.x > 700, "airborne shotgun retains real overspeed recoil")
	flight.fire_pressed = false
	await physics_frame
	p.step(flight, 1.0 / 60)
	check(p.velocity.x > 700, "air input cap does not erase existing recoil overspeed")
	world.free()
	for index in [0, 1]:
		world = Node2D.new()
		root.add_child(world)
		make_floor(world, Rect2(-4000, 0, 8000, 32))
		p = make_player(world, Vector2.ZERO, index)
		for tick in 15:
			await physics_frame
			var f := frame_for(p)
			f.move.x = 1
			p.step(f, 1.0 / 60)
		var shot := frame_for(p, Vector2.RIGHT)
		shot.move.x = 1
		shot.fire_pressed = true
		await physics_frame
		p.step(shot, 1.0 / 60)
		var after_shot := p.velocity.x
		var backslide := p.position.x
		var minimum_x := backslide
		for tick in 12:
			await physics_frame
			shot.fire_pressed = false
			shot.aim_world = p.aim_origin() + Vector2.RIGHT * 100
			p.step(shot, 1.0 / 60)
			minimum_x = minf(minimum_x, p.position.x)
		samples["ground_%d" % index] = {"vx_on_shot": after_shot, "vx_after_200ms": p.velocity.x, "extra_reverse_distance": backslide - minimum_x}
		check(p.velocity.x >= 140, "held running recovers from grounded shot within 200ms, weapon=%d" % index)
		if index == 0:
			check(after_shot >= 0, "grounded revolver shot slows a run without involuntary reverse")
		else:
			check(after_shot < 0 and backslide - minimum_x < 20, "grounded shotgun retains kick with bounded sliding")
		world.free()
	world = Node2D.new()
	root.add_child(world)
	make_floor(world, Rect2(-2000, 0, 4000, 32))
	p = make_player(world, Vector2.ZERO)
	for tick in 3:
		await physics_frame
		p.step(frame_for(p), 1.0 / 60)
	var neutral := frame_for(p, Vector2.LEFT)
	neutral.fire_pressed = true
	await physics_frame
	p.step(neutral, 1.0 / 60)
	check(p.visual.pose != "run", "recoil alone does not animate voluntary running")
	world.free()
	var file := FileAccess.open("res://artifacts/movement-feel.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(samples, "\t"))
	file.close()
	print("FEEL METRICS: " + JSON.stringify(samples))
	print("FEEL RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
