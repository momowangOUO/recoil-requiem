class_name MonasteryCampaign
extends CrimsonEnvironment
## Editable world modules remain the source of both physics and 3D geometry.
var space_bounds: Dictionary = {}
var connections: Array[Dictionary] = []
var checkpoints: Array[Dictionary] = []
var npc_points: Array[Dictionary] = []
var action_points: Array[Dictionary] = []
var gates: Dictionary = {}
var gate_states: Dictionary = {}
var campaign := true
var shortcut_points: Array[Dictionary] = [
	{"gate_id": "gate_entry", "from": Vector2(2400, 1120), "to": Vector2(400, 1840), "from_space": "mon_02", "to_space": "mon_10"},
	{"gate_id": "gate_west", "from": Vector2(2000, 400), "to": Vector2(6800, 1120), "from_space": "mon_04", "to_space": "mon_08"},
	{"gate_id": "gate_east", "from": Vector2(7700, 400), "to": Vector2(9600, 1120), "from_space": "mon_09", "to_space": "mon_14"},
	{"gate_id": "gate_return", "from": Vector2(11600, 1120), "to": Vector2(240, 1120), "from_space": "mon_16", "to_space": "mon_01"}
]

func build(_index: int) -> void:
	preset = 3
	room_title = "猩红修道院"
	objective_hint = ""
	bounds = get_meta("world_bounds", Rect2(0, -160, 12000, 2400))
	room_width = bounds.size.x
	spawn = Vector2(120, 1120)
	exit_position = Vector2(11760, 1120)
	stage = PaperStage.new()
	stage.name = "RoomVisuals"
	add_child(stage)
	var gameplay := get_node("Gameplay")
	for section in get_node("Sections").get_children():
		var id: String = section.get_meta("space_id")
		space_bounds[id] = section.get_meta("space_bounds")
	for node in gameplay.get_children():
		if node is PaperPlatform:
			modules.append(node)
			var rect := Rect2(node.position, Vector2(node.width, node.collision_depth))
			if node.one_way: platforms.append(rect)
			else: blocks.append(rect)
			if node.has_meta("gate_id"):
				var id: String = node.get_meta("gate_id")
				gates[id] = node
				gate_states[id] = false
		if node is RoomAction:
			actions.append(node)
			action_points.append({"id": node.action_id, "space_id": node.get_meta("space_id"), "position": node.position})
		if node is RoomMarker:
			if node.has_meta("checkpoint_id"):
				checkpoints.append({"id": node.get_meta("checkpoint_id"), "space_id": node.get_meta("space_id"), "position": node.position})
			elif node.has_meta("npc_id"):
				npc_points.append({"id": node.get_meta("npc_id"), "space_id": node.get_meta("space_id"), "position": node.position})
			elif node.kind in [RoomMarker.Kind.SHIELD, RoomMarker.Kind.RIFLE]:
				enemy_spawns.append(node)
			elif node.kind == RoomMarker.Kind.SPAWN: spawn = node.position
			elif node.kind == RoomMarker.Kind.EXIT: exit_position = node.position
	for shortcut in shortcut_points:
		var endpoints: Array = []
		for point in action_points:
			if point.id == shortcut.gate_id + "_travel": endpoints.append(point)
		if endpoints.size() == 2:
			shortcut.from = endpoints[0].position
			shortcut.to = endpoints[1].position
			shortcut.from_space = endpoints[0].space_id
			shortcut.to_space = endpoints[1].space_id
	for node in get_node("Connections").get_children():
		connections.append({"from": node.get_meta("from"), "to": node.get_meta("to"), "gate_id": node.get_meta("gate_id", ""), "position": node.position})
	for node in get_node("VisualSections").get_children():
		visual_sections.append({"offset": node.position, "architecture": node.get_meta("architecture", 0)})
	_collision(Rect2(-24, -184, 24, 2448), false)
	_collision(Rect2(12000, -184, 24, 2448), false)
	_collision(Rect2(0, -184, 12000, 24), false)

func space_at(point: Vector2) -> String:
	for id in space_bounds:
		if space_bounds[id].has_point(point): return id
	return ""

func set_gate_state(gate_id: String, opened: bool) -> void:
	if not gates.has(gate_id): return
	gate_states[gate_id] = opened
	gates[gate_id].set_active(not opened)

func shortcut_destination(point: Vector2, radius: float = 48.0) -> Vector2:
	for shortcut in shortcut_points:
		if not gate_states.get(shortcut.gate_id, false): continue
		if point.distance_to(shortcut.from) <= radius: return shortcut.to
		if point.distance_to(shortcut.to) <= radius: return shortcut.from
	return Vector2.INF

func alarm_active() -> bool: return false
func _draw() -> void: pass
