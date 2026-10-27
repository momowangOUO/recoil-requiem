extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var room = load("res://scenes/rooms/image_monastery.tscn").instantiate()
	var errors = preload("res://addons/recoil_map_editor/room_validator.gd").validate(room)
	for error in errors: print(error)
	room.free()
	var seam_room := Node2D.new()
	seam_room.set_meta("world_bounds", Rect2(0, 0, 320, 180))
	var gameplay := Node2D.new()
	gameplay.name = "Gameplay"
	seam_room.add_child(gameplay)
	for x in [0, 128]:
		var floor_piece := PaperPlatform.new()
		floor_piece.position = Vector2(x, 100)
		floor_piece.width = 128
		gameplay.add_child(floor_piece)
	for x in [128, 220]:
		var marker := RoomMarker.new()
		marker.kind = RoomMarker.Kind.SPAWN if x == 128 else RoomMarker.Kind.EXIT
		marker.position = Vector2(x, 100)
		gameplay.add_child(marker)
	var validator = preload("res://addons/recoil_map_editor/room_validator.gd")
	if not validator.validate(seam_room).is_empty(): errors.append("Continuous floor seams must support an actor.")
	gameplay.get_child(1).position.x += 4
	if validator.validate(seam_room).is_empty(): errors.append("A real gap beside the actor must still be rejected.")
	seam_room.free()
	print("IMAGE EDITOR STAGE RESULT: %d failures" % errors.size())
	quit(1 if not errors.is_empty() else 0)
