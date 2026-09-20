extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var failures := 0
	for path in ["res://scenes/game.tscn", "res://assets/characters/npcs/mara_idle_v2.png", "res://assets/ui/campaign/campaign_atlas.png", "res://assets/environments/crimson/chapel_window_v1.png", "res://assets/environments/crimson/castle_haze.gdshader"]:
		if load(path) == null:
			push_error("Missing exported resource: " + path)
			failures += 1
	var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://data/campaign/monastery_text.json"))
	if not parsed is Dictionary or parsed.is_empty(): failures += 1
	var packed = load("res://scenes/rooms/image_monastery.tscn")
	if packed == null:
		failures += 1
	else:
		var room = packed.instantiate()
		if room.get_meta("world_bounds").size.x != 16384: failures += 1
		if room.get_node("Gameplay/S09").get("one_way") != true: failures += 1
		if room.get_node("Gameplay/S02").get("one_way") != false: failures += 1
		room.free()
	for path in ["res://dev-design/README.md", "res://tests/test_campaign_state.gd", "res://tools/skills/game-story-workflow/SKILL.md"]:
		if FileAccess.file_exists(path):
			push_error("Development file leaked into export: " + path)
			failures += 1
	print("EXPORT CONTENT CHECK: ", failures, " failures")
	quit(failures)
