extends "res://tests/test_image_monastery_branches.gd"
## Rebuild acceptance: real controller traversal, compact authored geometry.
func run() -> void:
	world = Node2D.new()
	root.add_child(world)
	room = load("res://scenes/rooms/image_monastery.tscn").instantiate()
	world.add_child(room)
	room.build(3)
	check(room.bounds.size.x <= 6144, "Chapter uses player-scale buildings rather than the old 16384px span")
	check(not room.has_node("Gameplay/RecoveryRoad"), "No full-width underground rescue highway")
	check(room.space_bounds.size() == 16, "All sixteen stable region IDs survive")
	check(room.checkpoints.size() == 16, "All sixteen checkpoint markers instantiate")
	for stair in room.stairs:
		check(absf(stair.end_offset.x) <= 512, "Stair stays within a local building: " + str(stair.name))
	for checkpoint in room.checkpoints:
		var p := actor(checkpoint.position)
		for tick in 15:
			await physics_frame
			p.step(frame_for(p), 1.0 / 60)
		check(p.is_on_floor() and p.position.distance_to(checkpoint.position) < 8, "Old checkpoint lands safely: " + checkpoint.id)
		p.free()
	var walker := actor(room.spawn)
	check(await walk(walker,1000,"compact arrival"),"Zero-shot route reaches Mara through gatehouse")
	check(await walk(walker,1640,"compact cargo"),"Zero-shot route reaches Vira")
	check(not await walk(walker,1780,"closed freight gate"),"Closed freight route blocks walking")
	room.set_gate_state("gate_lift",true)
	check(await walk(walker,2640,"repaired upper route"),"Repair route reaches inner garden without jumping")
	grounded_at(walker,588,"Upper route garden")
	check(await walk(walker,2960,"garden to Celine"),"Garden reaches first duel checkpoint")
	check(not await walk(walker,3550,"closed chapel"),"Closed chapel blocks the boss chamber")
	room.set_gate_state("gate_departure",true)
	check(await walk(walker,3560,"raised chapel altar"),"Main route climbs the illustrated altar by its actual stairs")
	grounded_at(walker,488,"Raised altar")
	check(await walk(walker,3950,"chapel open"),"Defeated Celine opens route to Vira")
	walker.free()
	room.set_gate_state("gate_lift",false)
	var lower := actor(room.spawn)
	check(await walk(lower,1200,"maintenance approach"),"Fresh save reaches the maintenance hatch")
	for tick in 48:
		await physics_frame
		var f := frame_for(lower)
		f.drop_pressed = true
		lower.step(f,1.0/60)
	check(await walk(lower,2176,"local pump rooms"),"Maintenance console is reachable without tools, ammo or jumping")
	check(not await walk(lower,2300,"closed isolation gate"),"Unsafe maintenance gate physically blocks")
	room.set_gate_state("gate_maintenance",true)
	check(await walk(lower,2490,"maintenance landing"),"Short eastern maintenance flight reaches its landing")
	check(await walk(lower,2640,"maintenance garden"),"Maintenance route independently reaches inner garden")
	grounded_at(lower,588,"Lower route garden")
	lower.free()
	room.set_gate_state("gate_departure",false)
	room.set_gate_state("gate_departure_back",false)
	var airborne := actor(Vector2(2944,-300))
	airborne.velocity = Vector2(600,-720)
	for tick in 450:
		await physics_frame
		var f := frame_for(airborne)
		f.move.x = 1
		airborne.step(f,1.0/60)
	check(airborne.position.x < 3040 or airborne.position.y < 156,"Flying over the roof cannot land inside the locked chapel")
	airborne.free()
	world.free()
	print("MONASTERY REBUILD STAGE RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
