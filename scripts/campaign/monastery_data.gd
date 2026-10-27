extends RefCounted
const Quest = preload("res://scripts/campaign/quest_definition.gd")
const TEXT_PATH := "res://data/campaign/monastery_text.json"
const NAMES := {"player":"莉芙", "mara":"玛拉", "ina":"伊娜", "ruka":"鲁卡", "vira":"维拉", "celine":"赛琳"}
const SPACE_NAMES := ["运输站", "门楼", "装卸庭", "门楼上廊", "装卸台", "货场上廊", "货梯口", "钟楼庭院", "钟台", "地下货道", "泵房", "维护道", "档案室", "花棚内庭", "礼堂前廊", "礼堂"]
const FACTS := ["met_mara", "met_vira", "met_ina", "met_ruka", "met_celine", "inner_reached", "departed", "celine_defeated", "vira_dead", "returned", "tools_ina", "tools_mara", "records_ruka", "records_mara", "luggage_home", "luggage_cart", "luggage_request", "gate_entry", "gate_west", "gate_east", "gate_return"]
const EVIDENCE := ["tools", "records", "luggage"]

static func texts() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(TEXT_PATH))

static func text_speaker(id: String) -> String:
	if id == "mon.flow.celine.job": return "celine"
	var parts := id.split(".")
	return parts[1] if parts.size() > 2 and NAMES.has(parts[1]) else ""

static func onboarding_ui() -> Dictionary:
	var copy := texts()
	var result := {
		"objective": str(copy.get("mon.main01.title", "")),
		"speaker": str(NAMES.player),
		"lines": [str(copy.get("mon.opening.target", "")), str(copy.get("mon.flow.opening.intent", ""))],
		"opening_controls": str(copy.get("mon.ui.opening_controls", "")),
		"controls": str(copy.get("mon.ui.controls", "")),
		"completed": str(copy.get("mon.ui.completed", "已完成：{objective}")),
		"end_talk": str(copy.get("mon.ui.end_talk", "结束交谈 · Esc")),
		"interact": str(copy.get("mon.ui.interact", "E　{action}{target}"))
	}
	for action in ["move", "jump", "shoot", "reload", "claw", "switch", "map", "shotgun", "smg", "drop"]:
		result["tutorial_" + action] = str(copy.get("mon.flow.tutorial." + action, ""))
	for key in ["key_space", "key_mouse_1", "key_mouse_2"]: result[key] = str(copy.get("mon.flow." + key, ""))
	return result

static func main_title_id(facts: Variant) -> String:
	if "returned" in facts: return "mon.exit.title"
	if "vira_dead" in facts: return "mon.main07.title"
	if "celine_defeated" in facts: return "mon.main06.title"
	if "departed" in facts: return "mon.main05.title"
	# Exploration is allowed out of order; guidance still points to the missing first meetings.
	if not "met_mara" in facts: return "mon.main01.title"
	if not "met_vira" in facts: return "mon.main02.title"
	if "inner_reached" in facts: return "mon.main04.title"
	return "mon.main03.title"

static func interaction_prompt(id: String, npc: bool, known_npc: bool = false) -> Dictionary:
	if npc:
		return {"action":"交谈", "target":str(NAMES.get(id, "")) if known_npc else ""}
	var key := id
	var action := "使用"
	if id == "tools" or id == "luggage": action = "调查"
	elif id == "records": action = "阅读"
	elif id == "departure": action = "操作"
	elif id == "exit": action = "查看"
	elif id.ends_with("_travel"): key = "shortcut"
	elif id.begins_with("gate_"):
		key = "gate"
		action = "开启"
	var copy := texts()
	return {"action":action, "target":str(copy.get("mon.action." + key, "机关"))}

static func catalog() -> Dictionary:
	var facts: Array = FACTS.duplicate()
	var staging: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/campaign/chapter_staging.json"))
	for id in staging: facts.append("stage_"+id)
	facts.append_array(["lift_repaired", "maintenance_open", "repair_explained", "vira_relocated", "celine_observed", "opening_seen"])
	for action in ["move", "jump", "shoot", "reload", "claw", "switch", "map", "drop"]: facts.append("tutorial_" + action)
	facts.append("boss_met")
	facts.append("celine_helped")
	facts.append("celine_returned")
	for id in texts():
		var who := text_speaker(str(id))
		if not who.is_empty() and who != "player": facts.append("heard_"+id)
	var regions: Array = []
	var checkpoints: Dictionary = {}
	for i in range(1, 17):
		var id := "mon_%02d" % i
		regions.append(id)
		checkpoints["cp_" + id] = id
		facts.append("clear_%02d" % i)
	return {"facts":facts,"evidence":EVIDENCE.duplicate(),"regions":regions,"checkpoints":checkpoints,"routes":["lift","maintenance"]}

static func quests() -> Array:
	var result: Array = []
	var rows := [
		["mon_main_01", [], ["met_mara"]],
		["mon_main_02", ["met_mara"], ["met_vira"]],
		["mon_main_03", ["met_vira"], ["inner_reached"]],
		["mon_main_04", ["inner_reached"], ["departed"]],
		["mon_main_05", ["departed"], ["celine_defeated"]],
		["mon_main_06", ["celine_defeated"], ["vira_dead"]],
		["mon_main_07", ["vira_dead"], ["returned"]]
	]
	for row in rows:
		var q := Quest.new()
		q.quest_id = row[0]
		q.prerequisite_flags = PackedStringArray(row[1])
		q.objective_flags = PackedStringArray(row[2])
		result.append(q)
	return result
