class_name PaperStage
extends Node2D
## Shared visual layers; camera motion never changes gameplay coordinates.

const BACKGROUND = preload("res://assets/environments/crimson/background_v1.png")
const ATLAS = preload("res://assets/environments/crimson/atlas_v1.png")
const COLUMN_REGION := Rect2(228, 589, 292, 629)
const CANDLE_REGION := Rect2(820, 718, 218, 497)
const FAR_FACTOR := 0.22
const MID_FACTOR := 0.68
const FRONT_FACTOR := 1.08
const LOOK_AHEAD := 24.0
var far_layer := Node2D.new()
var mid_layer := Node2D.new()
var back_layer := Node2D.new()
var front_layer := Node2D.new()
var actors: Array[CharacterBody2D] = []
var greybox := false

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for entry in [[far_layer, "Background", -300], [mid_layer, "Midground", -200], [back_layer, "BackDecor", -100], [front_layer, "Foreground", 100]]:
		entry[0].name = entry[1]
		entry[0].z_index = entry[2]
		add_child(entry[0])
	for x in range(-1, 3):
		var background := Sprite2D.new()
		background.texture = BACKGROUND
		background.centered = false
		background.scale = Vector2(0.32, 0.32)
		background.position = Vector2(x * 535, -80)
		background.modulate = Color("8b8798")
		far_layer.add_child(background)
	for x in [36, 268, 500, 732, 964]:
		_prop(mid_layer, COLUMN_REGION, Vector2(x, 320), Vector2(46, 232), Color("625363"))
	for x in [40, 368, 816, 928]:
		_prop(back_layer, CANDLE_REGION, Vector2(x, 352), Vector2(13, 29), Color("b29aa0"))
	for x in [-32, 980]:
		_prop(front_layer, COLUMN_REGION, Vector2(x, 396), Vector2(54, 288), Color("514452"))

func _prop(layer: Node2D, region: Rect2, foot: Vector2, size: Vector2, tint: Color) -> void:
	var sprite := Sprite2D.new()
	var texture := AtlasTexture.new()
	texture.atlas = ATLAS
	texture.region = region
	sprite.texture = texture
	sprite.centered = false
	sprite.scale = size / region.size
	sprite.position = foot - Vector2(size.x * 0.5, size.y)
	sprite.modulate = tint
	layer.add_child(sprite)

func follow_camera(center: Vector2) -> void:
	var displacement := center - Vector2(160, 288)
	far_layer.position = (displacement * (1.0 - FAR_FACTOR)).round()
	mid_layer.position = (displacement * (1.0 - MID_FACTOR)).round()
	front_layer.position = (displacement * (1.0 - FRONT_FACTOR)).round()
	# Foreground props yield when an actor is near, including a knocked-down enemy.
	for prop in front_layer.get_children():
		var obscures := false
		for actor in actors:
			if is_instance_valid(actor) and absf(actor.global_position.x - (prop.global_position.x + 27)) < 48:
				obscures = true
		prop.modulate.a = 0.15 if obscures else 1.0

func set_greybox(enabled: bool) -> void:
	greybox = enabled
	# Preserve depth and parallax, only simplify materials.
	far_layer.modulate = Color("5d5969") if enabled else Color.WHITE
	mid_layer.modulate = Color("514d61") if enabled else Color.WHITE

func add_actor(actor: CharacterBody2D) -> void:
	actors.append(actor)
	var shadow := ContactShadow.new()
	shadow.actor = actor
	add_child(shadow)
