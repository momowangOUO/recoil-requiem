extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var room = load("res://scenes/rooms/image_monastery.tscn").instantiate()
	var errors = preload("res://addons/recoil_map_editor/room_validator.gd").validate(room)
	for error in errors: print(error)
	room.free()
	print("IMAGE EDITOR STAGE RESULT: %d failures" % errors.size())
	quit(1 if not errors.is_empty() else 0)
