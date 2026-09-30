extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var failures := 0
	for path in ["res://assets/ui/v2/runtime/chapter_comic_plate.png", "res://assets/environments/crimson/archive_bookshelf_v1.png", "res://assets/environments/crimson/garden_close_bay_v1.png", "res://assets/characters/npcs/mara_story_v1.png", "res://assets/characters/npcs/vira_story_v1.png"]:
		if load(path) == null:
			push_error("Missing chapter resource: " + path)
			failures += 1
	var cues = JSON.parse_string(FileAccess.get_file_as_string("res://data/campaign/chapter_staging.json"))
	if not cues is Dictionary or cues.size() != 17: failures += 1
	for path in ["res://assets/characters/npcs/chapter_actions_source_v1.png", "res://assets/ui/v2/source/chapter_arrival_concept.png", "res://dev-design/flow-review/chapter-board-01-04.png", "res://dev-design/levels/image-led/clarity-20260930/garden-close-source.png"]:
		if FileAccess.file_exists(path): failures += 1
	for path in ["res://assets/ui/v2/runtime/map_elevations_v2.png", "res://assets/ui/v2/runtime/map_station_v2.png", "res://assets/ui/v2/runtime/title_stage_v1.png", "res://assets/ui/v2/runtime/title_hero_poses_v2.png", "res://assets/ui/v2/runtime/dialogue_portraits_v1.png", "res://assets/ui/v2/runtime/quest_station_v1.png", "res://assets/ui/v2/runtime/quest_routes_v1.png", "res://assets/ui/v2/runtime/quest_departure_v1.png", "res://assets/environments/crimson/garden_facade_v2.png", "res://assets/environments/crimson/close_facade_bays_v1.png"]:
		if load(path) == null:
			push_error("Missing new exported artwork: " + path)
			failures += 1
	for path in ["res://data/campaign/monastery_map_art.json", "res://data/campaign/title_hero_poses.json", "res://data/campaign/dialogue_art.json"]:
		if not JSON.parse_string(FileAccess.get_file_as_string(path)) is Dictionary:
			failures += 1
	for path in ["res://assets/ui/v2/source/dialogue_layout_v3.png", "res://assets/ui/v2/source/dialogue_before_v3.png", "res://assets/ui/v2/source/dialogue_layout_v3.prompt.json", "res://assets/ui/v2/source/title_hero_concept_v1.png", "res://assets/ui/v2/source/title_hero_poses_v1.png", "res://assets/ui/v2/source/ui_map_concept_v2.png", "res://tools/skills/image-led-game-art/SKILL.md"]:
		if FileAccess.file_exists(path): failures += 1
	for path in ["res://scenes/game.tscn", "res://assets/fonts/unifont-18.0.01.otf", "res://assets/environments/crimson/foreground_silhouette.gdshader", "res://assets/characters/npcs/mara_idle_v3.png", "res://assets/characters/npcs/ina_idle_v3.png", "res://assets/characters/npcs/ruka_idle_v3.png", "res://assets/characters/campaign/elite_actions_v2.png", "res://assets/characters/campaign/boss_actions_v2.png", "res://assets/ui/v2/runtime/journal_frame.png", "res://assets/ui/v2/runtime/tracker_frame.png", "res://assets/ui/v2/runtime/weapon_frame.png", "res://assets/ui/v2/runtime/reticle.png", "res://assets/ui/v2/runtime/reload_segment.png", "res://assets/ui/v2/runtime/map_gatehouse.png", "res://assets/environments/crimson/chapel_window_v1.png", "res://assets/environments/crimson/foreground_panorama_v4.png", "res://assets/environments/crimson/industrial_facade_v1.png", "res://assets/environments/crimson/chapel_facade_v1.png", "res://assets/environments/crimson/chapel_grand_facade_v2.png", "res://assets/environments/crimson/bell_pier_facade_v1.png", "res://assets/environments/crimson/gatehouse_facade_v1.png", "res://assets/environments/crimson/quest_props_v1.png", "res://assets/environments/crimson/castle_haze.gdshader"]:
		if load(path) == null:
			push_error("Missing exported resource: " + path)
			failures += 1
	for license_path in ["res://assets/fonts/OFL-Unifont.txt", "res://assets/fonts/COPYRIGHT-Unifont.txt"]:
		if not FileAccess.file_exists(license_path): failures += 1
	var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://data/campaign/monastery_text.json"))
	if not parsed is Dictionary or parsed.is_empty(): failures += 1
	var map_ui = JSON.parse_string(FileAccess.get_file_as_string("res://data/campaign/monastery_map_ui.json"))
	if not map_ui is Dictionary or map_ui.get("segments", []).size() != 73 or map_ui.get("label_anchors", {}).size() != 16 or map_ui.get("transition_visibility", {}).size() != 6: failures += 1
	var packed = load("res://scenes/rooms/image_monastery.tscn")
	if packed == null:
		failures += 1
	else:
		var room = packed.instantiate()
		if room.get_meta("world_bounds").size.x != 16384: failures += 1
		if room.get_node("Gameplay/S09").get("one_way") != true: failures += 1
		if room.get_node("Gameplay/S02").get("one_way") != false: failures += 1
		room.free()
	for path in ["res://dev-design/README.md", "res://tests/test_campaign_state.gd", "res://tools/skills/game-story-workflow/SKILL.md", "res://assets/ui/v2/source/ui_panels_v1.png", "res://assets/ui/v2/source/ui_map_concept_v1.png"]:
		if FileAccess.file_exists(path):
			push_error("Development file leaked into export: " + path)
			failures += 1
	print("EXPORT CONTENT CHECK: ", failures, " failures")
	quit(failures)
