@tool
extends RefCounted
## Shared by editor validation and headless tests; room dimensions are intentional.
static func validate(room: Node) -> PackedStringArray:
	var errors := PackedStringArray()
	if room == null or not room.has_node("Gameplay"):
		errors.append("Open a room scene containing Gameplay first.")
		return errors
	var starts := 0
	var exits := 0
	var surfaces: Array[Rect2] = []
	var markers: Array[Node2D] = []
	for node in room.get_node("Gameplay").get_children():
		if node is PaperPlatform:
			if node.width < 16 or node.collision_depth <= 0:
				errors.append("%s: width >= 16 and collision depth > 0 required." % node.name)
			if node.position.x < 0 or node.position.x + node.width > 960 or node.position.y < -128 or node.position.y > 400:
				errors.append("%s: outside the supported 960 x 544 room." % node.name)
			surfaces.append(Rect2(node.position, Vector2(node.width, node.collision_depth)))
		elif node is RoomMarker:
			starts += int(node.kind == RoomMarker.Kind.SPAWN)
			exits += int(node.kind == RoomMarker.Kind.EXIT)
			markers.append(node)
	if starts != 1: errors.append("Exactly one SPAWN marker is required.")
	if exits != 1: errors.append("Exactly one EXIT marker is required.")
	for marker in markers:
		var supported := false
		for surface in surfaces:
			if absf(surface.position.y - marker.position.y) <= 2 and marker.position.x >= surface.position.x + 12 and marker.position.x <= surface.end.x - 12:
				supported = true
		if not supported: errors.append("%s: feet must be on a platform, at least 12 px from its edge." % marker.name)
	return errors
