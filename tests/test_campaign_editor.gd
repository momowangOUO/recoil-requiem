extends SceneTree
const Validator = preload("res://addons/recoil_map_editor/room_validator.gd")
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func has_error(room: Node, fragment: String) -> bool:
	for error in Validator.validate(room):
		if fragment in error: return true
	return false
func run() -> void:
	var room = load("res://scenes/rooms/monastery_campaign.tscn").instantiate()
	var errors := Validator.validate(room)
	check(errors.is_empty(), "Campaign validates without build: " + str(errors.slice(0, 12)))
	check(not room.has_node("RoomVisuals"), "Validation must not build gameplay or scenery")
	check(Validator.editor_bounds(room) == Rect2(0, -160, 12000, 2400), "Editor reads the full authored bounds")
	var gameplay = room.get_node("Gameplay")
	var duplicate_action = gameplay.get_node("Action_tools").duplicate()
	gameplay.add_child(duplicate_action)
	check(has_error(room,"unique"), "Ordinary duplicate action IDs remain invalid")
	duplicate_action.free()
	var endpoint = gameplay.get_node("Passage_gate_entry_b")
	endpoint.set_meta("shortcut_gate", "gate_west")
	check(has_error(room,"same existing gate"), "Mismatched shortcut gate IDs remain invalid")
	endpoint.set_meta("shortcut_gate", "gate_entry")
	var extra_endpoint = endpoint.duplicate()
	gameplay.add_child(extra_endpoint)
	check(has_error(room,"exactly two endpoints"), "Three shortcut endpoints remain invalid")
	extra_endpoint.free()
	endpoint.action_id = "orphan_shortcut"
	check(has_error(room,"exactly two endpoints"), "A single shortcut endpoint remains invalid")
	endpoint.action_id = "gate_entry_travel"
	var first_endpoint = gameplay.get_node("Passage_gate_entry_a")
	var first_position: Vector2 = first_endpoint.position
	first_endpoint.position = Vector2(200,1840)
	check(Validator.validate(room).is_empty(), "A freight control may occupy its own supported closed doorway")
	first_endpoint.position = first_position
	var unrelated_control := RoomAction.new()
	unrelated_control.action_id = "unrelated_control"
	unrelated_control.position = Vector2(200,1840)
	gameplay.add_child(unrelated_control)
	check(has_error(room,"standing space"), "Unrelated controls do not receive the doorway overlap exception")
	unrelated_control.free()
	var npc = gameplay.get_node("NPC_mara")
	var npc_position: Vector2 = npc.position
	npc.position.y -= 150
	check(has_error(room,"NPC_mara: feet"), "Unsupported NPC is rejected despite its editor SPAWN enum")
	npc.position = npc_position
	var enemy = gameplay.get_node("Encounter1_0")
	var enemy_position: Vector2 = enemy.position
	enemy.position.y -= 150
	check(has_error(room,"Encounter1_0: feet"), "Unsupported encounter marker is rejected")
	enemy.position = Vector2(3655,1120)
	check(has_error(room,"Encounter1_0: standing space"), "Enemies cannot spawn inside a closed gate")
	enemy.position = enemy_position
	var door = gameplay.get_node("gate_west")
	var door_position: Vector2 = door.position
	door.position.y -= 240
	check(has_error(room,"gate must meet"), "Floating gates still require physical support")
	door.position = door_position
	var outside := PaperPlatform.new()
	outside.position = Vector2(11990, 1800)
	gameplay.add_child(outside)
	check(has_error(room,"outside the configured"), "Expanded maps still reject out-of-bounds platforms")
	outside.free()
	check(Validator.validate(room).is_empty(), "Restoring valid campaign data clears all errors")
	room.free()
	for path in RecoilLab.CAMPAIGN_ROOMS + ["res://scenes/rooms/connected_monastery.tscn"]:
		var legacy = load(path).instantiate()
		check(Validator.validate(legacy).is_empty(), "Legacy editor validation still passes: " + path)
		legacy.free()
	print("STAGE RESULT: campaign editor failures=%d" % failures)
	quit(1 if failures else 0)

