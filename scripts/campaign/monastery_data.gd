extends RefCounted
const Quest = preload("res://scripts/campaign/quest_definition.gd")
const TEXT_PATH := "res://data/campaign/monastery_text.json"
const NAMES := {"player":"莉芙", "mara":"玛拉", "ina":"伊娜", "ruka":"鲁卡", "vira":"维拉", "celine":"赛琳"}
const SPACE_NAMES := ["运输站", "装卸入口", "外庭", "西侧廊", "装卸间", "上层走廊", "货梯间", "中央庭院", "钟台", "地下货道", "泵房", "维护道", "档案走廊", "内庭", "装车礼堂", "后门"]
const FACTS := ["met_mara", "met_vira", "met_ina", "met_ruka", "met_celine", "inner_reached", "departed", "celine_defeated", "vira_dead", "returned", "tools_ina", "tools_mara", "records_ruka", "records_mara", "luggage_home", "luggage_cart", "luggage_request", "gate_entry", "gate_west", "gate_east", "gate_return"]
const EVIDENCE := ["tools", "records", "luggage"]

static func texts() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(TEXT_PATH))

static func catalog() -> Dictionary:
	var facts: Array = FACTS.duplicate()
	facts.append("boss_met")
	facts.append("celine_helped")
	facts.append("celine_returned")
	for id in texts():
		var parts: PackedStringArray = str(id).split(".")
		if parts.size() > 2 and NAMES.has(parts[1]) and parts[1] != "player": facts.append("heard_"+id)
	var regions: Array = []
	var checkpoints: Dictionary = {}
	for i in range(1, 17):
		var id := "mon_%02d" % i
		regions.append(id)
		checkpoints["cp_" + id] = id
		facts.append("clear_%02d" % i)
	return {"facts":facts,"evidence":EVIDENCE.duplicate(),"regions":regions,"checkpoints":checkpoints}

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
