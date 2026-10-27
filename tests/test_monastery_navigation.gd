extends "res://tests/run_tests.gd"
## Adversarial exploration, rather than only the memorised critical path.
var lab: RecoilLab

func run() -> void:
	lab = load("res://scenes/crimson_slice.tscn").instantiate()
	lab.campaign_enabled = true
	root.add_child(lab)
	await process_frame
	lab.campaign_session.autosave = false
	lab.player.manual_control = true
	for enemy in lab.enemies: enemy.process_mode = Node.PROCESS_MODE_DISABLED
	# Independent starts at real walkable surfaces. Input is continuous inside each case.
	for example in [
		["pump west edge", Vector2(820,802), -1.0],
		["catch east edge", Vector2(2620,832), 1.0],
		["hall lower west edge", Vector2(2960,912), -1.0]
	]:
		lab.player.position = example[1]
		lab.player.velocity = Vector2.ZERO
		for tick in 18:
			await physics_frame
			lab.player.step(InputFrame.new(), 1.0/60)
		var health := lab.player.health
		var snapshot: Dictionary = lab.campaign_session.state.snapshot()
		var player := lab.player
		var lowest := player.position.y
		for tick in 180:
			await physics_frame
			if not is_instance_valid(player) or lab.player != player: break
			var frame := InputFrame.new()
			frame.move.x = example[2]
			player.step(frame, 1.0/60)
			lowest = maxf(lowest,player.position.y)
			if lab.player != player: break
		check(lab.player == player, str(example[0])+" does not reset the entire map")
		check(lowest < float(example[1].y)+120, str(example[0])+" stays in its local room; lowest="+str(lowest))
		check(lab.player.health == health, str(example[0])+" never heals or damages via recovery")
		check(lab.campaign_session.state.snapshot().facts == snapshot.facts, str(example[0])+" preserves quest facts")
		lab.player.manual_control = true
	for npc in lab.environment.npc_points:
		var hit := lab.environment.get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(npc.position+Vector2(0,-2),npc.position+Vector2(0,6),1|1024))
		check(not hit.is_empty() and hit.normal.y < -0.98, "Conversation takes place on a flat landing: "+npc.id)
		for checkpoint in lab.environment.checkpoints:
			check(npc.position.distance_to(checkpoint.position) >= 30,"Loading a checkpoint never places the player inside "+npc.id+": "+checkpoint.id)
	for id in ["vira_after","celine_after","celine_return"]:
		var point: Vector2 = lab.environment.story_positions[id]
		var hit := lab.environment.get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(point-Vector2(0,2),point+Vector2(0,8),1|1024))
		check(not hit.is_empty() and hit.normal.y < -0.98,"Later conversation has flat ground: "+id)
	var departure: Vector2 = lab.environment.get_node("Gameplay/Action_departure").position
	check(departure.distance_to(lab.environment.story_positions.vira_after) >= 56,"Vira and the departure control have separate interaction positions")
	for checkpoint in lab.environment.checkpoints:
		for enemy in lab.environment.enemy_spawns:
			check(checkpoint.position.distance_to(enemy.position) >= 64,"Checkpoint has room before an enemy: "+checkpoint.id+"/"+str(enemy.name))
	lab.player.position = Vector2(820,802)
	lab.player.velocity = Vector2.ZERO
	for tick in 18:
		await physics_frame
		lab.player.step(InputFrame.new(),1.0/60)
	lab.player.health = 3
	lab.player.weapons.current().ammo = 2
	var player := lab.player
	for tick in 150:
		await physics_frame
		if lab.player != player: break
		var frame := InputFrame.new()
		frame.move.x = -1 if lab.fall_recoveries == 0 else 0
		frame.jump_pressed = tick == 0
		frame.aim_world = player.aim_origin()+Vector2(0,200)
		frame.fire_pressed = tick == 1
		frame.fire_held = tick == 1
		player.step(frame,1.0/60)
	check(lab.player == player and lab.fall_recoveries > 0,"Jumping over a local edge returns to a nearby reliable footing")
	check(lab.player.health == 3 and lab.player.weapons.current().ammo == 1,"Fall recovery preserves damaged health and the ammunition left after the recoil jump")
	lab.player.position = Vector2(1728,642)
	lab.player.velocity = Vector2.ZERO
	for tick in 18:
		await physics_frame
		lab.player.step(InputFrame.new(),1.0/60)
	check(lab.campaign_session.nearest().get("id","") == "vira", "First meeting is reachable across the closed freight gate without the repair prompt taking focus")
	check(lab.campaign_session.npc_actors.vira.position.x > lab.environment.gates.gate_lift.position.x+24,"Vira starts on her own side of the locked freight door")
	var session = lab.campaign_session
	session.event("met_celine")
	for enemy in lab.enemies: enemy.target = null
	lab.combat_timer = 0
	session.ally_cooldown = 0
	session.ally_cover(1.0)
	check(lab.combat_timer == 0 and not session.has("celine_helped"),"An ally never keeps a safe conversation in combat by shooting inactive guards")
	lab.set_physics_process(false)
	for enemy in lab.enemies: enemy.process_mode = Node.PROCESS_MODE_DISABLED
	for module in lab.environment.modules:
		if not module.one_way or not module.get_meta("route_surface",false) or module.width < 32: continue
		lab.player.position = module.position+Vector2(module.width*0.5,0)
		lab.player.velocity = Vector2.ZERO
		for tick in 300:
			await physics_frame
			lab._recover_campaign_fall()
			var frame := InputFrame.new()
			frame.drop_pressed = tick > 20 and tick < 200 and tick%20 == 0
			lab.player.step(frame,1.0/60)
		check(lab.player.position.y < lab.environment.bounds.end.y and lab.player.is_on_floor(),"Repeated S drops settle on a local floor: "+str(module.name))
	lab.player.position = Vector2(900,802)
	lab.player.velocity = Vector2.ZERO
	for destination in [788.0,1250.0]:
		var direction := signf(destination-lab.player.position.x)
		for tick in 360:
			await physics_frame
			var frame := InputFrame.new()
			frame.move.x = direction
			lab.player.step(frame,1.0/60)
			lab._recover_campaign_fall()
			if direction*(destination-lab.player.position.x) < 0: break
	check(lab.player.position.x >= 1240 and lab.player.position.y < 600,"Pump return climbs the visible entry stair with walking input only")
	session.talk("vira")
	session.close()
	var vira: Node2D = session.npc_actors.vira
	vira.set_process(false)
	var penetrations := 0
	for tick in 1100:
		await physics_frame
		vira._process(1.0/60)
		var query := PhysicsPointQueryParameters2D.new()
		query.position = vira.position-Vector2(0,1)
		query.collision_mask = 1 # Open grates allow upward passage, as they do for the player.
		var overlaps := lab.player.get_world_2d().direct_space_state.intersect_point(query)
		if not overlaps.is_empty():
			if penetrations < 4: print("NPC FOOT OVERLAP ",vira.position," ",overlaps[0].collider.get_parent().name)
			penetrations += 1
	check(penetrations == 0,"Vira's continuous departure never walks through locked walls or luggage")
	check(vira.position.distance_to(lab.environment.story_positions.vira_after) < 1,"Vira reaches her separate flat conversation position")
	lab.free()
	print("MONASTERY NAVIGATION STAGE RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
