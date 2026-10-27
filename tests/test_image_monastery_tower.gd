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
	var p := make_player(world,Vector2(2600,588))
	p.tuning = PlayerTuning.responsive()
	for level in 6:
		var x := 2300.0 if level%2==0 else 2460.0
		await walk(p,x)
		for tick in 20:
			await physics_frame
			p.step(frame_for(p),1.0/60)
		print("TOWER UP ",level," ",p.position)
		check(absf(p.position.y-(516-level*72))<12,"Tower landing %d ascent with AD only" % level)
	await walk(p,2370)
	for tick in 360:
		await physics_frame
		var f := frame_for(p)
		f.drop_pressed = tick%50==0
		p.step(f,1.0/60)
	check(p.position.y>580 and p.position.y<680,"Controlled descent returns inside the same tower/court")
	await walk(p,2896)
	check(absf(p.position.y-588)<12,"Tower returns to garden without jump or fire")
	p.free()
	world.free()
	print("IMAGE MONASTERY TOWER STAGE RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
