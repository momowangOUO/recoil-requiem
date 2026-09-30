extends SceneTree
## Authored density and six-camera sweep; never changes gameplay geometry.
const SLICES := {
	"Tower": Vector2(9592,932.8), "Gate": Vector2(2100,294),
	"Hall": Vector2(13800,1424), "Archive": Vector2(6800,880),
	"Garden": Vector2(10800,1424)
}
var checks := 0
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func run() -> void:
	if not "--campaign-test" in OS.get_cmdline_user_args(): quit(2); return
	var app = load("res://scenes/game.tscn").instantiate()
	root.add_child(app)
	var stage: CrimsonStage3D = app.stage
	stage.frozen_camera = true
	stage.residency_enabled = false
	stage.residency.clear()
	stage.game.player.manual_control = true
	stage.game.player.set_physics_process(false)
	for enemy in stage.game.enemies: enemy.set_physics_process(false)
	for id in stage.game.campaign_session.npc_actors:
		stage.game.campaign_session.npc_actors[id].set_process(false)
	for id in SLICES:
		var cards := stage.scenery.find_children("Clarity%s*" % id, "MeshInstance3D", true, false)
		var covered := false
		check(not cards.is_empty(), "Authored near building detail exists: " + id)
		for card in cards:
			if not card.has_meta("clarity_world_rect"): continue
			var rect: Rect2 = card.get_meta("clarity_world_rect")
			var source: Rect2 = card.get_meta("clarity_source_rect")
			var density := source.size / rect.size
			var probe: Vector2 = SLICES[id] - Vector2(220 if id == "Hall" else 0,120)
			covered = covered or rect.has_point(probe)
			check(density.x >= 1.99 and density.y >= 1.99, "Near detail has at least two source texels per logical pixel: " + str(card.name))
			if str(card.name).begins_with("ClarityGarden") and str(card.name).ends_with("Glass"):
				check(card.get_aabb().size.x <= rect.size.x*0.01 + 0.0001 and card.get_aabb().size.y <= rect.size.y*0.01 + 0.0001, "Glass with removed frame strips stays within original window")
			else:
				check(card.get_aabb().size.distance_to(Vector3(rect.size.x*0.01,rect.size.y*0.01,0)) < 0.0001, "Actual mesh matches declared density bounds")
			check(card.material_override.texture_filter == BaseMaterial3D.TEXTURE_FILTER_NEAREST, "Paper detail remains nearest sampled")
			check(card.get_aabb().end.z <= -1.0, "Paper detail stays behind the actor and rear rail")
			check(card.find_children("*", "CollisionObject3D", true, false).is_empty(), "Detail has no new collision")
		check(covered, "Existing rear building is detailed beside the slice's player position: " + id)
	var garden_glass := stage.scenery.find_children("ClarityGarden*Glass", "MeshInstance3D", true, false)
	check(garden_glass.size() == 5, "Near greenhouse preserves exactly five broad window bays")
	var old_glass := stage.scenery.find_children("GardenLayeredWindow*Glass", "Sprite3D", true, false)
	for index in garden_glass.size():
		var card: MeshInstance3D = garden_glass[index]
		var original: Sprite3D = old_glass[index]
		var opening: Rect2 = card.get_meta("original_window")
		check((Vector2(original.position.x,-original.position.y)*100).distance_to(opening.get_center()) < 0.01, "Close glass keeps the original window centre")
		check((original.region_rect.size*original.pixel_size*100).distance_to(opening.size) < 0.01, "Close glass keeps the original window size")
		check(card.get_aabb().end.z < card.get_meta("wall_z"), "Close glass is recessed behind wall")
		check(stage.scenery.find_children("ClarityGarden%dFrame*" % index, "MeshInstance3D", true, false).size() == 12, "Authored metal rails occupy an independent front layer")
	for stair in stage.game.environment.stairs:
		if stair.one_way:
			check(stage.scenery.find_children(str(stair.get_meta("structural_id", stair.name))+"ContinuousRearFoundation", "MeshInstance3D", true, false).is_empty(), "Open stairs retain open undersides")
	if DisplayServer.get_name() != "headless" and "--capture" in OS.get_cmdline_user_args():
		await capture(app)
	app.free()
	print("BACKGROUND CLARITY STAGE RESULT: %d checks, %d failures" % [checks,failures])
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
