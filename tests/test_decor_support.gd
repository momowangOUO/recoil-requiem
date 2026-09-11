extends SceneTree

var failures := 0
var checks := 0

func _initialize() -> void: run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func supported(stage: CrimsonStage3D, piece: MeshInstance3D) -> bool:
	var bounds := piece.get_aabb()
	var foot := piece.global_position + Vector3(0, bounds.position.y, 0)
	if str(piece.name).begins_with("PillarFoot"):
		for corbel in stage.scenery.find_children("PillarCorbel*", "MeshInstance3D", true, false):
			var base: AABB = corbel.get_aabb()
			if absf(corbel.global_position.x - foot.x) > 0.001: continue
			if absf(corbel.global_position.y + base.end.y - foot.y) > 0.001: continue
			if foot.z + bounds.position.z < corbel.global_position.z + base.position.z: continue
			if foot.z + bounds.end.z > corbel.global_position.z + base.end.z: continue
			return true
		return false
	for module in stage.game.environment.modules:
		if not module.active or module.one_way: continue
		var left: float = module.position.x * 0.01
		var right: float = left + module.width * 0.01
		if absf(foot.y + module.position.y * 0.01) > 0.006: continue
		if foot.x + bounds.position.x < left - 0.001 or foot.x + bounds.end.x > right + 0.001: continue
		if foot.z + bounds.position.z < -1.175 or foot.z + bounds.end.z > 0.675: continue
		return true
	return false

func run() -> void:
	var app = load("res://scenes/game.tscn").instantiate()
	root.add_child(app)
	var stage: CrimsonStage3D = app.stage
	stage.game.player.set_physics_process(false)
	for enemy in stage.game.enemies: enemy.set_physics_process(false)
	var floating: Array[String] = []
	for pillar in stage.scenery.find_children("RearPillar*", "MeshInstance3D", true, false):
		check(pillar.global_position.z + pillar.get_aabb().end.z < -1.175, "Rear columns must remain entirely behind the platform back face")
	for corbel in stage.scenery.find_children("PillarCorbel*", "MeshInstance3D", true, false):
		var attached := false
		for module in stage.game.environment.modules:
			if not module.active or module.one_way or not module.unlock_action.is_empty(): continue
			var top: float = -module.position.y * 0.01
			var bounds: AABB = corbel.get_aabb()
			if absf(corbel.global_position.y + bounds.end.y - top) > 0.001: continue
			if corbel.global_position.x + bounds.position.x < module.position.x * 0.01: continue
			if corbel.global_position.x + bounds.end.x > (module.position.x + module.width) * 0.01: continue
			attached = absf(corbel.global_position.z + bounds.end.z + 1.175) < 0.001
		check(attached, "Column corbels must meet a permanent platform rear face, not float")
	for piece in stage.scenery.find_children("*", "MeshInstance3D", true, false):
		if not piece.is_visible_in_tree(): continue
		if str(piece.name).begins_with("RearRailing") or str(piece.name).begins_with("RosePlanter") or str(piece.name).begins_with("PillarFoot") or str(piece.name).begins_with("ArchiveBack") or str(piece.name).begins_with("ForegroundPillar") or str(piece.name).begins_with("BellPost"):
			if not supported(stage, piece): floating.append(str(piece.get_path()))
	check(floating.is_empty(), "Decor feet must touch a solid platform across their whole footprint; floating count=%d, first=%s" % [floating.size(), floating.slice(0, 3)])
	check(stage.scenery.find_children("Bloodrose*", "MeshInstance3D", true, false).is_empty(), "Roses must no longer be cylinders")
	check(stage.scenery.find_children("RoseBush*", "Sprite3D", true, false).size() >= 3, "Garden must contain authored flat rose sprites")
	check(stage.scenery.find_children("RearRailing*", "MeshInstance3D", true, false).size() > 100, "Contact check must cover actual railing posts, not only one node per section")
	for bush in stage.scenery.find_children("RoseBush*", "Sprite3D", true, false):
		var image: Image = bush.texture.get_image()
		check(image.detect_alpha() != Image.ALPHA_NONE and image.get_pixel(0, 0).a == 0, "Rose source must have genuine transparent background")
		var foot: Vector3 = bush.global_position - Vector3(0, bush.region_rect.size.y * bush.pixel_size * 0.5, 0)
		var attached := false
		for planter in stage.scenery.find_children("RosePlanter*", "MeshInstance3D", true, false):
			if absf(planter.global_position.x - foot.x) < 0.01 and absf(planter.global_position.y + planter.get_aabb().end.y - foot.y) < 0.01:
				attached = true
		check(attached, "Opaque stem baseline must meet the planter rim")
		var clear := true
		var half_width: float = bush.region_rect.size.x * bush.pixel_size * 0.5
		var head_y: float = foot.y + bush.region_rect.size.y * bush.pixel_size
		for module in stage.game.environment.modules:
			var left: float = module.position.x * 0.01
			var right: float = left + module.width * 0.01
			if right <= foot.x - half_width or left >= foot.x + half_width: continue
			var top: float = -module.position.y * 0.01
			var bottom: float = top - module.collision_depth * 0.01
			if top > foot.y + 0.005 and bottom < head_y + 0.25: clear = false
		check(clear, "Entire rose silhouette needs clear space above the planter, including future bridge geometry")
	for active in [true, false]:
		for module in stage.game.environment.modules:
			if not module.unlock_action.is_empty(): module.active = active
		stage._physics_process(0)
		var correct := true
		for module in stage.platform_visuals:
			for piece in stage.platform_visuals[module]:
				if str(piece.name).begins_with("RearRailing"):
					correct = correct and piece.visible == module.active
		check(correct, "Railing visibility follows its unlocked bridge; no posts remain over a closed gap")
	app.free()
	print("DECOR SUPPORT STAGE RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
