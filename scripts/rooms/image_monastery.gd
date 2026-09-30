class_name ImageMonastery
extends MonasteryCampaign
## Scene-authored floors, independent stairs, markers and structural masses.
var image_led := true
var stairs: Array[Node] = []
var structure_records: Array = []
var story_positions: Dictionary = {}
var _luggage_home: Variant = null

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

	set_luggage_home(false)

func set_luggage_home(home: bool) -> void:
	if _luggage_home == home: return
	_luggage_home = home
	for site in ["Home", "Cart"]:
		for part in ["Cover", "Up", "Down"]:
			get_node("Gameplay/Luggage" + site + part).set_active(home == (site == "Home"))
	var at: Vector2 = story_positions["luggage_home" if home else "luggage_cart"] - Vector2(0,36)
	get_node("Gameplay/Action_luggage").position = at
	for point in action_points:
		if point.id == "luggage": point.position = at
