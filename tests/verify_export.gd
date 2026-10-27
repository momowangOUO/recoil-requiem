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
	for arg in OS.get_cmdline_user_args():
		if not arg.begins_with("--review-root="): continue
		var draft_root := arg.trim_prefix("--review-root=")
		var expected := {}
		for line in FileAccess.get_file_as_string(draft_root.path_join("monastery-navigation-2026-10-27-review.md")).split("\n"):
			var fields := line.split("|")
			if line.begins_with("|mon."): expected[fields[1]] = fields[2].replace("<br>","\n")
			elif fields.size() == 5 and cues.has(fields[1]):
				if cues[fields[1]].title != fields[2] or cues[fields[1]].subtitle != fields[3]: failures += 1
		if expected != parsed: failures += 1
		var system_copy := {
			"player_menu":load("res://scripts/ui/player_flow_ui.gd").COPY,
			"campaign_ui":load("res://scripts/ui/campaign_ui.gd").COPY,
			"quest_status":load("res://scripts/ui/campaign_ui.gd").STATUS_COPY,
			"save_status":load("res://scripts/campaign/campaign_session.gd").SAVE_COPY,
			"hud":JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/hud_text.json")),
			"developer_settings":JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/settings_text.json")),
			"character_names":load("res://scripts/campaign/monastery_data.gd").NAMES
		}
		if system_copy != JSON.parse_string(FileAccess.get_file_as_string(draft_root.path_join("player-text-2026-10-27-review.json"))): failures += 1
	var map_ui = JSON.parse_string(FileAccess.get_file_as_string("res://data/campaign/monastery_map_ui.json"))
	if not map_ui is Dictionary or map_ui.get("label_anchors", {}).size() != 16: failures += 1
	var packed = load("res://scenes/rooms/image_monastery.tscn")
	if packed == null:
		failures += 1
	else:
		var room = packed.instantiate()
		if room.get_meta("world_bounds").size.x != 4096 or room.get_meta("layout_revision") != 2: failures += 1
		if room.get_node("Gameplay/S11").get("one_way") != true: failures += 1
		if room.get_node("Gameplay/S02").get("one_way") != false: failures += 1
		var routes := {}
		for node in room.get_node("Gameplay").get_children():
			if node.get_meta("route_surface",false) and not str(node.name).begins_with("Luggage"): routes[str(node.name)]=true
		if map_ui.segments.size()!=routes.size(): failures += 1
		for segment in map_ui.segments:
			if not routes.has(segment.id): failures += 1
		room.free()
	var rebuilt := {"monastery_architecture_v2":Vector2i(2048,768),"rebuild_gate_near":Vector2i(1454,1082),"rebuild_cargo_near":Vector2i(1337,1176),"rebuild_bell_near":Vector2i(1229,1280),"rebuild_garden_near":Vector2i(989,1590),"rebuild_hall_near":Vector2i(1533,1026),"rebuild_gate_arch_v1":Vector2i(1126,1397)}
	for name in rebuilt:
		var texture = load("res://assets/environments/crimson/"+name+".png")
		if texture == null: failures += 1; continue
		var pixels: Image = texture.get_image()
		if pixels.get_size()!=rebuilt[name] or pixels.get_format()!=Image.FORMAT_RGBA8: failures += 1
	for key in preload("res://scripts/rooms/compact_monastery_visual.gd").DETAIL_ART:
		var art: Dictionary = preload("res://scripts/rooms/compact_monastery_visual.gd").DETAIL_ART[key]
		var pixels: Image = art.texture.get_image()
		var crop: Rect2 = art.source
		if pixels==null or not Rect2(Vector2.ZERO,Vector2(pixels.get_size())).encloses(crop):
			push_error("Polished artwork or its authored crop is missing: "+key)
			failures += 1
		elif key!="books" and pixels.get_format()!=Image.FORMAT_RGBA8: failures += 1
	for path in ["res://dev-design/README.md", "res://tests/test_campaign_state.gd", "res://tools/skills/game-story-workflow/SKILL.md", "res://assets/ui/v2/source/ui_panels_v1.png", "res://assets/ui/v2/source/ui_map_concept_v1.png"]:
		if FileAccess.file_exists(path):
			push_error("Development file leaked into export: " + path)
			failures += 1
	print("EXPORT CONTENT CHECK: ", failures, " failures")
	quit(failures)
