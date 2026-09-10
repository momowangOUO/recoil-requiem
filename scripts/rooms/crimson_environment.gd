class_name CrimsonEnvironment
extends LabEnvironment

@export var room_title := "CRIMSON / EAST COURT"
@export_enum("Court", "Bell", "Archive", "Garden") var architecture := 0
@export var require_clear := true
@export var objective_hint := "CLEAR GUARDS / EAST DOOR"
@export var room_width := 960.0
var visual_sections: Array[Dictionary] = []
var actions: Array[RoomAction] = []
var stage: PaperStage
var modules: Array[PaperPlatform] = []
var enemy_spawns: Array[RoomMarker] = []
var exit_position := Vector2(900, 352)
var exit_open := false

func build(_index: int) -> void:
	preset = 3
	spawn = Vector2(80, 352)
	bounds = Rect2(0, -128, room_width, 544)
	if visual_sections.is_empty(): visual_sections.append({"offset": Vector2.ZERO, "architecture": architecture})
	stage = PaperStage.new()
	stage.name = "RoomVisuals"
	add_child(stage)
	for node in get_node("Gameplay").get_children():
		if node is RoomAction:
			actions.append(node)
		if node is RoomMarker:
			match node.kind:
				RoomMarker.Kind.SPAWN: spawn = node.position
				RoomMarker.Kind.EXIT: exit_position = node.position
				_: enemy_spawns.append(node)
		if node is PaperPlatform:
			modules.append(node)
			var rect := Rect2(node.position, Vector2(node.width, node.collision_depth))
			if node.one_way:
				platforms.append(rect)
			else:
				blocks.append(rect)
	# Room seals have no fake visible standing tops.
	_collision(Rect2(-16, -144, 16, 560), false)
	_collision(Rect2(room_width, -144, 16, 560), false)
	_collision(Rect2(0, -144, room_width, 16), false)
	queue_redraw()

func objectives_complete() -> bool:
	for action in actions:
		if action.required and not action.activated: return false
	return true

func alarm_active() -> bool:
	return architecture == 1 and not objectives_complete()

func activate(action: RoomAction) -> void:
	action.activated = true
	for module in modules:
		if module.unlock_action == action.action_id:
			module.set_active(true)

func progress_text() -> String:
	var complete := 0
	var total := 0
	for action in actions:
		if action.required:
			total += 1
			complete += int(action.activated)
	return objective_hint + ("  %d/%d" % [complete, total] if total > 0 else "")

func set_greybox(enabled: bool) -> void:
	for module in modules:
		module.textured = not enabled
		module.queue_redraw()
	stage.set_greybox(enabled)

func _draw() -> void:
	# Exit is a drawn door, not an apparently standable decorative platform.
	draw_rect(Rect2(883, 294, 34, 58), Color("282331"))
	draw_rect(Rect2(887, 299, 26, 53), Color("263c3c") if exit_open else Color("492c3e"))
	draw_line(Vector2(883, 294), Vector2(917, 294), Color("6cddd3") if exit_open else Color("9b6573"), 2)
	draw_circle(Vector2(906, 326), 2, Color("e8c6a1"))
