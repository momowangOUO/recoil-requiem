extends SceneTree
## Physical depth and registration checks; visual quality is reviewed in rendered captures.
var checks := 0
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func run() -> void:
	if "--campaign-test" not in OS.get_cmdline_user_args(): quit(2); return
	var app = load("res://scenes/game.tscn").instantiate()
	root.add_child(app)
	var stage: CrimsonStage3D = app.stage
	stage.residency_enabled = false
	stage.residency.clear()
	stage.game.set_physics_process(false)
	stage.game.player.set_physics_process(false)
	var named := {}
	for id in ["HallRecessedTriptych","HallReredos","HallNearWesternStatueFigure","HallNearEasternStatueFigure","BellNearWesternStatueFigure","BellNearEasternStatueFigure","GardenTreeBranches","GardenTreeCrown","GardenIvyWest","GardenIvyEast","GardenRoseLeft","GardenRoseRight","GardenLantern","CargoServiceDoor","CargoCrateFace0","ArchiveBooks"]:
		var found := stage.scenery.find_children(id,"Sprite3D",true,false)
		check(found.size()==1,"Exactly one independent authored part: "+id)
		if found.size()!=1: continue
		var face: Sprite3D = found[0]
		named[id] = face
		check(face.texture_filter==BaseMaterial3D.TEXTURE_FILTER_NEAREST,"Authored part preserves nearest sampling: "+id)
		var rect: Rect2 = face.get_meta("world_rect")
		check(absf(rect.size.x/rect.size.y-face.region_rect.size.x/face.region_rect.size.y)<0.001,"Authored part keeps its aspect ratio: "+id)
		check(face.find_children("*","CollisionObject3D",true,false).is_empty(),"Decoration does not change traversal: "+id)
		if id not in ["HallRecessedTriptych"]:
			check(face.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_ON,"Opaque cutout casts a silhouette onto the physical scene: "+id)
		if id.ends_with("Figure"):
			var bases := stage.scenery.find_children(id.trim_suffix("Figure")+"Plinth","MeshInstance3D",true,false)
			check(bases.size()==1,"Statue has a real supporting plinth")
			if bases.size()==1:
				var bounds: AABB = bases[0].transform*bases[0].get_aabb()
				check(absf(bounds.end.y+rect.end.y*.01)<0.002,"Statue feet meet the plinth")
			var backs := stage.scenery.find_children(id.trim_suffix("Figure")+"NicheBack","MeshInstance3D",true,false)
			check(backs.size()==1 and backs[0].position.z<face.position.z-0.3,"Statue has a recessed niche behind its silhouette")
	if named.has("HallRecessedTriptych") and named.has("HallReredos"):
		check(named.HallRecessedTriptych.position.z<named.HallReredos.position.z-0.4,"Glass sits behind the separately authored shrine")
		check(stage.scenery.find_children("HallWindowReveal*","MeshInstance3D",true,false).size()>=4,"Real reveals bridge the glass recess")
	if named.has("GardenTreeBranches") and named.has("GardenTreeCrown"):
		check(named.GardenTreeBranches.position.z<named.GardenTreeCrown.position.z-0.2,"Canopy and trunk have separate actual depth")
		var roots: Rect2 = named.GardenTreeBranches.get_meta("world_rect")
		var planters := stage.scenery.find_children("GardenTreePlanter","MeshInstance3D",true,false)
		check(planters.size()==1,"Tree is grounded in a real planter")
		if planters.size()==1:
			var bounds: AABB = planters[0].transform*planters[0].get_aabb()
			check(absf(bounds.position.y+5.88)<0.001 and absf(bounds.end.y+roots.end.y*.01)<0.002,"Planter touches floor and roots touch planter")
		check(stage.scenery.find_children("GardenNearRedTree","MeshInstance3D",true,false).is_empty(),"Old combined tree artwork is removed")
	for lamp in stage.scenery.find_children("CourtyardLampWindowLight*","OmniLight3D",true,false):
		check(lamp.position.z>-0.9,"Warm facade lamps illuminate real front faces, not the back of the wall")
	for id in ["GardenRoseLeft","GardenRoseRight"]:
		if not named.has(id): continue
		var plants := stage.scenery.find_children(id+"Planter","MeshInstance3D",true,false)
		check(plants.size()==1,"Rose has a physical planted bed")
		if plants.size()==1:
			var bed: AABB = plants[0].transform*plants[0].get_aabb()
			var plant: Rect2 = named[id].get_meta("world_rect")
			check(absf(bed.position.y+5.88)<0.001 and absf(bed.end.y+plant.end.y*.01)<0.002,"Rose bed meets ground and stems meet soil")
	if named.has("GardenLantern"):
		var lamps := stage.scenery.find_children("GardenLanternWindowLight*","OmniLight3D",true,false)
		check(lamps.size()==1,"Visible lantern owns one actual light source")
		if lamps.size()==1:
			var lamp_center := Vector2(lamps[0].position.x,-lamps[0].position.y)*100
			var face: Rect2 = named.GardenLantern.get_meta("world_rect")
			check(lamp_center.distance_to(face.get_center())<6 and lamps[0].position.z>named.GardenLantern.position.z,"Warm light matches the visible lantern rather than an empty wall")
	var shelves := stage.scenery.find_children("CargoFreightShelf","MeshInstance3D",true,false)
	check(shelves.size()==1,"Rear cargo boxes have a physical storage shelf")
	if shelves.size()==1:
		var shelf: AABB = shelves[0].transform*shelves[0].get_aabb()
		for index in [0,1]:
			var bodies := stage.scenery.find_children("CargoCrateBody"+str(index),"MeshInstance3D",true,false)
			check(bodies.size()==1,"Crate owns a physical body")
			if bodies.size()!=1: continue
			var bounds: AABB = bodies[0].transform*bodies[0].get_aabb()
			check(absf(bounds.position.y-shelf.end.y)<0.002,"Cargo box rests on its shelf")
			check(bounds.position.x>=shelf.position.x and bounds.end.x<=shelf.end.x and bounds.position.z>=shelf.position.z and bounds.end.z<=shelf.end.z,"Shelf supports the whole box footprint")
	app.free()
	print("MONASTERY POLISH STAGE RESULT: %d checks, %d failures; rendered review required" % [checks,failures])
	quit(1 if failures else 0)
