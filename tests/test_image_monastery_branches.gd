extends "res://tests/run_tests.gd"
## Independent entry fixtures exercise real collisions, never jump/fire/teleport within a route.
var world: Node2D
var room: Node2D

func walk(p: PlayerController, target_x: float, label: String, drop_range := Vector2.INF) -> bool:
	var direction := signf(target_x-p.position.x)
	var still := 0
	var last := p.position
	for tick in 4500:
		await physics_frame
		var f := frame_for(p)
		f.move.x = direction
		f.drop_pressed = p.position.x > drop_range.x and p.position.x < drop_range.y
		p.step(f,1.0/60)
		still = still+1 if p.position.distance_to(last)<0.02 else 0
		last = p.position
		if direction*(target_x-p.position.x)<=0:
			print("BRANCH ",label," REACHED ",p.position)
			return true
		if still>70 or p.position.y>3900: break
	print("BRANCH ",label," BLOCKED ",p.position)
	return false

func actor(at: Vector2) -> PlayerController:
	var p := make_player(world,at)
	p.tuning = PlayerTuning.responsive()
	return p

func grounded_at(p: PlayerController, y: float, label: String) -> void:
	check(absf(p.position.y-y)<12,label+" standing height; actual "+str(p.position))

func run() -> void:
	world = Node2D.new()
	root.add_child(world)
	room = load("res://scenes/rooms/image_monastery.tscn").instantiate()
	world.add_child(room)
	room.build(3)
	for id in room.gates: room.set_gate_state(id,true)
	var p := actor(room.spawn)
	check(await walk(p,500,"gate balcony approach"),"Entry reaches local balcony stair")
	check(await walk(p,144,"gate lower landing"),"Balcony access begins within station")
	check(await walk(p,744,"gate balcony"),"Local stairs reach gate balcony with AD only")
	grounded_at(p,280,"Gate balcony")
	check(await walk(p,80,"balcony return"),"Balcony returns to known arrival road")
	for tick in 30:
		await physics_frame
		p.step(frame_for(p),1.0/60)
	grounded_at(p,512,"Station return")
	p.free()
	p = actor(room.spawn)
	check(await walk(p,1640,"cargo branch approach"),"Main road reaches upper gallery junction")
	check(await walk(p,1112,"gallery ascent"),"Local stair reaches gallery without jumping")
	grounded_at(p,404,"Gallery ascent")
	check(await walk(p,1704,"archive approach"),"Gallery reaches archive")
	grounded_at(p,452,"Archive")
	check(await walk(p,1000,"archive return"),"Archive returns to known cargo court")
	grounded_at(p,584,"Archive return")
	p.free()
	world.free()
	print("IMAGE MONASTERY BRANCHES STAGE RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
