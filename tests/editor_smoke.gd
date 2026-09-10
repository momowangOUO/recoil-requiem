@tool
extends RefCounted
## Runs inside the real editor plugin; only writes an ignored artifact copy.
var failures := 0
var checks := 0

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)
	print("EDITOR ", "PASS: " if value else "FAIL: ", label)

func run(plugin: EditorPlugin) -> void:
	# Editor layout restoration is asynchronous and may reopen a different tab.
	await plugin.get_tree().create_timer(2.0).timeout
	EditorInterface.open_scene_from_path("res://scenes/rooms/bell_gallery.tscn")
	for i in 8: await plugin.get_tree().process_frame
	var room := EditorInterface.get_edited_scene_root()
	check(room != null and room.has_node("Gameplay"), "open room in actual editor")
	if room == null or not room.has_node("Gameplay"):
		plugin.get_tree().quit(1)
		return
	var parent := room.get_node("Gameplay")
	var before := parent.get_child_count()
	plugin.x_input.value = 32
	plugin.y_input.value = 288
	plugin.width_input.value = 96
	plugin._platform(true)
	check(parent.get_child_count() == before + 1, "platform button inserts a scene node")
	var platform := parent.get_child(-1) as PaperPlatform
	check(platform != null and platform.owner == room and platform.width == 96, "inserted platform has saved ownership and selected width")
	platform.width = 144
	check(platform.get_node("Collision").get_child(0).shape.size.x == 144, "inspector width refreshes physical shape")
	var manager := plugin.get_undo_redo()
	var history := manager.get_history_undo_redo(manager.get_object_history_id(room))
	history.undo()
	check(parent.get_child_count() == before, "undo removes added platform")
	history.redo()
	check(parent.get_child_count() == before + 1, "redo restores added platform")
	plugin.x_input.value = 80
	plugin.y_input.value = 352
	plugin._marker(RoomMarker.Kind.RIFLE)
	check(parent.get_child(-1) is RoomMarker and parent.get_child(-1).kind == RoomMarker.Kind.RIFLE, "rifle placement button creates encounter data")
	check(plugin._validate(), "modified supported map validates")
	var packed := PackedScene.new()
	check(packed.pack(room) == OK and ResourceSaver.save(packed, "res://artifacts/editor_roundtrip.tscn") == OK, "save editable nodes into scene artifact")
	var loaded = load("res://artifacts/editor_roundtrip.tscn").instantiate()
	check(loaded.get_node("Gameplay").get_child_count() == before + 2, "saved map reload retains new platform and enemy")
	loaded.free()
	if DisplayServer.get_name() != "headless":
		EditorInterface.open_scene_from_path("res://scenes/rooms/bell_gallery.tscn")
		EditorInterface.set_main_screen_editor("2D")
		plugin.dock_shell.make_visible()
		for i in 10: await plugin.get_tree().process_frame
		check(plugin.dock.is_visible_in_tree(), "map dock is visible in the real editor")
		await RenderingServer.frame_post_draw
		plugin.get_tree().root.get_texture().get_image().save_png("res://artifacts/map_editor.png")
	history.undo()
	history.undo()
	print("MAP EDITOR RESULT: %d checks, %d failures" % [checks, failures])
	plugin.get_tree().quit(1 if failures else 0)
