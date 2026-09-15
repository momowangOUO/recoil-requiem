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
	check(await walk(p,6400,"courtyard side stair entrance"),"Spawn reaches side stair entrance")
	check(await walk(p,2960,"gatehouse balcony"),"Main route reaches gatehouse via side gallery")
	grounded_at(p,0,"Gatehouse balcony")
	check(await walk(p,5440,"upper side gallery"),"Gatehouse connects to side gallery")
	grounded_at(p,688,"Upper side gallery")
	check(await walk(p,6896,"archive room"),"Side gallery connects to archive room")
	grounded_at(p,880,"Archive room")
	check(await walk(p,2960,"archive return to gatehouse"),"Archive route reversible")
	grounded_at(p,0,"Returned gatehouse balcony")
	check(await walk(p,240,"gatehouse return street"),"Gatehouse returns to street")
	grounded_at(p,1120,"Returned street")
	p.free()
	# The visible courtyard hatch leads onto its descending stair.
	p = actor(Vector2(4500,1408))
	for tick in 30:
		await physics_frame
		var f := frame_for(p)
		f.drop_pressed = true
		p.step(f,1.0/60)
	print("BRANCH centered cargo hatch landed ",p.position)
	check(await walk(p,7200,"cargo stair to pump room",Vector2(4384,4640)),"Cargo stair reaches pump room")
	grounded_at(p,2632,"Pump room")
	check(await walk(p,8840,"pump east maintenance"),"Pump room east stair reachable")
	grounded_at(p,2312,"Pump east maintenance")
	check(await walk(p,4320,"pump return courtyard"),"Pump route returns via cargo stair")
	grounded_at(p,1408,"Returned courtyard")
	p.free()
	# Drop through the west hatch edge to visit the cargo floor below the stair.
	p = actor(Vector2(4397,1408))
	for tick in 100:
		await physics_frame
		var f := frame_for(p)
		f.drop_pressed = true
		p.step(f,1.0/60)
	print("BRANCH west cargo hatch landed ",p.position)
	check(await walk(p,4000,"west cargo floor"),"West cargo floor reachable from visible hatch")
	grounded_at(p,2280,"West cargo floor")
	check(await walk(p,7200,"west cargo to pump"),"West cargo floor connects to pump without jump")
	grounded_at(p,2632,"West cargo to pump arrival")
	p.free()
	room.set_gate_state("gate_departure",false)
	room.set_gate_state("gate_departure_back",false)
	for y in [1424.0,2720.0,3840.0]:
		p = actor(Vector2(13000,y))
		var crossed := await walk(p,13300,"closed departure boundary y="+str(y))
		check(not crossed and p.position.x<13160,"Closed departure gates block approach at y="+str(y))
		p.free()
	world.free()
	print("IMAGE MONASTERY BRANCHES STAGE RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
