@tool
class_name RoomMarker
extends Marker2D
## Editable scene data. Markers do not simulate enemies in the editor.
enum Kind { SPAWN, EXIT, SHIELD, RIFLE }
@export var kind: Kind = Kind.SHIELD:
	set(value):
		kind = value
		queue_redraw()

func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var colors := [Color.CYAN, Color.LIME_GREEN, Color.SALMON, Color.GOLD]
	draw_rect(Rect2(-12, -44, 24, 44), colors[kind], false, 2)
	draw_string(ThemeDB.fallback_font, Vector2(-16, -50), ["SPAWN", "EXIT", "SHIELD", "RIFLE"][kind], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, colors[kind])
