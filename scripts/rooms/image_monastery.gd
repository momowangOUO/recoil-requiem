class_name ImageMonastery
extends MonasteryCampaign
## Scene-authored floors, independent stairs, markers and structural masses.
var image_led := true
var stairs: Array[Node] = []
var structure_records: Array = []
var story_positions: Dictionary = {}

static func source_to_world(point: Vector2) -> Vector2:
	return Vector2(point.x*8.0,1120+(point.y-430)*8.0)

func build(index: int) -> void:
	super.build(index)
	for node in get_node("Gameplay").get_children():
		if node is PaperStair: stairs.append(node)
	for node in get_node("StructureRecords").get_children():
		var record: Dictionary = node.get_meta("record").duplicate(true)
		record.position = [node.position.x,node.position.y]
		structure_records.append(record)
	for node in get_node("StoryPositions").get_children():
		story_positions[str(node.name)] = node.position
