extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if not ResourceLoader.exists("res://scripts/rooms/image_monastery_visual.gd"):
		push_error("Image-led monastery visual builder is missing")
		quit(1)
		return
	var builder = load("res://scripts/rooms/image_monastery_visual.gd").new()
	var failures := 0
	for offset in [Vector2(576, -288), Vector2(-576, -288), Vector2(384, 192)]:
		var samples: Array = builder.stair_samples(Vector2(120, 800), offset, 12.0)
		for step in samples:
			var left_y: float = 800 + (step.left - 120) / offset.x * offset.y
			var right_y: float = 800 + (step.right - 120) / offset.x * offset.y
			if maxf(absf(step.y - left_y), absf(step.y - right_y)) > 6.001:
				failures += 1
	var app = load("res://scenes/game.tscn").instantiate()
	root.add_child(app)
	var stage = app.stage
	stage.residency.clear()
	var castle_count := 0
	for card in stage.night.get_children():
		if card is Sprite3D and card != stage.night.sky and card != stage.night.moon:
			castle_count += 1
			if card.material_override != stage.night.castle_haze:
				push_error("An expanded-map castle layer is missing its lower-edge transition")
				failures += 1
	if castle_count != 6: failures += 1
	var open_count := 0
	for stair in stage.game.environment.stairs:
		if not stair.get("one_way"): continue
		open_count += 1
		var id: String = stair.get_meta("structural_id", str(stair.name))
		if stage.scenery.find_children(id + "OpenTread*", "MeshInstance3D", false, false).is_empty():
			push_error(id + " is passable but has no visible open metal treads")
			failures += 1
		if not stage.scenery.find_children(id + "ClosedStringer*", "MeshInstance3D", false, false).is_empty():
			push_error(id + " is passable but still displays a solid stair shell")
			failures += 1
	if open_count < 6:
		push_error("All six tower flights must use visibly open metal construction")
		failures += 1
	var landing_count := 0
	for module in stage.game.environment.modules:
		if not str(module.name).begins_with("F20_TowerLanding"): continue
		landing_count += 1
		var pieces: Array = stage.platform_visuals[module]
		var rails := pieces.filter(func(n):return str(n.name).contains("RearRailPost"))
		var floors := pieces.filter(func(n):return str(n.name).contains("EdgeGirder"))
		for rail in rails:
			if not touches_any(rail,floors): failures += 1
		for corbel in pieces.filter(func(n):return str(n.name).contains("WallCorbel")):
			if not touches_any(corbel,floors) or not touches_any(corbel,stage.scenery.find_children("BellStairwellRearMasonry","MeshInstance3D",false,false)): failures += 1
	if landing_count != 6: failures += 1
	var carriage: Array = stage.scenery.find_children("StationCarriagePainted", "Sprite3D", false, false)
	if carriage.size() != 1 or stage.scenery.find_children("StationCarriageBody", "MeshInstance3D", false, false).size() != 1:
		push_error("The arrival carriage requires one authored two-wheel face and its depth-bearing body")
		failures += 1
	elif absf(carriage[0].position.y - carriage[0].region_rect.size.y * carriage[0].pixel_size * 0.5 + 5.12) > 0.001:
		push_error("The carriage wheels must touch the real arrival platform")
		failures += 1
	app.free()
	print("IMAGE VISUAL STAGE RESULT: stair surface error <= 6px, open flights=", open_count, ", supported landing checks=", landing_count, ", failures=", failures)
	quit(1 if failures else 0)

func touches_any(node: MeshInstance3D, candidates: Array) -> bool:
	var bounds: AABB = node.global_transform * node.get_aabb()
	for candidate: MeshInstance3D in candidates:
		var other: AABB = candidate.global_transform * candidate.get_aabb()
		if bounds.grow(0.001).intersects(other.grow(0.001)): return true
	return false
