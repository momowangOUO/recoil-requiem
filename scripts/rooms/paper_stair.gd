@tool
class_name PaperStair
extends Node2D
## Origin and end_offset are the two standing-line endpoints, in logical pixels.
## Collision is a thin closed slope shell. Treads are visual geometry only.

@export var end_offset := Vector2(384, -192):
	set(value):
		end_offset = value
		_refresh()
@export var stair_depth := 48.0:
	set(value):
		stair_depth = maxf(8.0, value)
		_refresh()
@export var visual_tread := 12.0:
	set(value):
		visual_tread = maxf(1.0, value)
		_refresh()
## Only visibly open metal grating may opt into underside/drop-through access.
@export var one_way := false:
	set(value):
		one_way = value
		_refresh()

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if not has_node("RampCollision"):
		var body := StaticBody2D.new()
		body.name = "RampCollision"
		body.collision_layer = 1
		body.collision_mask = 0
		var polygon := CollisionPolygon2D.new()
		polygon.name = "SlopeShell"
		body.add_child(polygon)
		add_child(body)
	_refresh()

func surface_points() -> PackedVector2Array:
	return PackedVector2Array([Vector2.ZERO, end_offset])

func surface_y(local_x: float) -> float:
	if is_zero_approx(end_offset.x):
		return 0.0
	return end_offset.y * clampf(local_x / end_offset.x, 0.0, 1.0)

func shell_polygon() -> PackedVector2Array:
	var left := Vector2.ZERO if end_offset.x >= 0 else end_offset
	var right := end_offset if end_offset.x >= 0 else Vector2.ZERO
	return PackedVector2Array([left, right, right + Vector2(0, stair_depth), left + Vector2(0, stair_depth)])

## Ordered left-to-right, including the exact two landing heights. Each tread
## sits at its midpoint's slope height, so visible feet differ by at most 3 px.
func tread_points() -> PackedVector2Array:
	var left := minf(0.0, end_offset.x)
	var right := maxf(0.0, end_offset.x)
	var count := maxi(1, ceili(maxf(absf(end_offset.x) / visual_tread, absf(end_offset.y) / 6.0)))
	var points := PackedVector2Array([Vector2(left, surface_y(left))])
	for index in count:
		var x0 := lerpf(left, right, float(index) / count)
		var x1 := lerpf(left, right, float(index + 1) / count)
		var y := surface_y((x0 + x1) * 0.5)
		points.append(Vector2(x0, y))
		points.append(Vector2(x1, y))
	points.append(Vector2(right, surface_y(right)))
	return points

func _refresh() -> void:
	queue_redraw()
	# Detached room instances may be edited before ordinary tree reentry, which
	# does not rerun _ready(). Keep their existing collision resource in sync.
	if has_node("RampCollision/SlopeShell"):
		var collider := get_node("RampCollision/SlopeShell") as CollisionPolygon2D
		collider.polygon = shell_polygon() if absf(end_offset.x) >= 1.0 else PackedVector2Array()
		collider.one_way_collision = one_way
		collider.one_way_collision_margin = 2.0
		get_node("RampCollision").collision_layer = 1024 if one_way else 1
	update_configuration_warnings()

func _get_configuration_warnings() -> PackedStringArray:
	if absf(end_offset.x) < 1.0:
		return PackedStringArray(["A walkable stair needs nonzero horizontal run."])
	if rad_to_deg(atan2(absf(end_offset.y), absf(end_offset.x))) > 35.0:
		return PackedStringArray(["Use a stair slope of at most 35 degrees and connect both ends to horizontal landings."])
	return PackedStringArray()

func _draw() -> void:
	if absf(end_offset.x) < 1.0:
		return
	var treads := tread_points()
	if one_way:
		for index in range(1, treads.size() - 1, 2):
			draw_line(treads[index], treads[index + 1], Color("6cddd3"), 2.0)
		return
	var outline := treads.duplicate()
	outline.append(treads[-1] + Vector2(0, stair_depth))
	outline.append(treads[0] + Vector2(0, stair_depth))
	draw_colored_polygon(outline, Color("454658"))
	draw_polyline(treads, Color("b7abb2"), 1.0)
	draw_line(outline[-2], outline[-1], Color("272a38"), 2.0)
	for index in range(1, treads.size() - 1, 2):
		draw_line(treads[index], treads[index] + Vector2(0, minf(stair_depth, 8)), Color("272a38"), 1.0)
