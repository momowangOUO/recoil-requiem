extends "res://tests/test_background_clarity.gd"
func run() -> void:
	if "--campaign-test" not in OS.get_cmdline_user_args(): quit(2); return
	var app = load("res://scenes/game.tscn").instantiate()
	root.add_child(app)
	var stage: CrimsonStage3D = app.stage
	stage.residency_enabled = false
	stage.residency.clear()
	for flight in stage.game.environment.stairs:
		var id := str(flight.name)
		var pieces: Array = stage.platform_visuals[flight]
		var stringers := pieces.filter(func(n): return str(n.name).contains("ClosedStringer"))
		check(stringers.size()==(0 if flight.one_way else 1),"Only solid stairs own a closed structural shell: "+id)
		if not flight.one_way:
			var bounds: AABB = stringers[0].get_aabb()
			check(bounds.size.z>=0.5,"Solid flight has real thickness: "+id)
			if not id.begins_with("Luggage"):
				check(pieces.filter(func(n):return str(n.name).contains("RearSupportLeg")).size()==2,"Stone flight has two rear supports: "+id)
	for module in stage.game.environment.modules:
		var id := str(module.name)
		if not module.get_meta("route_surface",false) or module.one_way or id.begins_with("Luggage"): continue
		var floors: Array = stage.platform_visuals[module].filter(func(n):return str(n.name).contains("MasonryBody"))
		check(floors.size()==1,"Walking platform owns one 3D body: "+id)
		if floors.is_empty(): continue
		var bounds: AABB = floors[0].transform*floors[0].get_aabb()
		check(absf(bounds.end.y+module.position.y*0.01)<0.001,"Visible standing line agrees with physics: "+id)
		check(bounds.position.z<=-1.69 and bounds.end.z>=0.37,"Deck joins recessed walls and actor plane: "+id)
	for module in stage.game.environment.modules:
		if not str(module.name).begins_with("F20_TowerLanding"): continue
		var pieces: Array = stage.platform_visuals[module]
		check(pieces.filter(func(n):return str(n.name).contains("WallCorbel")).size()==2,"Tower landing is carried by two wall corbels")
		check(pieces.filter(func(n):return str(n.name).contains("RearRailPost")).size()==2,"Tower landing carries its railing")
	app.free()
	print("ARCHITECTURE GROUNDING STAGE RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
