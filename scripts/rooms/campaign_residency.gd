class_name CampaignResidency
extends RefCounted
## Scene-tree residency only: construction and texture memory remain eager.
## clear() restores ownership before scenery is freed by a room reset.
const CELL := Vector2(1200, 720)
const WINDOW := Vector2(1800, 1200)
var bins: Dictionary = {}
var _stage: WeakRef
var _scenery: WeakRef

func setup(stage: Node3D) -> void:
	clear()
	_stage = weakref(stage)
	_scenery = weakref(stage.scenery)
	for node in stage.scenery.get_children():
		if not node is VisualInstance3D or node is Light3D: continue
		if node == stage.bell_clapper: continue
		if node is MeshInstance3D and node in stage.shadow_cards: continue
		if node is MeshInstance3D and node.material_override == stage.door_material: continue
		var box: AABB = node.global_transform * node.get_aabb()
		var bounds := Rect2(Vector2(box.position.x, -box.end.y) / 0.01, Vector2(box.size.x, box.size.y) / 0.01)
		var key := Vector2i((bounds.get_center() / CELL).floor())
		if not bins.has(key):
			bins[key] = {"bounds": bounds, "nodes": [], "mounted": true}
		bins[key].bounds = bins[key].bounds.merge(bounds)
		bins[key].nodes.append(node)

func update_at(position: Vector2) -> void:
	if _scenery == null or _scenery.get_ref() == null: return
	var scenery: Node = _scenery.get_ref()
	var window := Rect2(position - WINDOW / 2, WINDOW)
	var stage: Node3D = _stage.get_ref()
	if stage != null:
		# Include camera lag and weapon zoom/edge look, with a generous backdrop margin.
		var focus: Vector3 = stage.camera_target
		var camera_point := Vector2(focus.x, -focus.y) / 0.01
		window = window.merge(Rect2(camera_point - WINDOW / 2, WINDOW))
	for entry in bins.values():
		var wanted: bool = window.intersects(entry.bounds, true)
		if wanted == entry.mounted: continue
		for node in entry.nodes:
			if wanted: scenery.add_child(node)
			else: scenery.remove_child(node)
		entry.mounted = wanted

func clear() -> void:
	var scenery: Node = _scenery.get_ref() if _scenery != null else null
	for entry in bins.values():
		for node in entry.nodes:
			if not is_instance_valid(node) or node.get_parent() != null: continue
			if scenery != null: scenery.add_child(node)
			else: node.free()
	bins.clear()
	_stage = null
	_scenery = null
