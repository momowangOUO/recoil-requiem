extends "res://tests/run_tests.gd"

func run() -> void:
	var copy: Dictionary = load("res://scripts/campaign/monastery_data.gd").texts()
	var stages: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/campaign/chapter_staging.json"))
	var draft := {}
	var stage_count := 0
	for line in FileAccess.get_file_as_string("res://game-text/monastery-navigation-2026-10-27-review.md").split("\n"):
		var fields := line.split("|")
		if line.begins_with("|mon."):
			draft[fields[1]] = fields[2].replace("<br>","\n")
		elif line.begins_with("|region.mon_"):
			check(load("res://scripts/campaign/monastery_data.gd").SPACE_NAMES[int(fields[1].trim_prefix("region.mon_"))-1] == fields[2],"Map location matches actual area: "+fields[1])
		elif fields.size() == 5 and stages.has(fields[1]):
			stage_count += 1
			check(stages[fields[1]].title == fields[2] and stages[fields[1]].subtitle == fields[3],"Staging matches reviewed text: "+fields[1])
	check(draft == copy,"All decoded campaign text matches the complete current draft")
	check(stage_count == stages.size(),"All chapter cues are reviewed")
	var system_copy := {
		"player_menu":load("res://scripts/ui/player_flow_ui.gd").COPY,
		"campaign_ui":load("res://scripts/ui/campaign_ui.gd").COPY,
		"quest_status":load("res://scripts/ui/campaign_ui.gd").STATUS_COPY,
		"save_status":load("res://scripts/campaign/campaign_session.gd").SAVE_COPY,
		"hud":JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/hud_text.json")),
		"developer_settings":JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/settings_text.json")),
		"character_names":load("res://scripts/campaign/monastery_data.gd").NAMES
	}
	var system_draft: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://game-text/player-text-2026-10-27-review.json"))
	for category in system_copy:
		check(system_copy[category] == system_draft.get(category,{}),"Decoded player text matches reviewed draft: " + category)
	check(copy.has("mon.flow.tutorial.drop"),"The maintenance entrance has a contextual drop instruction")
	var session = load("res://scripts/campaign/campaign_session.gd").new()
	session.autosave = false
	session.state.configure(session.Data.catalog(),session.Data.quests())
	root.add_child(session)
	session.event("tools","evidence")
	check(session.tool_choices()[0][1] == "mon.tools.return.unused.choice","Returning tools before repair explains the remaining pump route")
	session.event("met_mara")
	session.event("met_vira")
	session.select_route("lift")
	session.event("tools_ina")
	check(session.current_main_title_id() == "mon.flow.route.service","Guidance never sends handed-in tools back to the freight repair")
	session.event("lift_repaired")
	session.event("maintenance_open")
	session.select_route("maintenance")
	check(session.current_main_title_id() == "mon.flow.service.safe","An opened maintenance route points up the exit stairs, not back to the entrance")
	session.free()
	print("MONASTERY COPY STAGE RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
