extends "res://tests/run_tests.gd"
var world: Node2D

func walk(p: PlayerController, x: float) -> void:
	var direction := signf(x-p.position.x)
	for tick in 1800:
		await physics_frame
		var f := frame_for(p)
		f.move.x = direction
		p.step(f,1.0/60)
		if direction*(x-p.position.x)<=0: return

func run() -> void:
	world = Node2D.new()
	root.add_child(world)
	var room = load("res://scenes/rooms/image_monastery.tscn").instantiate()
	world.add_child(room)
	room.build(3)
	for id in room.gates: room.set_gate_state(id,true)
	var p := make_player(world,room.spawn)
	p.tuning = PlayerTuning.responsive()
	await walk(p,240)
	check(p.position.x<244 and absf(p.position.y-1120)<4,"Spawn walks left out of solid gatehouse stair underpass")
	await walk(p,2960)
	check(absf(p.position.y)<4,"West entry bridge walks up solid gatehouse stair to balcony")
	await walk(p,200)
	check(p.position.x<204 and absf(p.position.y-1120)<4,"Gatehouse stair returns to west street")
	p.free()
	p = make_player(world,Vector2(9830,1424))
	p.tuning = PlayerTuning.responsive()
	for level in 6:
		var x := 9200.0 if level%2==0 else 9840.0
		await walk(p,x)
		print("TOWER UP ",level," ",p.position)
		check(absf(p.position.y-(1120-level*288))<12,"Tower landing %d ascent with AD only" % level)
	# The two flights overlap in screen X. At their inside quarter, one S press
	# selects the visible flight below with 144 px clearance, then AD continues.
	# Dropping at the shared tip instead would fall past the next flight.
	for level in 5:
		var x := 9400.0 if level%2==0 else 9640.0
		await walk(p,x)
		var before := p.position.y
		for tick in 90:
			await physics_frame
			var f := frame_for(p)
			f.drop_pressed = tick==0
			p.step(f,1.0/60)
		print("TOWER DOWN SELECT ",level," ",p.position)
		check(p.is_on_floor() and p.position.y-before>80 and p.position.y-before<210,"One S press selects only next flight %d" % level)
	await walk(p,9840)
	check(absf(p.position.y-1424)<12,"Tower returns to entry without jump or fire")
	p.free()
	world.free()
	print("IMAGE MONASTERY TOWER STAGE RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
