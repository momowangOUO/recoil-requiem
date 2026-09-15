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
	app.free()
	print("IMAGE VISUAL STAGE RESULT: stair surface error <= 6px, open flights=", open_count, ", failures=", failures)
	quit(1 if failures else 0)
