extends "res://tests/run_tests.gd"
func run() -> void:
	var world := Node2D.new()
	root.add_child(world)
	var room = load("res://scenes/rooms/image_monastery.tscn").instantiate()
	world.add_child(room)
	room.build(3)
	check(room.stairs.size() >= 18,"Image-derived map contains independent stair modules")
	check(room.space_bounds.size()==16,"All 16 stable region IDs remain")
	for id in room.gates: room.set_gate_state(id,true)
	var p := make_player(world,room.spawn)
	p.tuning = PlayerTuning.responsive()
	var stuck := 0
	var previous_x := p.position.x
	for tick in 9000:
		await physics_frame
		var f := frame_for(p)
		f.move.x = 1
		p.step(f,1.0/60)
		stuck = stuck+1 if absf(p.position.x-previous_x)<0.01 else 0
		previous_x = p.position.x
		if stuck>90 or p.position.x>16050: break
	print("IMAGE MAIN WALK END: ",p.position)
	check(p.position.x>16050 and p.position.y<2800,"Main route reaches chapel exit without jump/fire/melee")
	check(p.position.y<2000,"Main traversal does not use underground recovery road")
	for tick in 9000:
		await physics_frame
		var f := frame_for(p)
		f.move.x = -1
		# Choose the visibly grated lower return, rather than the tower/gallery stair.
		f.drop_pressed = (p.position.x>9770 and p.position.x<10080) or (p.position.x>5940 and p.position.x<6390)
		p.step(f,1.0/60)
		stuck = stuck+1 if absf(p.position.x-previous_x)<0.01 else 0
		previous_x = p.position.x
		if stuck>90 or p.position.x<1000: break
	print("IMAGE RETURN WALK END: ",p.position)
	check(p.position.x<1000 and absf(p.position.y-1120)<3,"Ground route returns to transport shelter without jumping")
	for cp in room.checkpoints:
		var query := PhysicsRayQueryParameters2D.create(cp.position+Vector2(0,-4),cp.position+Vector2(0,8),1|1024)
		var hit: Dictionary = room.get_world_2d().direct_space_state.intersect_ray(query)
		check(not hit.is_empty(),"Checkpoint supported: "+cp.id)
	room.set_gate_state("gate_departure",false)
	p.position = Vector2(13080,1424)
	p.velocity = Vector2.ZERO
	for tick in 90:
		await physics_frame
		var f := frame_for(p); f.move.x=1
		p.step(f,1.0/60)
	check(p.position.x<13160,"Closed chapel gate stops walking before boss")
	world.free()
	print("IMAGE MONASTERY ROUTES STAGE RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)

