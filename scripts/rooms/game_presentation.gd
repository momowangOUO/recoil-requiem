extends Control
## 640x360 pixel world, native-resolution UI. Logical gameplay remains 320x180.

@export var campaign_enabled := true
var stage: CrimsonStage3D
var stage_viewport: SubViewport
var mouse_screen := Vector2(160, 90)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage_viewport = SubViewport.new()
	stage_viewport.name = "PixelWorld640x360"
	stage_viewport.size = Vector2i(640, 360)
	stage_viewport.own_world_3d = true
	stage_viewport.handle_input_locally = false
	stage_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	stage_viewport.msaa_3d = Viewport.MSAA_DISABLED
	add_child(stage_viewport)
	var display := TextureRect.new()
	display.name = "NearestPixelWorld"
	display.texture = stage_viewport.get_texture()
	display.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	display.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(display)
	stage = load("res://scenes/crimson_stage_3d.tscn").instantiate()
	stage.campaign_enabled = campaign_enabled
	stage.ui_host = self
	stage_viewport.add_child(stage)

func _input(event: InputEvent) -> void:
	if event is InputEventMouse:
		mouse_screen = event.position
	if is_instance_valid(stage):
		stage._input(event)

func get_aim_screen() -> Vector2:
	return mouse_screen
