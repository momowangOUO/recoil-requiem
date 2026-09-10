@tool
class_name RoomAction
extends Marker2D
## Room-local state is rebuilt at the checkpoint. Read notes also enter the session journal.
enum Kind { SWITCH, NOTE, SUPPLY }
@export var kind: Kind = Kind.SWITCH
@export var action_id := "switch"
@export var required := false
@export var title := "LEVER"
@export_multiline var description := ""
var activated := false

func _draw() -> void:
	if not Engine.is_editor_hint(): return
	var color: Color = [Color.CYAN, Color.GOLD, Color.SALMON][kind]
	draw_circle(Vector2(0, -16), 9, color, false, 2)
	draw_line(Vector2(0, -7), Vector2.ZERO, color, 2)
	draw_string(ThemeDB.fallback_font, Vector2(-18, -30), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, color)
