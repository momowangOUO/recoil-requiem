@tool
class_name ConnectedMonastery
extends CrimsonEnvironment
## The authored sections share one World2D. Section roots never call build(),
## so their former doors and boundary walls do not exist in the combined room.
var checkpoints: Array[Vector2] = []

func build(index: int) -> void:
	compose_sections()
	super.build(index)

func compose_sections() -> void:
	var gameplay := get_node("Gameplay")
	var section_index := 0
	for section in get_node("Sections").get_children():
		var offset: Vector2 = section.position
		visual_sections.append({"offset": offset, "architecture": section.architecture})
		for node in section.get_node("Gameplay").get_children():
			if node is RoomMarker:
				if node.kind == RoomMarker.Kind.SPAWN:
					checkpoints.append(node.position + offset)
					if section_index > 0: continue
				if node.kind == RoomMarker.Kind.EXIT and section_index < 4: continue
			node.owner = null
			node.reparent(gameplay, false)
			node.position += offset
			node.set_meta("section", section_index)
		section_index += 1
	get_node("Sections").free()
	# Archive entrance is now a descending stair, so its checkpoint is the desk.
	checkpoints[3] = Vector2(3232, 288)

func alarm_active() -> bool:
	for action in actions:
		if action.action_id == "BellRope": return not action.activated
	return false
