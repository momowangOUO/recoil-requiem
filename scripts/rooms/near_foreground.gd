@tool
extends Node3D
## Authored 2D near silhouette. Origin is its highest visible contour.
@export_range(1.2, 3.2) var width := 2.6:
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
	var texture := preload("res://assets/environments/crimson/foreground_silhouette_v1.png")
	var image := texture.get_image()
	var region := image.get_used_rect()
	if not end_pier:
		# The right-hand bramble section excludes the single authored finial.
		var start := int(image.get_width() * 0.23)
		var crop := Rect2i(start, 0, image.get_width() - start, image.get_height())
		region = image.get_region(crop).get_used_rect()
		region.position += crop.position
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
	card.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(card)
