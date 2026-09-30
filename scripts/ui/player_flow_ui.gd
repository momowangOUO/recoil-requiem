extends Control
## Authored title-stage background, native text and existing nine-slice controls.
signal action_requested(id: String)
signal setting_changed(key: String, value: Variant)

const FONT = preload("res://assets/fonts/unifont-18.0.01.otf")
const ART := "res://assets/ui/v2/runtime/"
const HERO_MANIFEST := "res://data/campaign/title_hero_poses.json"
const HERO_ACTIONS := {"begin":"ready", "continue":"ready", "explore":"ready", "checkpoint":"cylinder", "title_return":"lookback", "restart":"cylinder", "confirm":"cylinder", "cancel":"ready", "back":"ready", "settings":"cuff", "fullscreen":"cuff", "shake":"cuff", "help":"notebook", "journal":"notebook", "retry_save":"notebook", "retry_load":"notebook", "quit":"lookback", "quit_unsaved":"lookback"}
const HERO_PAGES := {"title":"ready", "pause":"ready", "completed":"ready", "restart":"cylinder", "settings":"cuff", "help":"notebook", "quit_unsaved":"lookback"}
const COPY := {
	"title":"反冲挽歌", "chapter":"猩红修道院", "continue":"继续游戏", "begin":"开始游戏",
	"restart":"从头开始", "quit":"退出游戏", "settings":"设置", "help":"操作说明", "back":"返回",
	"pause":"已暂停", "checkpoint":"从检查点重试", "title_return":"返回标题",
	"restart_title":"重新开始这一章？", "restart_body":"当前章节进度将重新开始。旧存档会保留备份。",
	"confirm":"确认重开", "cancel":"取消", "completed":"猩红修道院 · 本章完成",
	"completed_body":"你可以继续探索，查看留下的记录，或返回标题。", "explore":"继续探索", "journal":"查看记录",
	"volume":"主音量", "fullscreen":"全屏显示", "shake":"镜头震动", "retry_save":"重试保存", "retry_load":"重试读取存档",
	"settings_failed":"设置未保存。请检查存储空间或写入权限后重试。",
	"settings_load_failed":"设置文件无法读取，暂时使用默认设置。",
	"quit_unsaved_title":"退出前的进度尚未保存", "quit_unsaved_body":"退出后，尚未保存的进度将丢失。要直接退出吗？",
	"quit_unsaved":"不保存，退出游戏", "on":"开启", "off":"关闭",
	"help_body":"A / D　移动\nSpace　跳跃　　W　空中修正\n鼠标瞄准　左键射击　R 换弹\n1—6　选择枪槽　滚轮切枪\n短按 Q 切枪，按住 Q 查看枪槽\nV　爪击　　E　交谈或调查\nS　选择下方开放式楼梯或下穿格栅\nM　地图　　J　日志　　Esc　暂停"
}

var page := ""
var content: ScrollContainer
var stack: VBoxContainer
var status: Label
var buttons: Dictionary = {}
var art_rect := Rect2()
var background: TextureRect
var context: Dictionary = {}
var volume_control: HSlider
var volume_caption: Label
var hero: TextureRect
var hero_pose := ""
var hero_target_pose := ""
var hero_foot := Vector2.ZERO
var hero_scale := 1.0
var hero_load_error: Error = OK
var _hero_regions: Dictionary = {}
var _hero_config: Dictionary = {}
var _hero_tween: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Same native 1280px UI canvas as the existing campaign UI; world sampling is
	# unaffected. The project canvas scales it with the integer window transform.
	scale = Vector2.ONE * 0.25
	size = Vector2(1280, 720)
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	theme = Theme.new()
	theme.default_font = FONT
	theme.default_font_size = 24
	for kind in ["Label", "Button"]:
		theme.set_color("font_color", kind, Color("f2e7d4"))
	theme.set_color("font_hover_color", "Button", Color("30151c"))
	theme.set_color("font_pressed_color", "Button", Color("30151c"))
	theme.set_color("font_focus_color", "Button", Color("ffd18a"))
	theme.set_color("font_disabled_color", "Button", Color("7f777a"))
	for state in ["normal", "hover", "pressed", "disabled"]:
		theme.set_stylebox(state, "Button", _button_style(state))
	theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	background = TextureRect.new()
	background.texture = load(ART + "title_stage_v1.png")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	hero = TextureRect.new()
	hero.name = "TitleHero"
	hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero.hide()
	add_child(hero)
	content = ScrollContainer.new()
	content.name = "QuietMenuArea"
	content.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.follow_focus = true
	add_child(content)
	stack = VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 10)
	content.add_child(stack)
	resized.connect(_layout)
	_layout()
	if FileAccess.file_exists(HERO_MANIFEST): hero_load_error = load_hero_manifest()
	hide()

func _button_style(state: String) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = load(ART + "button_" + state + ".png")
	style.texture_margin_left = 24
	style.texture_margin_right = 24
	style.texture_margin_top = 22
	style.texture_margin_bottom = 22
	style.content_margin_left = 30
	style.content_margin_right = 30
	style.content_margin_top = 15
	style.content_margin_bottom = 15
	return style

func _layout() -> void:
	if background == null: return
	background.size = size
	var source := background.texture.get_size()
	var factor := minf(size.x / source.x, size.y / source.y)
	art_rect = Rect2((size - source * factor) * 0.5, source * factor)
	# Clear the silver divider, top flourish, and bottom corner ornaments.
	content.position = art_rect.position + art_rect.size * Vector2(0.705, 0.10)
	content.size = art_rect.size * Vector2(0.258, 0.78)
	_layout_hero()

func _label(value: String, font_size := 24) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	stack.add_child(label)
	return label

func _button(id: String, disabled := false) -> Button:
	var button := Button.new()
	button.name = id
	button.text = COPY[id]
	if id == "explore": button.text = str(preload("res://scripts/campaign/monastery_data.gd").texts().get("mon.flow.chapter.explore", COPY[id]))
	button.disabled = disabled
	button.custom_minimum_size.y = 56
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(func(): action_requested.emit(id))
	button.mouse_entered.connect(func(): _hero_button_attention(button, id))
	button.focus_entered.connect(func(): _hero_button_attention(button, id))
	stack.add_child(button)
	buttons[id] = button
	return button

func show_page(kind: String, values: Dictionary) -> void:
	page = kind
	context = values.duplicate(true)
	buttons.clear()
	volume_control = null
	volume_caption = null
	for child in stack.get_children():
		stack.remove_child(child)
		child.queue_free()
	content.scroll_vertical = 0
	var blocked: bool = context.get("save_code", "") == "load_failed"
	status = _label("", 20)
	status.name = "PersistentSaveStatus"
	status.add_theme_color_override("font_color", Color("ffd18a"))
	update_status(str(context.get("status", "")))
	match page:
		"title":
			_label(COPY.title, 46)
			_label(COPY.chapter, 26)
			_button("continue" if context.get("has_progress", false) else "begin", blocked)
			if context.get("has_progress", false):
				_label(str(context.get("location", "")), 22).name = "ContinueLocation"
				_label(str(context.get("current_objective", "")), 20).name = "ContinueObjective"
				_button("restart", blocked)
			_button("settings")
			_button("help")
			_button("quit")
		"pause":
			_label(COPY.pause, 36)
			_button("continue")
			_button("checkpoint")
			_button("settings")
			_button("help")
			_button("title_return")
			_button("quit")
		"restart":
			_label(COPY.restart_title, 32)
			_label(COPY.restart_body)
			_button("confirm", blocked)
			_button("cancel")
		"completed":
			_label(COPY.completed, 28)
			_label(COPY.completed_body)
			for line in context.get("summary", []): _label(str(line), 20)
			_button("explore")
			_button("journal")
			_button("title_return")
		"help":
			_label(COPY.help, 36)
			_label(COPY.help_body, 23)
			_button("back")
		"settings":
			_label(COPY.settings, 36)
			var settings: Dictionary = context.get("settings", {})
			var volume_label := _label(COPY.volume + "  %d%%" % roundi(float(settings.get("volume",1.0)) * 100))
			volume_caption = volume_label
			var volume := HSlider.new()
			volume_control = volume
			volume.name = "MasterVolume"
			volume.min_value = 0
			volume.max_value = 100
			volume.step = 1
			volume.value = float(settings.get("volume",1.0)) * 100
			volume.custom_minimum_size.y = 42
			volume.value_changed.connect(func(value: float):
				volume_label.text = COPY.volume + "  %d%%" % roundi(value)
				setting_changed.emit("volume", value / 100.0))
			stack.add_child(volume)
			for key in ["fullscreen", "shake"]:
				var toggle := _button(key)
				# A standard button reuses the authored frame instead of inventing
				# checkbox ornament; native text states its actual value.
				toggle.pressed.disconnect(toggle.pressed.get_connections()[0].callable)
				toggle.toggle_mode = true
				toggle.button_pressed = bool(settings.get(key, false))
				toggle.text = COPY[key] + "　" + COPY.on if toggle.button_pressed else COPY[key] + "　" + COPY.off
				toggle.toggled.connect(func(value: bool):
					toggle.text = COPY[key] + "　" + (COPY.on if value else COPY.off)
					setting_changed.emit(key, value))
			_button("back")
		"quit_unsaved":
			_label(COPY.quit_unsaved_title, 32)
			_label(COPY.quit_unsaved_body)
			_button("retry_save")
			_button("quit_unsaved")
			_button("cancel")
	if blocked and page != "quit_unsaved": _button("retry_load")
	elif context.get("save_code", "") == "write_failed" and page != "quit_unsaved": _button("retry_save")
	show()
	select_hero_pose(HERO_PAGES.get(page, "ready"))
	_focus_first.call_deferred()

func _focus_first() -> void:
	if not is_inside_tree() or not visible: return
	for button in buttons.values():
		if is_instance_valid(button) and button.is_inside_tree() and not button.disabled:
			button.grab_focus()
			break

func update_status(message: String) -> void:
	if status != null:
		status.text = message
		status.visible = not message.is_empty()

func update_settings(settings: Dictionary) -> void:
	if page != "settings": return
	if is_instance_valid(volume_control):
		volume_control.set_value_no_signal(float(settings.volume) * 100)
		volume_caption.text = COPY.volume + "  %d%%" % roundi(float(settings.volume) * 100)
	for key in ["fullscreen", "shake"]:
		if buttons.has(key):
			buttons[key].set_pressed_no_signal(bool(settings[key]))
			buttons[key].text = COPY[key] + "　" + (COPY.on if settings[key] else COPY.off)

func load_hero_manifest(path := HERO_MANIFEST) -> Error:
	if not FileAccess.file_exists(path): return ERR_FILE_NOT_FOUND
	var json := JSON.new()
	var error := json.parse(FileAccess.get_file_as_string(path))
	if error != OK: return error
	if not json.data is Dictionary or not json.data.get("texture") is String: return ERR_INVALID_DATA
	var texture: Texture2D = load(json.data.texture)
	if texture == null: return ERR_CANT_OPEN
	return configure_hero(json.data, texture)

func _number_array(value: Variant, count: int) -> bool:
	if not value is Array or value.size() != count: return false
	for item in value:
		if not (item is int or item is float) or not is_finite(float(item)): return false
	return true

## rect and anchor are source pixels; anchor is local to each cropped rect.
## Every pose uses one shared source-to-screen scale and the same foot position.
func configure_hero(data: Dictionary, texture: Texture2D) -> Error:
	if texture == null or not data.get("regions") is Array: return ERR_INVALID_DATA
	var reference: Variant = data.get("reference_height", texture.get_height())
	var display: Variant = data.get("display_height", 600.0)
	var foot: Variant = data.get("foot_position", [0.38,0.91])
	if not _number_array([reference,display], 2) or reference <= 0 or display <= 0 or not _number_array(foot, 2): return ERR_INVALID_DATA
	if foot[0] <= 0 or foot[0] >= 0.665 or foot[1] <= 0 or foot[1] > 1: return ERR_INVALID_DATA
	var regions := {}
	for entry in data.regions:
		if not entry is Dictionary or not entry.get("id") is String or regions.has(entry.id) or not _number_array(entry.get("rect"),4): return ERR_INVALID_DATA
		var rect := Rect2(entry.rect[0],entry.rect[1],entry.rect[2],entry.rect[3])
		var anchor: Variant = entry.get("anchor", [rect.size.x * 0.5, rect.size.y])
		if not rect.has_area() or not Rect2(Vector2.ZERO,texture.get_size()).encloses(rect) or not _number_array(anchor,2): return ERR_INVALID_DATA
		if anchor[0] < 0 or anchor[0] > rect.size.x or anchor[1] < 0 or anchor[1] > rect.size.y: return ERR_INVALID_DATA
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = rect
		atlas.filter_clip = true
		regions[entry.id] = {"texture":atlas, "size":rect.size, "anchor":Vector2(anchor[0],anchor[1])}
	for id in ["ready","cylinder","cuff","notebook","lookback"]:
		if not regions.has(id): return ERR_INVALID_DATA
	if _hero_tween != null: _hero_tween.kill()
	_hero_regions = regions
	_hero_config = {"reference_height":reference, "display_height":display, "foot_position":Vector2(foot[0],foot[1])}
	hero_pose = "ready"
	hero_target_pose = "ready"
	hero.modulate.a = 1.0
	_layout_hero()
	hero.show()
	return OK

func _layout_hero() -> void:
	if _hero_regions.is_empty() or not art_rect.has_area(): return
	hero_foot = art_rect.position + art_rect.size * _hero_config.foot_position
	hero_scale = float(_hero_config.display_height) / float(_hero_config.reference_height) * art_rect.size.y / 720.0
	# Fit the largest extents once for the entire atlas, never resize an individual
	# pose. A wide gesture cannot cover the silver divider or the menu text.
	for pose in _hero_regions.values():
		var extents := [pose.anchor.x, pose.size.x-pose.anchor.x, pose.anchor.y, pose.size.y-pose.anchor.y]
		var available := [hero_foot.x-art_rect.position.x, art_rect.position.x+art_rect.size.x*0.665-hero_foot.x, hero_foot.y-art_rect.position.y, art_rect.end.y-hero_foot.y]
		for index in 4:
			if extents[index] > 0: hero_scale = minf(hero_scale, available[index]/extents[index])
	_apply_hero_pose(hero_pose)

func _apply_hero_pose(id: String) -> void:
	if not _hero_regions.has(id): return
	hero_pose = id
	var pose: Dictionary = _hero_regions[id]
	hero.texture = pose.texture
	hero.size = pose.size * hero_scale
	hero.position = hero_foot - pose.anchor * hero_scale

func _hero_button_attention(button: Button, id: String) -> void:
	if button.disabled or not HERO_ACTIONS.has(id): return
	if not button.has_focus(): button.grab_focus()
	select_hero_pose(HERO_ACTIONS[id])

func select_hero_pose(id: String) -> void:
	if not _hero_regions.has(id) or hero_target_pose == id: return
	hero_target_pose = id
	if _hero_tween != null: _hero_tween.kill()
	if not is_visible_in_tree():
		_apply_hero_pose(id)
		hero.modulate.a = 1.0
		return
	_hero_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	if hero_pose != id:
		# One TextureRect: switch its crop only at zero alpha, never cross-fade
		# two faces. Killing this tween also cancels its obsolete crop callback.
		_hero_tween.tween_property(hero, "modulate:a", 0.0, 0.07)
		_hero_tween.tween_callback(func(): _apply_hero_pose(id))
	_hero_tween.tween_property(hero, "modulate:a", 1.0, 0.11)
