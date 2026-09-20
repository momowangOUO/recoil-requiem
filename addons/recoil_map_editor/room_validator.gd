@tool
extends RefCounted
## Shared validation reads authored data; campaign build() is never called here.
static func editor_bounds(room: Node) -> Rect2:
	if room != null and room.has_meta("world_bounds"):
		return room.get_meta("world_bounds")
	return Rect2(0, -128, room.room_width if room != null else 960, 528)

static func validate(room: Node) -> PackedStringArray:
	if room is ConnectedMonastery and room.has_node("Sections"):
		var copy := room.duplicate()
		copy.compose_sections()
		var result := validate(copy)
		copy.free()
		return result
	var errors := PackedStringArray()
	if room == null or not room.has_node("Gameplay"):
		errors.append("Open a room scene containing Gameplay first.")
		return errors
	var bounds := editor_bounds(room)
	var expanded := room.has_meta("world_bounds")
	if not bounds.has_area(): errors.append("World bounds must have positive width and height.")
	var starts := 0
	var exits := 0
	var markers: Array[Node2D] = []
	var actions: Dictionary = {}
	var unlocks: Array[String] = []
	var solid_surfaces: Array[Dictionary] = []
	var initial_surfaces: Array[Rect2] = []
	var stairs: Array[PaperStair] = []
	var gates: Dictionary = {}
	var shortcut_counts: Dictionary = {}
	var spaces: Dictionary = {}
	if expanded and room.has_node("Sections"):
		for section in room.get_node("Sections").get_children():
			if section.has_meta("space_id"): spaces[str(section.get_meta("space_id"))] = section.get_meta("space_bounds", Rect2())
	for node in room.get_node("Gameplay").get_children():
		if node is PaperPlatform:
			if not node.unlock_action.is_empty(): unlocks.append(node.unlock_action)
			if node.width < 16 or node.collision_depth <= 0:
				errors.append("%s: width >= 16 and collision depth > 0 required." % node.name)
			var surface := Rect2(node.position, Vector2(node.width, node.collision_depth))
			var out_of_bounds: bool = not bounds.encloses(surface) if expanded else (node.position.x < 0 or surface.end.x > bounds.end.x or node.position.y < -128 or node.position.y > 400)
			if out_of_bounds: errors.append("%s: outside the configured room bounds." % node.name)
			if node.has_meta("gate_id"):
				var id := str(node.get_meta("gate_id"))
				if id.is_empty() or gates.has(id): errors.append("%s: gate ID must be nonempty and unique." % node.name)
				if node.one_way: errors.append("%s: a closed gate must block from both sides." % node.name)
				gates[id] = node
			if node.unlock_action.is_empty():
				if not node.has_meta("gate_id"): initial_surfaces.append(surface)
				if not node.one_way: solid_surfaces.append({"rect":surface,"node":node})
		elif node is PaperStair:
			stairs.append(node)
			if absf(node.end_offset.x) < 1:
				errors.append("%s: stair requires nonzero horizontal run." % node.name)
			elif rad_to_deg(atan2(absf(node.end_offset.y), absf(node.end_offset.x))) > 35.001:
				errors.append("%s: stair slope must not exceed 35 degrees." % node.name)
			for corner in node.shell_polygon():
				if not bounds.grow(0.001).has_point(node.position + corner):
					errors.append("%s: stair shell is outside the configured room bounds." % node.name)
					break
		elif node is RoomAction:
			markers.append(node)
			if node.has_meta("shortcut_gate"):
				var shortcut_id := str(node.get_meta("shortcut_gate"))
				shortcut_counts[shortcut_id] = int(shortcut_counts.get(shortcut_id, 0)) + 1
			if node.action_id.is_empty(): errors.append("%s: action ID must be nonempty and unique." % node.name)
			if not actions.has(node.action_id): actions[node.action_id] = []
			actions[node.action_id].append(node)
			if node.kind == RoomAction.Kind.SUPPLY and node.required:
				errors.append("%s: supplies cannot be required objectives." % node.name)
		elif node is RoomMarker:
			var is_npc := node.has_meta("npc_id")
			var is_checkpoint := node.has_meta("checkpoint_id")
			if is_npc and is_checkpoint: errors.append("%s: a marker cannot be both NPC and checkpoint." % node.name)
			if not is_npc and not is_checkpoint:
				starts += int(node.kind == RoomMarker.Kind.SPAWN)
				exits += int(node.kind == RoomMarker.Kind.EXIT)
			markers.append(node)
	if starts != 1: errors.append("Exactly one SPAWN marker is required.")
	if exits != 1: errors.append("Exactly one EXIT marker is required.")
	for unlock in unlocks:
		if not actions.has(unlock): errors.append("Unknown platform unlock action: " + unlock)
	for gate_id in shortcut_counts:
		if shortcut_counts[gate_id] != 2: errors.append("%s: freight gate must have exactly two endpoints across all action IDs." % gate_id)
	for id in actions:
		var group: Array = actions[id]
		var has_shortcut := false
		for action in group: has_shortcut = has_shortcut or action.has_meta("shortcut_gate")
		if has_shortcut:
			if group.size() != 2:
				errors.append("%s: freight shortcut must have exactly two endpoints." % id)
				continue
			var gate_id := str(group[0].get_meta("shortcut_gate", ""))
			if gate_id.is_empty() or not gates.has(gate_id) or str(group[1].get_meta("shortcut_gate", "")) != gate_id:
				errors.append("%s: freight endpoints must reference the same existing gate." % id)
			if group[0].position.distance_to(group[1].position) < 96:
				errors.append("%s: freight endpoints must be distinct locations." % id)
		elif group.size() > 1:
			errors.append("%s: action ID must be nonempty and unique." % id)
	for gate_id in gates:
		var gate: PaperPlatform = gates[gate_id]
		var gate_rect := Rect2(gate.position, Vector2(gate.width, gate.collision_depth))
		var anchored := false
		for surface in initial_surfaces:
			if gate_rect.grow(0.1).intersects(surface): anchored = true
		if not anchored: errors.append("%s: gate must meet an authored floor or support." % gate.name)
	for marker in markers:
		if expanded:
			if not bounds.has_point(marker.position): errors.append("%s: marker is outside world bounds." % marker.name)
			if marker.has_meta("space_id"):
				var id := str(marker.get_meta("space_id"))
				if not spaces.has(id): errors.append("%s: unknown space ID %s." % [marker.name,id])
		var supported := false
		var supporting_stair: PaperStair
		for surface in initial_surfaces:
			if absf(surface.position.y - marker.position.y) <= 2 and marker.position.x >= surface.position.x + 12 and marker.position.x <= surface.end.x - 12: supported = true
		for stair in stairs:
			var local_x: float = marker.position.x - stair.position.x
			if local_x >= minf(0, stair.end_offset.x) + 12 and local_x <= maxf(0, stair.end_offset.x) - 12 and absf(marker.position.y - stair.position.y - stair.surface_y(local_x)) <= 2:
				supported = true
				supporting_stair = stair
		var airborne: bool = marker is RoomMarker and marker.kind in [RoomMarker.Kind.SHIELD, RoomMarker.Kind.RIFLE] and marker.get_meta("enemy_archetype", "") == "flyer"
		if not supported and not airborne: errors.append("%s: feet must be on a platform or stair, at least 12 px from its edge." % marker.name)
		var body := Rect2(marker.position + Vector2(-9, -38), Vector2(18, 37))
		for solid in solid_surfaces:
			if body.intersects(solid.rect):
				# Door controls may use their own closed doorway; actor spawns may not.
				var own_door := marker is RoomAction and marker.has_meta("shortcut_gate") and str(marker.get_meta("shortcut_gate")) == str(solid.node.get_meta("gate_id", ""))
				if own_door: continue
				errors.append("%s: standing space overlaps solid stone or a closed gate; leave 38 px headroom." % marker.name)
				break
		var body_polygon := PackedVector2Array([body.position, Vector2(body.end.x, body.position.y), body.end, Vector2(body.position.x, body.end.y)])
		for stair in stairs:
			# A rectangular actor settles slightly above the slope center line;
			# its supporting stair must not be diagnosed as a head obstruction.
			if stair == supporting_stair or stair.one_way: continue
			var polygon := stair.shell_polygon()
			for index in polygon.size(): polygon[index] += stair.position
			if not Geometry2D.intersect_polygons(body_polygon, polygon).is_empty():
				errors.append("%s: standing space overlaps a solid stair; leave 38 px headroom." % marker.name)
				break
	return errors
