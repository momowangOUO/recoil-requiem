class_name ReloadFeedback
extends RefCounted

const TRACK := preload("res://assets/ui/v2/runtime/reload_track.png")
const SEGMENT := preload("res://assets/ui/v2/runtime/reload_segment.png")

static func progress_color(progress: float) -> Color:
	var amount := clampf(progress, 0.0, 1.0)
	if amount < 0.5:
		return Color("ed675d").lerp(Color("edc875"), amount * 2.0)
	return Color("edc875").lerp(Color("6cddd3"), (amount - 0.5) * 2.0)

static func draw_ring(canvas: CanvasItem, center: Vector2, progress: float, alpha := 1.0, radius := 11.0) -> void:
	var diameter := radius * 2.0 + 2.0
	canvas.draw_texture_rect(TRACK, Rect2(center - Vector2.ONE * diameter * 0.5, Vector2.ONE * diameter), false, Color(0.58,0.58,0.58,alpha))
	var filled := int(floor(clampf(progress, 0.0, 1.0) * 24.0))
	for segment in 24:
		var angle := -PI * 0.5 + TAU * segment / 24.0
		var tint := progress_color(progress) if segment < filled else Color("534752")
		tint.a *= alpha
		var width := radius * 0.22
		var length := radius * 0.31
		canvas.draw_set_transform(center, angle + PI * 0.5)
		canvas.draw_texture_rect(SEGMENT, Rect2(-width * 0.5, -radius - length * 0.5, width, length), false, tint)
	canvas.draw_set_transform(Vector2.ZERO)
