class_name ReloadFeedback
extends RefCounted

static func progress_color(progress: float) -> Color:
	var amount := clampf(progress, 0.0, 1.0)
	if amount < 0.5:
		return Color("ed675d").lerp(Color("edc875"), amount * 2.0)
	return Color("edc875").lerp(Color("6cddd3"), (amount - 0.5) * 2.0)

static func draw_ring(canvas: CanvasItem, center: Vector2, progress: float, alpha := 1.0) -> void:
	var filled := int(floor(clampf(progress, 0.0, 1.0) * 24.0))
	for segment in 24:
		var angle := -PI * 0.5 + TAU * segment / 24.0
		var a := (center + Vector2.from_angle(angle) * 11.0).round()
		var b := (center + Vector2.from_angle(angle + TAU / 32.0) * 11.0).round()
		var tint := progress_color(progress) if segment < filled else Color("354350")
		tint.a *= alpha
		canvas.draw_line(a, b, tint, 2.0, false)
