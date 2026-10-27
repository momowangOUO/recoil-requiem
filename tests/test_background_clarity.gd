extends SceneTree
## Texture registration checks; perceived clarity still requires actual-camera review.
const SLICES := {"Tower":Vector2(2376,156),"Gate":Vector2(704,512),"Hall":Vector2(3560,488),"Archive":Vector2(1688,452),"Garden":Vector2(2648,588)}
var checks := 0
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func run() -> void:
	if "--campaign-test" not in OS.get_cmdline_user_args(): quit(2); return
	var app = load("res://scenes/game.tscn").instantiate()
	root.add_child(app)
	var stage: CrimsonStage3D = app.stage
	stage.frozen_camera = true
	stage.residency_enabled = false
	stage.residency.clear()
	stage.game.set_physics_process(false)
	stage.game.player.manual_control = true
	stage.game.player.set_physics_process(false)
	app.chapter_staging.enabled = false
	for spec in preload("res://scripts/rooms/compact_monastery_visual.gd").PANELS:
		var walls := stage.scenery.find_children(spec.id+"RearMasonryFace","MeshInstance3D",true,false)
		check(walls.size()==1,"Exactly one registered rear face: "+spec.id)
		if walls.is_empty(): continue
		var wall: MeshInstance3D = walls[0]
		var rect: Rect2 = wall.get_meta("world_rect")
		var expected: Rect2 = wall.get_meta("reference_source")
		check(rect.position.distance_to(ImageMonastery.source_to_world(expected.position))<0.01 and rect.size.distance_to(expected.size*2)<0.01,"Facade follows accepted source registration: "+spec.id)
		check(wall.material_override.texture_filter==BaseMaterial3D.TEXTURE_FILTER_NEAREST,"No linear filtering on near architecture")
		check(wall.get_aabb().size.distance_to(Vector3(rect.size.x*.01,rect.size.y*.01,0))<0.001,"Declared density agrees with actual mesh")
		check(float(wall.get_meta("logical_per_texel"))<=1.0,"Near texture has at least one authored source texel per logical pixel")
		var parts := stage.scenery.find_children(spec.id+"*","MeshInstance3D",true,false).filter(func(n): return n.has_meta("architectural_part"))
		check(parts.size()>=2,"Building uses detached architectural parts: "+spec.id)
		for part in parts:
			check(part.get_aabb().end.z>wall.get_aabb().end.z+0.25,"Architectural part projects from rear masonry")
			check(part.find_children("*","CollisionObject3D",true,false).is_empty(),"Painted detail cannot invent walkable surfaces")
	check(stage.scenery.find_children("GatePassageSideWall*","MeshInstance3D",true,false).size()==2,"Gate passage has two real side walls")
	check(stage.scenery.find_children("GreenhouseSlopedGlass","MeshInstance3D",true,false).size()==1,"Glass roof is a separate real sloping surface")
	for id in ["gate_lift","gate_departure"]:
		var gate = stage.game.environment.gates[id]
		var pieces: Array = stage.platform_visuals[gate]
		check(pieces.any(func(n):return str(n.name).ends_with("MovingDoor")),"Illustrated door leaf belongs to its actual collision gate: "+id)
		stage.game.environment.set_gate_state(id,true)
		stage._physics_process(0)
		check(pieces.all(func(n):return not n.visible),"Opening a gate removes both 3D barrier and painted closed leaf")
	if DisplayServer.get_name()!="headless" and "--capture" in OS.get_cmdline_user_args(): await capture(app)
	app.free()
	print("BACKGROUND CLARITY STAGE RESULT: %d registration checks, %d failures; visual approval is separate" % [checks,failures])
	quit(1 if failures else 0)
func capture(app) -> void:
	var stage: CrimsonStage3D = app.stage
	var points: Dictionary = SLICES.duplicate()
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/campaign/monastery_map_ui.json"))
	for id in data.label_anchors:
		points[id] = Vector2(data.label_anchors[id][0],data.label_anchors[id][1])
	if "--archive-only" in OS.get_cmdline_user_args(): points = {"Archive":SLICES.Archive}
	if "--garden-only" in OS.get_cmdline_user_args(): points = {"Garden":SLICES.Garden, "GardenWest":Vector2(10120,1424), "GardenEast":Vector2(11720,1424), "GardenUpper":Vector2(10800,1160)}
	DirAccess.make_dir_recursive_absolute("res://artifacts/background_clarity")
	for id in points:
		var sheet := Image.create(1920,720,false,Image.FORMAT_RGBA8)
		var index := 0
		for gun in CrimsonStage3D.WEAPON_CAMERA:
			for extent in ["near","far"]:
				stage.game.player.position = points[id]
				stage.camera_target = CrimsonStage3D.to_stage(points[id]+Vector2(0,-52))
				stage.camera.position = stage.camera_target+Vector3(0.12,1.18,CrimsonStage3D.WEAPON_CAMERA[gun][extent])
				stage.camera.look_at(stage.camera_target)
				for frame in 3: await process_frame
				await RenderingServer.frame_post_draw
				var pixels: Image = app.stage_viewport.get_texture().get_image()
				pixels.convert(Image.FORMAT_RGBA8)
				pixels.save_png("res://artifacts/background_clarity/%s_%s_%s.png" % [id,gun,extent])
				sheet.blit_rect(pixels,Rect2i(0,0,640,360),Vector2i((index/2)*640,(index%2)*360))
				index += 1
			sheet.save_png("res://artifacts/background_clarity/%s_six_views.png" % id)
	print("Captured %d positions across all six weapon camera distances" % points.size())
