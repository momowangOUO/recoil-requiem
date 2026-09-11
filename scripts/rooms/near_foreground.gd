@tool
extends Node3D
## Authored 2D near silhouette. Origin is its highest visible contour.
@export_range(1.2, 6.0) var width := 2.6:
	set(value):
		width = value
		if is_inside_tree(): rebuild()
@export var end_pier := false:
	set(value):
		end_pier = value
		if is_inside_tree(): rebuild()

func _ready() -> void: rebuild()

func rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var texture := preload("res://assets/environments/crimson/foreground_embankment_v2.png")
	# Authored contour bounds exclude nearly transparent generator specks.
	var region := Rect2i(364, 270, 890, 984)
	var card := Sprite3D.new()
	card.name = "AuthoredNearSilhouette"
	card.texture = texture
	card.region_enabled = true
	card.region_rect = region
	card.pixel_size = width / float(region.size.x)
	card.position = Vector3(width * 0.5, -region.size.y * card.pixel_size * 0.5, 0)
	card.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	card.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	card.shaded = false
	card.modulate = Color(0.6, 0.6, 0.68, 1.0)
	card.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(card)
	if end_pier:
		var pier := card.duplicate() as Sprite3D
		pier.name = "AttachedFinial"
		pier.region_rect = Rect2(214, 73, 110, 278)
		pier.pixel_size = 0.28 / 110.0
		pier.position = Vector3(0.6, -278 * pier.pixel_size * 0.5, 0.002)
		add_child(pier)
