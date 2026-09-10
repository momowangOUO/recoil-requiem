extends SceneTree
## Read actual parsed scene properties and runtime constants, never the source draft.
func _initialize() -> void:
	var result := {}
	for name in ["bell_tower", "forbidden_archive", "rose_court"]:
		var room = load("res://scenes/rooms/%s.tscn" % name).instantiate()
		result[name + ".room_title"] = room.room_title
		result[name + ".objective_hint"] = room.objective_hint
		for action in room.get_node("Gameplay").get_children():
			if action is RoomAction:
				result[name + "." + str(action.name) + ".title"] = action.title
				result[name + "." + str(action.name) + ".description"] = action.description
		room.free()
	for key in RecoilLab.ROOM_TEXT:
		result["system." + key] = RecoilLab.ROOM_TEXT[key]
	var file := FileAccess.open("res://artifacts/game-text-actual.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("Exported ", result.size(), " decoded game texts.")
	var expected := {}
	var current_id := ""
	var body := PackedStringArray()
	var inside := false
	for line in FileAccess.get_file_as_string("res://game-text/crimson-continuation.md").split("\n"):
		if line == "~~~~text":
			inside = true
			body.clear()
		elif inside and line == "~~~~":
			expected[current_id] = "\n".join(body)
			inside = false
		elif inside:
			body.append(line)
		elif line.begins_with("## "):
			current_id = line.trim_prefix("## ")
	var matched := not expected.is_empty() and expected == result and not inside
	print("TEXT STAGE RESULT: %d entries, %d failures" % [result.size(), 0 if matched else 1])
	quit(0 if matched else 1)
