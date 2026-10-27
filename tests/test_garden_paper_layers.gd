extends "res://tests/test_background_clarity.gd"
func run() -> void:
	if "--campaign-test" not in OS.get_cmdline_user_args(): quit(2); return
	var app = load("res://scenes/game.tscn").instantiate()
	root.add_child(app)
	var stage: CrimsonStage3D = app.stage
	stage.residency_enabled = false
	stage.residency.clear()
	stage.game.set_physics_process(false)
	stage.game.player.set_physics_process(false)
	var glazing := stage.scenery.find_children("GreenhouseSlopedGlass","MeshInstance3D",true,false)
	var frames := stage.scenery.find_children("GreenhouseSlopedFrameFace","MeshInstance3D",true,false)
	check(glazing.size()==1 and frames.size()==1,"Greenhouse frame face and glazing are separate")
	if not glazing.is_empty():
		var bounds: AABB = glazing[0].get_aabb()
		check(bounds.size.z>0.9 and bounds.size.y>0.7,"Roof slopes in real depth and height")
		check(glazing[0].material_override.transparency==BaseMaterial3D.TRANSPARENCY_ALPHA,"Glazing transmits the rear scene")
		check(frames[0].material_override.texture_filter==BaseMaterial3D.TEXTURE_FILTER_NEAREST,"Sloping artwork stays nearest sampled")
	var supports := stage.scenery.find_children("GreenhouseSupportColumn*","MeshInstance3D",true,false)
	check(supports.size()==2,"Front roof edge has two real columns")
	for support in supports:
		var bounds: AABB = support.transform*support.get_aabb()
		check(absf(bounds.position.y+5.88)<0.01,"Roof column meets the actual garden floor")
	check(stage.scenery.find_children("GreenhouseRoofRafter*","MeshInstance3D",true,false).size()==4,"Real rafters connect front and rear roof edges")
	for id in ["HangingBanner","GreenhouseCornice","GreenhouseSill"]:
		check(stage.scenery.find_children("GardenNear"+id,"MeshInstance3D",true,false).size()==1,"Garden part has independent depth: "+id)
	for id in ["GardenTreeBranches","GardenTreeCrown","GardenTreePlanterPaintedFront"]:
		check(stage.scenery.find_children(id,"Sprite3D",true,false).size()==1,"Tree and planter use independently authored faces: "+id)
	check(stage.scenery.find_children("GardenNearRecessedGlass*","Sprite3D",true,false).size()==1,"Garden doorway glass is recessed separately from the roof")
	stage.game.reset_trial(3)
	check(stage.scenery.find_children("GreenhouseSlopedGlass","MeshInstance3D",true,false).size()==1,"Reset does not duplicate glazing")
	app.free()
	print("GARDEN PAPER LAYERS STAGE RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
