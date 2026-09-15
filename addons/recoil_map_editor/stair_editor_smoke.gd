@tool
extends RefCounted
var failures := 0
var checks := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
	print("STAIR EDITOR ", "PASS: " if ok else "FAIL: ", label)

func run(plugin: EditorPlugin) -> void:
	await plugin.get_tree().create_timer(2.0).timeout
	plugin._open(plugin.MAIN_ROOM)
	for tick in 12: await plugin.get_tree().process_frame
	var room := EditorInterface.get_edited_scene_root()
	check(room != null and room.scene_file_path == "res://scenes/rooms/image_monastery.tscn", "main button opens image-led monastery")
	if room == null:
		plugin.get_tree().quit(1)
		return
	var bounds: Rect2 = room.get_meta("world_bounds")
	check(plugin.x_input.max_value == bounds.end.x and plugin.stair_run_input.max_value == bounds.size.x, "stair controls follow actual map bounds")
	check(not "--room=" + room.scene_file_path in plugin._preview_arguments(room.scene_file_path), "main map preview launches campaign session")
	check("--room=res://scenes/rooms/bell_gallery.tscn" in plugin._preview_arguments("res://scenes/rooms/bell_gallery.tscn"), "legacy map preview retains explicit room argument")
	var gameplay := room.get_node("Gameplay")
	var before := gameplay.get_child_count()
	plugin.x_input.value = 128
	plugin.y_input.value = 128
	plugin.stair_run_input.value = 384
	plugin.stair_rise_input.value = -192
	plugin._stair()
	var stair := gameplay.get_child(-1) as PaperStair
	check(stair != null and stair.owner == room and stair.end_offset == Vector2(384, -192), "add stair uses chosen dimensions and saved scene ownership")
	plugin.stair_run_input.value = -480
	plugin.stair_rise_input.value = -240
	plugin._edit_stair()
	check(stair.end_offset == Vector2(-480, -240) and stair.get_node("RampCollision/SlopeShell").polygon == stair.shell_polygon(), "edit stair refreshes mirrored dimensions and collision")
	var manager := plugin.get_undo_redo()
	var history := manager.get_history_undo_redo(manager.get_object_history_id(room))
	history.undo()
	check(stair.end_offset == Vector2(384, -192), "undo restores original stair dimensions")
	history.redo()
	check(stair.end_offset == Vector2(-480, -240), "redo restores edited stair dimensions")
	var packed := PackedScene.new()
	check(packed.pack(room) == OK and ResourceSaver.save(packed, "res://artifacts/stair_editor_roundtrip.tscn") == OK, "stair edits save to isolated scene copy")
	var restored = load("res://artifacts/stair_editor_roundtrip.tscn").instantiate()
	var saved := restored.get_node("Gameplay").get_child(-1) as PaperStair
	check(saved != null and saved.end_offset == Vector2(-480, -240) and not saved.one_way, "saved stair dimensions and solid default survive reload")
	restored.free()
	history.undo()
	history.undo()
	check(gameplay.get_child_count() == before, "undo removes created stair without altering authored map")
	history.redo()
	check(gameplay.get_child_count() == before + 1 and stair.get_node("RampCollision").get_child_count() == 1, "redo reattaches one collision shape")
	history.undo()
	print("STAIR EDITOR SMOKE RESULT: %d checks, %d failures" % [checks, failures])
	plugin.get_tree().quit(1 if failures else 0)
