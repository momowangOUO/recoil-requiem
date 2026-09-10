@tool
extends RefCounted
## Shared by editor validation and headless tests; room dimensions are intentional.
static func validate(room: Node) -> PackedStringArray:
	if room is ConnectedMonastery and room.has_node("Sections"):
		# Validate the same composed coordinates the game actually loads.
		var copy := room.duplicate()
		copy.compose_sections()
		var result := validate(copy)
		copy.free()
		return result
	var errors := PackedStringArray()
	if room == null or not room.has_node("Gameplay"):
		errors.append("Open a room scene containing Gameplay first.")
		return errors
	var starts := 0
	var exits := 0
	var surfaces: Array[Rect2] = []
	var markers: Array[Node2D] = []
	var action_ids: Array[String] = []
	var unlocks: Array[String] = []
	var solid_surfaces: Array[Rect2] = []
	var initial_surfaces: Array[Rect2] = []
	for node in room.get_node("Gameplay").get_children():
		if node is PaperPlatform:
			if not node.unlock_action.is_empty(): unlocks.append(node.unlock_action)
			if node.width < 16 or node.collision_depth <= 0:
				errors.append("%s: width >= 16 and collision depth > 0 required." % node.name)
			if node.position.x < 0 or node.position.x + node.width > room.room_width or node.position.y < -128 or node.position.y > 400:
				errors.append("%s: outside the configured room bounds." % node.name)
			surfaces.append(Rect2(node.position, Vector2(node.width, node.collision_depth)))
			if node.unlock_action.is_empty():
				initial_surfaces.append(surfaces[-1])
				if not node.one_way: solid_surfaces.append(surfaces[-1])
		elif node is RoomAction:
			markers.append(node)
			if node.action_id.is_empty() or node.action_id in action_ids:
				errors.append("%s: action ID must be nonempty and unique." % node.name)
			action_ids.append(node.action_id)
			if node.kind == RoomAction.Kind.SUPPLY and node.required:
				errors.append("%s: supplies cannot be required objectives." % node.name)
		elif node is RoomMarker:
			starts += int(node.kind == RoomMarker.Kind.SPAWN)
			exits += int(node.kind == RoomMarker.Kind.EXIT)
			markers.append(node)
	if starts != 1: errors.append("Exactly one SPAWN marker is required.")
	if exits != 1: errors.append("Exactly one EXIT marker is required.")
	for unlock in unlocks:
		if unlock not in action_ids: errors.append("Unknown platform unlock action: " + unlock)
	for marker in markers:
		var supported := false
		for surface in initial_surfaces:
			if absf(surface.position.y - marker.position.y) <= 2 and marker.position.x >= surface.position.x + 12 and marker.position.x <= surface.end.x - 12:
				supported = true
		if not supported: errors.append("%s: feet must be on a platform, at least 12 px from its edge." % marker.name)
		var body := Rect2(marker.position + Vector2(-9, -38), Vector2(18, 37))
		for surface in solid_surfaces:
			if body.intersects(surface):
				errors.append("%s: standing space overlaps solid stone; leave 38 px headroom." % marker.name)
				break
	return errors
