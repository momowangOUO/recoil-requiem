@tool
class_name PaperPlatform
extends Node2D
## The origin is the physical standing line. All visual depth extends BELOW it.

@export var width: float = 128.0:
	set(value):
		width = maxf(16, value)
		_refresh()
@export var collision_depth: float = 8.0:
	set(value):
		collision_depth = maxf(1, value)
		_refresh()
@export var one_way := false:
	set(value):
		one_way = value
		_refresh()
@export var textured := true
@export var unlock_action := ""
var active := true
const TOP_DEPTH := 8.0
const FACE_DEPTH := 24.0
const ATLAS = preload("res://assets/environments/crimson/atlas_v1.png")
const TOP_REGION := Rect2(48, 34, 548, 526)
const FACE_REGION := Rect2(660, 34, 544, 526)

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var body := StaticBody2D.new()
	body.name = "Collision"
	body.collision_layer = (1024 if one_way else 1) if active else 0
	body.collision_mask = 0
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(width, collision_depth)
	collider.shape = shape
	collider.position = shape.size * 0.5
	collider.one_way_collision = one_way
	collider.one_way_collision_margin = 2.0
	body.add_child(collider)
	add_child(body)
	set_active(unlock_action.is_empty() or Engine.is_editor_hint())
	queue_redraw()

func set_active(value: bool) -> void:
	active = value
	visible = value
	if has_node("Collision"):
		get_node("Collision").collision_layer = (1024 if one_way else 1) if value else 0

func _refresh() -> void:
	queue_redraw()
	if not is_inside_tree() or not has_node("Collision"):
		return
	var body := get_node("Collision") as StaticBody2D
	body.collision_layer = (1024 if one_way else 1) if active else 0
	var collider := body.get_child(0) as CollisionShape2D
	collider.shape.size = Vector2(width, collision_depth)
	collider.position = Vector2(width, collision_depth) * 0.5
	collider.one_way_collision = one_way

func _draw() -> void:
	var edge := Color("6cddd3") if one_way else Color("b7abb2")
	if one_way:
		# Open grating is the only pass-through surface. No stone slab silhouette.
		for x in range(0, ceili(width), 12):
			draw_rect(Rect2(x, 0, minf(4, width - x), 5), Color("748b92"))
			draw_line(Vector2(x, 0), Vector2(minf(x + 4, width), 0), edge, 1)
		draw_line(Vector2(0, 5), Vector2(width, 5), Color("475b63"), 1)
		return
	for x in range(0, ceili(width), 32):
		var tile_width := minf(32.0, width - x)
		var top := Rect2(x, 0, tile_width, TOP_DEPTH)
		var face := Rect2(x, TOP_DEPTH, tile_width, FACE_DEPTH)
		if textured:
			draw_texture_rect_region(ATLAS, top, TOP_REGION, Color("b2a3af"))
			draw_texture_rect_region(ATLAS, face, FACE_REGION, Color("85738a"))
		else:
			draw_rect(top, Color("655b70"))
			draw_rect(face, Color("342d42"))
			draw_line(Vector2(x, TOP_DEPTH), Vector2(x, TOP_DEPTH + FACE_DEPTH), Color("504357"))
	# One uninterrupted bright line matches the collider, never the decorative front.
	draw_line(Vector2.ZERO, Vector2(width, 0), edge, 1)
	draw_line(Vector2(0, TOP_DEPTH), Vector2(width, TOP_DEPTH), Color("262231"), 1)
	draw_line(Vector2(0, TOP_DEPTH + FACE_DEPTH), Vector2(width, TOP_DEPTH + FACE_DEPTH), Color("171522"), 2)
