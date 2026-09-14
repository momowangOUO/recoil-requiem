@tool
extends RefCounted
var failures := 0
func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error(label)
func run(plugin: EditorPlugin) -> void:
	await plugin.get_tree().create_timer(2.0).timeout
	plugin._open("res://scenes/rooms/monastery_campaign.tscn")
	for i in 12: await plugin.get_tree().process_frame
	var room := EditorInterface.get_edited_scene_root()
	check(room != null and room.has_meta("world_bounds"), "Editor opens the sixteen-space scene")
	check(plugin.x_input.max_value == 12000 and plugin.y_input.min_value == -160 and plugin.y_input.max_value == 2239, "Editor controls adopt expanded scene bounds")
	check(plugin._validate(), "Authored campaign validates inside real editor")
	var before: int = room.get_node("Gameplay").get_child_count()
	plugin.x_input.value = 5000
	plugin.y_input.value = 1120
	plugin.encounter_input.value = 6
	for archetype in ["charger","grenadier","flyer","support"]:
		plugin._campaign_marker(archetype)
		var node := room.get_node("Gameplay").get_child(-1)
		check(node.owner == room and node.get_meta("enemy_archetype") == archetype and node.get_meta("encounter_id") == 6 and node.get_meta("space_id") == "mon_03", "Editor authors saved encounter metadata " + archetype)
	check(plugin._validate(), "New supported enemy markers validate")
	var packed := PackedScene.new()
	check(packed.pack(room) == OK and ResourceSaver.save(packed,"res://artifacts/campaign_editor_roundtrip.tscn") == OK, "Campaign marker edits serialize")
	var restored = load("res://artifacts/campaign_editor_roundtrip.tscn").instantiate()
	check(restored.get_node("Gameplay").get_child_count() == before + 4, "Campaign marker edits survive reload")
	restored.free()
	var manager := plugin.get_undo_redo()
	var history := manager.get_history_undo_redo(manager.get_object_history_id(room))
	for i in 4: history.undo()
	check(room.get_node("Gameplay").get_child_count() == before, "Four new markers undo cleanly")
	plugin._open("res://scenes/rooms/connected_monastery.tscn")
	for i in 12: await plugin.get_tree().process_frame
	check(plugin.x_input.max_value == 4800 and plugin.y_input.max_value == 400 and plugin._validate(), "Legacy connected map restores legacy bounds and validates")
	print("CAMPAIGN EDITOR RESULT: failures=%d" % failures)
	plugin.get_tree().quit(1 if failures else 0)
