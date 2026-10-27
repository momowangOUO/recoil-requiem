extends "res://tests/test_image_monastery_branches.gd"
## Route traversal is covered by test_monastery_rebuild; this fixture checks encounter spaces and movable cover.
func run() -> void:
	world = Node2D.new()
	root.add_child(world)
	room = load("res://scenes/rooms/image_monastery.tscn").instantiate()
	world.add_child(room)
	room.build(3)
	for id in room.gates: room.set_gate_state(id,true)
	for home in [true,false]:
		room.set_luggage_home(home)
		await physics_frame
		for site in ["Home","Cart"]:
			var at: Vector2 = room.story_positions["luggage_"+site.to_lower()]
			var hit := room.get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(at+Vector2(-60,-20),at+Vector2(60,-20),1))
			check(hit.is_empty() != (home == (site == "Home")),"Luggage outcome changes actual shot cover: "+site)
		var p := actor(Vector2(2500,588))
		check(await walk(p,2896,"movable luggage crossing"),"Both luggage choices retain a zero-shot walking route")
		p.free()
	var first := 0
	var coop := 0
	for enemy in room.enemy_spawns:
		if enemy.get_meta("encounter_id")==1: first += 1; check(enemy.get_meta("enemy_archetype")=="shield","Opening guard is a shieldguard")
		if enemy.get_meta("encounter_id")==5: coop += 1
		var patrol: Rect2 = enemy.get_meta("patrol_bounds")
		for npc in room.npc_points:
			if npc.id=="celine": continue
			check(not patrol.grow(24).has_point(npc.position),"Enemy patrol excludes conversation space: "+npc.id)
	check(first==1 and coop==2,"Opening and cooperation encounters retain bounded enemy counts")
	world.free()
	print("FLOW LEVEL STAGE RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
