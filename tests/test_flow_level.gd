extends "res://tests/test_image_monastery_branches.gd"
## Real controller steps through authored choices; only fixture starts place actors.
func run() -> void:
	world = Node2D.new()
	root.add_child(world)
	room = load("res://scenes/rooms/image_monastery.tscn").instantiate()
	world.add_child(room)
	room.build(3)
	for id in room.gates: room.set_gate_state(id,false)
	var p := actor(room.spawn)
	check(await walk(p,3920,"safe arrival and shield bypass"),"Zero-shot bypass reaches Mara")
	check(await walk(p,6416,"closed-lift route to Vira"),"Fresh save reaches Vira without tools or ammo")
	check(await walk(p,7600,"courtyard with closed lift"),"Fresh save reaches maintenance fork without repair")
	for tick in 25:
		await physics_frame
		var f := frame_for(p); f.drop_pressed = true
		p.step(f,1.0/60)
	check(await walk(p,6830,"pump first landing"),"Courtyard hatch reaches pump landing")
	check(await walk(p,8100,"pump lower stair",Vector2(6768,7050)),"Second stair reaches pump corridor")
	check(await walk(p,8840,"maintenance console"),"No-tool route reaches isolation console")
	room.set_gate_state("gate_maintenance",false)
	check(not await walk(p,8990,"closed safety shutter"),"Maintenance safety shutter blocks before isolation")
	room.set_gate_state("gate_maintenance",true)
	check(await walk(p,11200,"maintenance to innercourt"),"Isolated maintenance route reaches innercourt without shooting or jump")
	grounded_at(p,1424,"Maintenance merges into innercourt")
	check(await walk(p,10720,"return hatch"),"Innercourt return reaches maintenance hatch")
	for tick in 25:
		await physics_frame
		var f := frame_for(p); f.drop_pressed = true
		p.step(f,1.0/60)
	check(await walk(p,8840,"maintenance return"),"Maintenance route is reversible")
	p.free()
	p = actor(Vector2(240,3840))
	check(await walk(p,3600,"recovery road escape"),"Fallen exploration player can walk back to cargo road")
	grounded_at(p,2280,"Recovery reaches known cargo floor")
	p.free()
	p = actor(Vector2(7800,1696))
	check(await walk(p,10320,"repair route archive"),"Upper route reaches archive corridor")
	check(room.space_at(p.position+Vector2(0,-2)) == "mon_13","Repair route visits archive ID before innercourt")
	check(await walk(p,11200,"repair route innercourt"),"Repair route reaches innercourt independently of maintenance")
	p.free()
	# A real jump/recoil-sized impulse cannot pass over the complete chapel wall.
	room.set_gate_state("gate_departure",false)
	room.set_gate_state("gate_departure_back",false)
	for height in [1424.0, 2720.0, 3840.0, -1800.0]:
		p = actor(Vector2(13070,height))
		p.velocity = Vector2(480,-720)
		var farthest := p.position.x
		for tick in 150:
			await physics_frame
			var f := frame_for(p); f.move.x = 1
			p.step(f,1.0/60)
			farthest = maxf(farthest,p.position.x)
		check(farthest < 13160,"Solid chapel frame stops aerial bypass at "+str(height))
		p.free()
	room.set_gate_state("gate_lift",false)
	p = actor(Vector2(6160,1408))
	check(not await walk(p,6300,"closed lift shortcut"),"Unrepaired cargo shutter blocks upper shortcut")
	room.set_gate_state("gate_lift",true)
	check(await walk(p,6500,"repaired lift shortcut"),"Repaired cargo shortcut opens physically")
	p.free()
	for home in [true, false]:
		room.set_luggage_home(home)
		await physics_frame
		for site in ["Home", "Cart"]:
			var at: Vector2 = room.story_positions["luggage_"+site.to_lower()]
			var hit := room.get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(at+Vector2(-120,-20),at+Vector2(120,-20),1))
			check(hit.is_empty() != (home == (site == "Home")),"Luggage outcome physically changes shot cover at "+site)
		p = actor(Vector2(10200,1424))
		check(await walk(p,11200,"luggage no-jump crossing"),"Both luggage outcomes retain walking route")
		p.free()
	var first := 0
	var coop := 0
	for marker in room.enemy_spawns:
		if marker.get_meta("encounter_id") == 1:
			first += 1
			check(marker.get_meta("enemy_archetype") == "shield","Opening enemy is a shieldguard")
		if marker.get_meta("encounter_id") == 5: coop += 1
		for npc in room.npc_points:
			if npc.id != "celine": check(marker.position.distance_to(npc.position)>500,"NPC boundary excludes nearby enemy spawn: "+npc.id)
	check(first == 1,"Opening encounter contains exactly one enemy")
	check(coop == 2,"Cooperation encounter contains exactly two staggered enemies")
	world.free()
	print("FLOW LEVEL STAGE RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
