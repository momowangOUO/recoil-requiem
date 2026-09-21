class_name CampaignUI
extends Control

const CampaignData = preload("res://scripts/campaign/monastery_data.gd")

signal close_requested
signal choice_selected(id: String)
signal side_selected(id: String)

const STATUS_COPY := {"track":"追踪", "tracked":"正在追踪", "complete":"已完成", "active":"进行中"}

const COPY := {"main":"当前目标", "side":"支线", "journal":"日志", "map":"地图", "tasks":"任务", "clues":"线索", "people":"人物", "consequences":"后果", "empty":"暂无记录。", "close":"关闭 · Esc", "keys":"J 日志　M 地图", "map_legend":"当前位置　检查点　锁闭　已开通　未探索入口", "unknown":"未探索入口"}
const INK := Color("eee4d2")
const SILVER := Color("b4b1b8")
const ART_DIR := "res://assets/ui/v2/runtime/"
const MAP_SOURCE := "res://data/campaign/monastery_map_ui.json"
var panel_kind := ""
var tracker: VBoxContainer
var panel: PanelContainer
var content: VBoxContainer
var _main: Label
var _side: Label
var _opening: Label
var _completion: Label
var _controls: Label
var _modal_scrim: ColorRect
var _interaction_art: PanelContainer
var _interaction_label: Label
var _entries: Array = []
var _category := "tasks"
var _map: Control
var _map_preview: TextureRect
var _map_preview_title: Label
var _map_data: Dictionary = {}
var _map_selected := ""
var _font_multiplier := 1.0
var _tracker_art: TextureRect
var _art: Dictionary = {}
var _map_source: Dictionary = {}
var _map_zoom := 0.14
var _map_pan := Vector2.ZERO
var _map_focus := Vector2.ZERO
var _map_dragging := false
var _map_full := false
var _ui_copy: Dictionary = {}
var _last_main_text := ""
var _completion_serial := 0
var _completion_active := false
var _opening_started := false
var _opening_active := false
var _opening_serial := 0
var _onboarding_active := true
var _onboarding_started := false
var _onboarding_serial := 0
var _interaction_target := ""
var _interaction_action := ""
var _external_pause_hidden := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	scale = Vector2.ONE * 0.25
	size = Vector2(1280, 720)
	theme = Theme.new()
	theme.default_font_size = 24
	theme.set_color("font_color", "Label", INK)
	theme.set_color("font_color", "Button", INK)
	for state in ["normal", "hover", "pressed", "disabled"]:
		theme.set_stylebox(state, "Button", _style("button_" + state, 24, 22, 24, 22, 32, 22, 32, 22))
	# Focus is an overlay in Godot. A second ornate texture here would be drawn over
	# the normal frame, so keyboard focus uses warm text instead of a duplicate frame.
	theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	theme.set_color("font_focus_color", "Button", Color("ffd18a"))
	theme.set_color("font_disabled_color", "Button", Color("ada3a6"))
	theme.set_color("font_hover_color", "Button", Color("2c1c20"))
	_ui_copy = CampaignData.onboarding_ui()
	var map_file := FileAccess.open(MAP_SOURCE, FileAccess.READ)
	if map_file != null:
		var decoded: Variant = JSON.parse_string(map_file.get_as_text())
		if decoded is Dictionary: _map_source = decoded
	_tracker_art = TextureRect.new()
	_tracker_art.position = Vector2(677, 28)
	_tracker_art.size = Vector2(553, 183)
	_tracker_art.texture = _texture("tracker_frame")
	_tracker_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_tracker_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_tracker_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_tracker_art)
	tracker = VBoxContainer.new()
	tracker.position = Vector2(780, 80)
	tracker.size = Vector2(400, 112)
	tracker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tracker.add_theme_constant_override("separation", 6)
	add_child(tracker)
	_main = _label("", 23)
	tracker.add_child(_main)
	_side = _label("", 20)
	tracker.add_child(_side)
	_opening = _label("", 21, Color("f3e5d0"))
	_opening.position = Vector2(210, 550)
	_opening.size = Vector2(860, 78)
	_opening.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_opening.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_opening.add_theme_color_override("font_outline_color", Color(0.06, 0.035, 0.05, 0.98))
	_opening.add_theme_constant_override("outline_size", 2)
	_opening.hide()
	add_child(_opening)
	_controls = _label(str(_ui_copy.get("controls", "")), 16, SILVER)
	_controls.position = Vector2(360, 632)
	_controls.size = Vector2(560, 50)
	_controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_controls.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_controls)
	_completion = _label("", 19, Color("e0bd7a"))
	_completion.position = Vector2(420, 300)
	_completion.size = Vector2(440, 42)
	_completion.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_completion.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_completion.add_theme_color_override("font_outline_color", Color(0.06, 0.035, 0.05, 0.98))
	_completion.add_theme_constant_override("outline_size", 2)
	_completion.hide()
	add_child(_completion)
	_modal_scrim = ColorRect.new()
	_modal_scrim.position = Vector2.ZERO
	_modal_scrim.size = Vector2(1280, 720)
	_modal_scrim.color = Color(0.02, 0.012, 0.026, 0.58)
	_modal_scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	_modal_scrim.hide()
	add_child(_modal_scrim)
	panel = PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.mouse_force_pass_scroll_events = false
	panel.add_theme_stylebox_override("panel", _style("journal_frame", 120, 120, 120, 120, 112, 72, 112, 68))
	add_child(panel)
	panel.hide()
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	panel.add_child(content)
	_interaction_art = PanelContainer.new()
	_interaction_art.position = Vector2(430, 618)
	_interaction_art.size = Vector2(420, 72)
	_interaction_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_interaction_art.add_theme_stylebox_override("panel", _style("button_normal", 24, 22, 24, 22, 32, 22, 32, 22))
	add_child(_interaction_art)
	_interaction_label = _label("", 22)
	_interaction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_interaction_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_interaction_art.add_child(_interaction_label)
	_interaction_art.hide()
	get_window().size_changed.connect(_adapt_type)
	_adapt_type()

func _process(_delta: float) -> void:
	# Lab pause/settings owns the whole screen. Campaign modals also pause the tree,
	# so only hide when the pause did not originate from this UI.
	var should_hide := get_tree().paused and panel_kind.is_empty()
	if should_hide == _external_pause_hidden: return
	_external_pause_hidden = should_hide
	visible = not should_hide

func _fit_tracker() -> void:
	# A selected side objective needs one more wrapped line at 960. Grow the whole
	# authored frame proportionally instead of stretching its quiet center or text.
	if _side.visible:
		var expanded_width := 700.0
		_tracker_art.position = Vector2(530, 28)
		_tracker_art.size = Vector2(expanded_width, expanded_width * 183.0 / 553.0)
		tracker.position = Vector2(650, 96)
		tracker.size = Vector2(530, 96)
	else:
		_tracker_art.position = Vector2(677, 28)
		_tracker_art.size = Vector2(553, 183)
		tracker.position = Vector2(780, 80)
		tracker.size = Vector2(400, 112)

func _texture(name: String) -> Texture2D:
	if _art.has(name): return _art[name]
	var path := ART_DIR + name + ".png"
	var result: Texture2D = load(path) if ResourceLoader.exists(path) else null
	if result == null:
		var source := Image.load_from_file(path)
		if source != null and not source.is_empty(): result = ImageTexture.create_from_image(source)
	_art[name] = result
	return result

func _style(name: String, left: float, top: float, right: float, bottom: float, pad_left: float, pad_top: float, pad_right: float, pad_bottom: float, draw_center := true) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = _texture(name)
	style.texture_margin_left = left
	style.texture_margin_top = top
	style.texture_margin_right = right
	style.texture_margin_bottom = bottom
	style.content_margin_left = pad_left
	style.content_margin_top = pad_top
	style.content_margin_right = pad_right
	style.content_margin_bottom = pad_bottom
	style.draw_center = draw_center
	return style

func _adapt_type() -> void:
	_font_multiplier = maxf(1.0, 1280.0 / maxf(get_window().size.x, 1))
	theme.default_font_size = roundi(24 * _font_multiplier)
	for label in find_children("*", "Label", true, false):
		if label.has_meta("base_font_size"):
			label.add_theme_font_size_override("font_size", roundi(float(label.get_meta("base_font_size")) * _font_multiplier))
	if is_instance_valid(_map): _map.queue_redraw()
	_fit_tracker.call_deferred()

func _label(value: String, font_size: int = 24, color: Color = INK) -> Label:
	var label := Label.new()
	label.text = value
	label.set_meta("base_font_size", font_size)
	label.add_theme_font_size_override("font_size", roundi(font_size * _font_multiplier))
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0.08, 0.06, 0.10, 0.95))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func set_tracker(main_text: String, side_text: String = "") -> void:
	if not _last_main_text.is_empty() and main_text != _last_main_text:
		_show_completion(_last_main_text)
	var is_opening := main_text == str(_ui_copy.get("objective", ""))
	if is_opening and not _opening_started:
		_start_opening_caption()
	elif not is_opening:
		_opening_active = false
		_opening.hide()
	_controls.text = str(_ui_copy.get("opening_controls", "")) if is_opening else str(_ui_copy.get("controls", ""))
	_controls.visible = _onboarding_active and panel_kind.is_empty() and _interaction_action.is_empty()
	# Keep category labels inline. Fixed title-only rows wasted half the compact
	# tracker and could push a selected side quest into the lower ornament at 960.
	_main.text = COPY.main + "　" + main_text if not main_text.is_empty() else ""
	_side.text = COPY.side + "　" + side_text if not side_text.is_empty() else ""
	_side.visible = not side_text.is_empty()
	_last_main_text = main_text
	_fit_tracker.call_deferred()

func _start_opening_caption() -> void:
	_opening_started = true
	_opening_active = true
	_opening_serial += 1
	var serial := _opening_serial
	var opening_lines: Array = _ui_copy.get("lines", [])
	_opening.text = str(_ui_copy.get("speaker", "")) + "：" + "\n".join(opening_lines)
	_opening.visible = panel_kind.is_empty()
	_start_onboarding_timeout()
	get_tree().create_timer(6.0, true).timeout.connect(func():
		if serial == _opening_serial:
			_opening_active = false
			_opening.hide()
	)

func _start_onboarding_timeout() -> void:
	if _onboarding_started: return
	_onboarding_started = true
	_onboarding_serial += 1
	var serial := _onboarding_serial
	get_tree().create_timer(8.0, true).timeout.connect(func():
		if serial == _onboarding_serial:
			_onboarding_active = false
			_controls.hide()
	)

func _show_completion(objective: String) -> void:
	_completion_serial += 1
	var serial := _completion_serial
	_completion_active = true
	_completion.text = str(_ui_copy.get("completed", "已完成：{objective}")).replace("{objective}", objective)
	_completion.visible = panel_kind.is_empty()
	get_tree().create_timer(3.0, true).timeout.connect(func():
		if serial == _completion_serial:
			_completion_active = false
			_completion.hide()
	)

func set_interaction_prompt(target: String = "", action: String = "") -> void:
	_interaction_target = target
	_interaction_action = action
	if action.is_empty():
		_interaction_label.text = ""
		_interaction_art.hide()
		return
	# Reaching a concrete world action ends the transient opening/tutorial stage.
	# Keep the contextual E prompt as the only instruction near the player.
	_opening_active = false
	_opening.hide()
	_onboarding_active = false
	_controls.hide()
	var target_copy := "" if target.is_empty() else "　" + target
	_interaction_label.text = str(_ui_copy.get("interact", "E　{action}{target}")).replace("{action}", action).replace("{target}", target_copy)
	_interaction_art.visible = panel_kind.is_empty()

func interaction_prompt_visible() -> bool:
	return _interaction_art.visible

func is_panel_open() -> bool:
	return not panel_kind.is_empty()

func close_panel() -> void:
	panel_kind = ""
	panel.hide()
	_modal_scrim.hide()
	tracker.show()
	if _tracker_art: _tracker_art.show()
	_opening.visible = _opening_active
	_controls.visible = _onboarding_active and _interaction_action.is_empty()
	_completion.visible = _completion_active
	_interaction_art.visible = not _interaction_action.is_empty()

func _open(kind: String, title: String) -> void:
	panel_kind = kind
	_interaction_art.hide()
	tracker.hide()
	if _tracker_art: _tracker_art.hide()
	_opening.hide()
	_controls.hide()
	_completion.hide()
	_modal_scrim.show()
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	panel.position = Vector2(120, 38) if kind != "dialogue" else Vector2(280, 315)
	panel.size = Vector2(1040, 644) if kind != "dialogue" else Vector2(830, 365)
	panel.add_theme_stylebox_override("panel", _style("dialogue_frame", 96, 90, 96, 90, 86, 54, 86, 50) if kind == "dialogue" else _style("journal_frame", 120, 120, 120, 120, 112, 72, 112, 68))
	var header := HBoxContainer.new()
	content.add_child(header)
	if not title.is_empty():
		var heading := _label(title, 30)
		heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header.add_child(heading)
	else:
		var header_space := Control.new()
		header_space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header.add_child(header_space)
	var close := Button.new()
	close.text = str(_ui_copy.get("end_talk", "结束交谈 · Esc")) if kind == "dialogue" else COPY.close
	close.pressed.connect(func(): close_requested.emit())
	header.add_child(close)
	panel.show()

func _scroll() -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 16)
	scroll.add_child(body)
	return body

func show_dialogue(_speaker: String, lines: Array, choices: Array) -> void:
	# Runtime lines already carry the actual speaker. Keep the modal header quiet and
	# separate the name from the sentence instead of repeating it in two places.
	_open("dialogue", "")
	var body := _scroll()
	for line in lines:
		_add_dialogue_line(body, str(line))
	for choice in choices:
		var button := Button.new()
		button.text = str(choice.get("text", ""))
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = 72
		var id := str(choice.get("id", ""))
		button.pressed.connect(func(): choice_selected.emit(id))
		body.add_child(button)

func _add_dialogue_line(body: VBoxContainer, value: String) -> void:
	var separator := value.find("：")
	var who := value.left(separator) if separator > 0 else ""
	if separator > 0 and separator <= 4 and who in CampaignData.NAMES.values():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		body.add_child(row)
		var speaker := _label(who, 18, Color("d8b77c"))
		speaker.custom_minimum_size.x = 62
		speaker.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		row.add_child(speaker)
		var spoken := _label(value.substr(separator + 1).strip_edges())
		spoken.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(spoken)
	else:
		body.add_child(_label(value))

func show_journal(entries: Array, selected_category: String = "tasks") -> void:
	_entries = entries.duplicate(true)
	_category = selected_category if selected_category in ["tasks", "clues", "people", "consequences"] else "tasks"
	_open("journal", COPY.journal)
	var tabs := HBoxContainer.new()
	content.add_child(tabs)
	for category in ["tasks", "clues", "people", "consequences"]:
		var button := Button.new()
		button.text = COPY[category]
		button.toggle_mode = true
		button.button_pressed = category == _category
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(func(): show_journal(_entries, category))
		tabs.add_child(button)
	var body := _scroll()
	var count := 0
	for entry in entries:
		if str(entry.get("category", "tasks")) != _category:
			continue
		body.add_child(_label(str(entry.get("title", "")), 27))
		body.add_child(_label(str(entry.get("body", ""))))
		if entry.has("track_id"):
			var track := Button.new()
			track.text = STATUS_COPY.tracked if entry.get("tracked",false) else STATUS_COPY.track
			track.disabled = entry.get("tracked",false)
			var track_id: String = entry.track_id
			track.pressed.connect(func(): side_selected.emit(track_id))
			body.add_child(track)
		count += 1
	if count == 0:
		body.add_child(_label(COPY.empty, 24, SILVER))

func show_map(spaces: Dictionary, connections: Array, visited: Array, gate_states: Dictionary, player_position: Vector2, checkpoints: Array, shortcuts: Array = [], gate_platforms: Dictionary = {}) -> void:
	_open("map", COPY.map)
	var known := visited.duplicate()
	known.sort_custom(func(a, b): return int(str(a).trim_prefix("mon_")) < int(str(b).trim_prefix("mon_")))
	_map_data = {"spaces":spaces, "connections":connections, "visited":known, "gates":gate_states, "player":player_position, "checkpoints":checkpoints, "shortcuts":shortcuts, "gate_platforms":gate_platforms}
	_map_selected = ""
	for id in known:
		if spaces.has(id) and spaces[id].rect.has_point(player_position):
			_map_selected = str(id)
			break
	_map_focus = player_position
	_map_pan = Vector2.ZERO
	_map_full = false
	_map_dragging = false
	var toolbar := HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 8)
	content.add_child(toolbar)
	for spec in [["－", "zoom_out"], ["＋", "zoom_in"], ["回到当前位置", "player"], ["全图", "full"]]:
		var action := Button.new()
		action.text = spec[0]
		action.custom_minimum_size.y = 72
		action.pressed.connect(_map_action.bind(spec[1]))
		toolbar.add_child(action)
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 14)
	content.add_child(row)
	_map = Control.new()
	_map.custom_minimum_size = Vector2(0, 300)
	_map.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_map.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_map.mouse_filter = Control.MOUSE_FILTER_STOP
	_map.clip_contents = true
	_map.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	row.add_child(_map)
	_map.draw.connect(_draw_map)
	_map.resized.connect(func(): _map.queue_redraw())
	_map.gui_input.connect(_on_map_input)
	var sidebar := VBoxContainer.new()
	sidebar.custom_minimum_size.x = 204
	sidebar.add_theme_constant_override("separation", 6)
	row.add_child(sidebar)
	var preview := HBoxContainer.new()
	preview.custom_minimum_size.y = 49
	preview.add_theme_constant_override("separation", 7)
	sidebar.add_child(preview)
	_map_preview = TextureRect.new()
	_map_preview.custom_minimum_size = Vector2(46, 46)
	_map_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_map_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.add_child(_map_preview)
	_map_preview_title = _label("", 18)
	_map_preview_title.custom_minimum_size.x = 130
	_map_preview_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	_map_preview_title.clip_text = true
	_map_preview_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	preview.add_child(_map_preview_title)
	_update_map_preview()
	sidebar.add_child(_label("同字母＝捷径两端\n点线＝已开通", 15, SILVER))
	var legend_scroll := ScrollContainer.new()
	legend_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	legend_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sidebar.add_child(legend_scroll)
	var legend := VBoxContainer.new()
	legend.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	legend.add_theme_constant_override("separation", 6)
	legend_scroll.add_child(legend)
	for id in known:
		if not spaces.has(id): continue
		var button := Button.new()
		button.text = "%02d  %s" % [int(str(id).trim_prefix("mon_")), str(spaces[id].get("title",id))]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.autowrap_mode = TextServer.AUTOWRAP_OFF
		button.add_theme_font_size_override("font_size", roundi(20 * _font_multiplier))
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = 72
		for state in ["normal", "hover", "pressed", "disabled"]:
			button.add_theme_stylebox_override(state, _style("button_" + state, 24, 22, 24, 22, 32, 22, 32, 22))
		button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		button.pressed.connect(_select_map_region.bind(str(id)))
		legend.add_child(button)
	var legend_row := HBoxContainer.new()
	legend_row.add_theme_constant_override("separation", 8)
	content.add_child(legend_row)
	for item in [["map_player", "当前位置"], ["map_checkpoint", "检查点"], ["map_lock", "锁闭"], ["map_unknown", "未探索"]]:
		var pair := HBoxContainer.new()
		pair.add_theme_constant_override("separation", 5)
		legend_row.add_child(pair)
		var icon := TextureRect.new()
		icon.texture = _texture(item[0])
		icon.custom_minimum_size = Vector2(23, 23)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pair.add_child(icon)
		var caption := _label(item[1], 17, SILVER)
		caption.autowrap_mode = TextServer.AUTOWRAP_OFF
		pair.add_child(caption)
	_reset_map_view.call_deferred()

func _landmark_art(id: String) -> String:
	for landmark in _map_source.get("landmarks", []):
		if landmark.get("space_id", "") == id: return str(landmark.get("art", ""))
	return ""

func _map_anchor(id: String) -> Vector2:
	var anchors: Dictionary = _map_source.get("label_anchors", {})
	return _source_point(anchors[id]) if anchors.has(id) else _map_data.spaces[id].rect.get_center()

func _select_map_region(id: String) -> void:
	if not _map_data.spaces.has(id) or not id in _map_data.visited: return
	_map_selected = id
	_map_focus = _map_anchor(id)
	_map_pan = Vector2.ZERO
	_map_zoom = _local_map_zoom()
	_map_full = false
	_update_map_preview()
	_map.queue_redraw()

func _update_map_preview() -> void:
	if not is_instance_valid(_map_preview) or not is_instance_valid(_map_preview_title): return
	var art := _landmark_art(_map_selected)
	_map_preview.texture = _texture(art if not art.is_empty() else "map_player")
	_map_preview_title.text = str(_map_data.spaces.get(_map_selected, {}).get("title", ""))

func _draw_map() -> void:
	if _map_data.is_empty() or _map.size.x < 10: return
	var parchment := _texture("map_parchment")
	if parchment != null:
		_map.draw_texture_rect(parchment, Rect2(Vector2.ZERO, _map.size), false, Color(0.85, 0.79, 0.72, 0.90))
	var offset := _map_offset()
	var factor := Vector2.ONE * _map_zoom
	var strip := AtlasTexture.new()
	strip.atlas = _texture("map_route")
	strip.region = Rect2(82, 29, 280, 20)
	_draw_shortcut_links(offset)
	for segment in _map_source.get("segments", []):
		var start := _source_point(segment.get("start", []))
		var end := _source_point(segment.get("end", []))
		for piece in _visible_route_pieces(start, end, str(segment.get("id", ""))):
			_draw_route(piece[0] * _map_zoom + offset, piece[1] * _map_zoom + offset, strip, bool(segment.get("one_way", false)), str(segment.get("kind", "")) == "stair")
	var marker_size := clampf(_map_zoom * 112.0, 12.0, 19.0)
	for exit in _unknown_route_exits():
		_draw_icon("map_unknown", exit * _map_zoom + offset, Vector2.ONE * marker_size)
	for mark in _map_shortcut_marks():
		var at: Vector2 = mark.position * _map_zoom + offset
		_draw_icon("map_open" if mark.opened else "map_lock", at, Vector2.ONE * maxf(18.0, marker_size))
		_map.draw_string(ThemeDB.fallback_font, at + Vector2(9, -9), str(mark.label), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, INK)
	var gate_points := _map_gate_world_points()
	for gate in ["gate_departure", "gate_departure_back"]:
		if gate_points.has(gate) and _known_point(gate_points[gate]):
			_draw_icon("map_open" if bool(_map_data.gates.get(gate, false)) else "map_lock", gate_points[gate] * _map_zoom + offset, Vector2.ONE * marker_size)
	for checkpoint in _map_data.checkpoints:
		var point: Vector2 = checkpoint if checkpoint is Vector2 else checkpoint.get("position", Vector2.ZERO)
		if _known_point(point): _draw_icon("map_checkpoint", point * _map_zoom + offset, Vector2.ONE * marker_size)
	var numbers := _map_number_rects(factor, offset)
	for id in numbers:
		if _map_zoom < 0.06 and str(id) != _map_selected: continue
		var rect: Rect2 = numbers[id]
		_draw_icon("map_selection", rect.get_center(), Vector2(30, 30), Color(1, 1, 1, 0.9 if str(id) == _map_selected else 0.65))
		var number := "%02d" % int(str(id).trim_prefix("mon_"))
		_map.draw_string(ThemeDB.fallback_font, rect.position + Vector2(2, 19), number, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, INK)
	_draw_icon("map_player", _map_data.player * _map_zoom + offset, Vector2.ONE * maxf(20.0, marker_size * 1.3))

func _source_point(raw: Array) -> Vector2:
	return Vector2(float(raw[0]), float(raw[1])) if raw.size() >= 2 else Vector2.ZERO

func _map_view() -> Rect2:
	return Rect2(Vector2.ZERO, _map.size)

func _map_offset() -> Vector2:
	return _map.size * 0.5 + _map_pan - _map_focus * _map_zoom

func _world_at_map(at: Vector2) -> Vector2:
	return (at - _map_offset()) / _map_zoom

func _map_bounds() -> Rect2:
	var raw: Array = _map_source.get("world_bounds", [])
	return Rect2(Vector2(float(raw[0]), float(raw[1])), Vector2(float(raw[2]) - float(raw[0]), float(raw[3]) - float(raw[1]))) if raw.size() == 4 else Rect2(0, -2080, 16384, 6200)

func _full_map_zoom() -> float:
	var bounds := _map_bounds()
	return minf((_map.size.x - 46) / bounds.size.x, (_map.size.y - 38) / bounds.size.y)

func _reset_map_view() -> void:
	if not is_instance_valid(_map) or _map.size.x < 10: return
	_map_focus = _map_data.player
	_map_pan = Vector2.ZERO
	_map_zoom = _local_map_zoom()
	_map_full = false
	_map.queue_redraw()

func _local_map_zoom() -> float:
	return minf(0.18, minf((_map.size.x - 36) / 4500.0, (_map.size.y - 36) / 3000.0))

func _map_action(action: String) -> void:
	match action:
		"player": _reset_map_view()
		"full":
			_map_zoom = _full_map_zoom()
			_map_focus = _map_bounds().get_center()
			_map_pan = Vector2.ZERO
			_map_full = true
		"zoom_in": _zoom_map(1.3, _map.size * 0.5)
		"zoom_out": _zoom_map(1.0 / 1.3, _map.size * 0.5)
	_map.queue_redraw()

func _zoom_map(amount: float, anchor: Vector2) -> void:
	var before := _world_at_map(anchor)
	_map_zoom = clampf(_map_zoom * amount, _full_map_zoom(), 0.35)
	_map_pan += anchor - (before * _map_zoom + _map_offset())
	_map_full = false

func _on_map_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_zoom_map(1.16, event.position)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_zoom_map(1.0 / 1.16, event.position)
		elif event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_MIDDLE]:
			_map_dragging = event.pressed
		else: return
		_map.accept_event()
		_map.queue_redraw()
	elif event is InputEventMouseMotion and _map_dragging:
		_map_pan += event.relative
		_map.accept_event()
		_map.queue_redraw()

func _draw_icon(name: String, at: Vector2, extent: Vector2, tint := Color.WHITE) -> void:
	var texture := _texture(name)
	if texture == null or not _map_view().grow(40).has_point(at): return
	_map.draw_texture_rect(texture, Rect2(at - extent * 0.5, extent), false, tint)

func _draw_route(start: Vector2, finish: Vector2, strip: Texture2D, one_way: bool, stair: bool) -> void:
	var length := start.distance_to(finish)
	if length < 2: return
	# Source geometry is a walkable deck or stair; the narrow inlay never covers junctions.
	var width := clampf(_map_zoom * (54.0 if one_way else 72.0), 3.5, 10.0)
	_map.draw_set_transform(start, (finish - start).angle())
	_map.draw_texture_rect(strip, Rect2(0, -width * 0.5, length, width), false, Color("6f656c") if one_way else Color("a49087"))
	_map.draw_line(Vector2.ZERO, Vector2(length, 0), Color("d7c9ba") if one_way else Color("f4dfbf"), 1.4 if stair else 2.0, true)
	if stair:
		var step := 14.0 if _map_zoom > 0.075 else 10.0
		for i in range(1, int(length / step)):
			var at := i * step
			_map.draw_line(Vector2(at, -width * 0.38), Vector2(at, width * 0.38), Color("a98e81", 0.8), 1.0, true)
	elif one_way:
		for i in range(1, int(length / 11.0)):
			var at := i * 11.0
			_map.draw_line(Vector2(at, -width * 0.36), Vector2(at, width * 0.36), Color("8f7777", 0.8), 1.0, true)
	_map.draw_set_transform(Vector2.ZERO)

func _visible_route_pieces(start: Vector2, finish: Vector2, segment_id: String = "") -> Array:
	# Regions overlap in the authored scene. Merge their intervals on this one
	# physical segment before painting, or the overlap becomes a bright double road.
	var delta := finish - start
	if delta.length_squared() < 1.0: return []
	var owners: Array = _map_source.get("transition_visibility", {}).get(segment_id, [])
	if not owners.is_empty() and owners.all(func(id): return id in _map_data.visited):
		return [PackedVector2Array([start, finish])]
	var intervals: Array[Vector2] = []
	for id in _map_data.visited:
		if not _map_data.spaces.has(id): continue
		var piece := _clip_segment(start, finish, _map_data.spaces[id].rect.grow(5))
		if piece.size() != 2: continue
		var a := (piece[0] - start).dot(delta) / delta.length_squared()
		var b := (piece[1] - start).dot(delta) / delta.length_squared()
		intervals.append(Vector2(minf(a,b), maxf(a,b)))
	intervals.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	var joined: Array[Vector2] = []
	for interval in intervals:
		if not joined.is_empty() and interval.x <= joined[-1].y + 0.002:
			joined[-1].y = maxf(joined[-1].y, interval.y)
		else:
			joined.append(interval)
	var result := []
	for interval in joined:
		result.append(PackedVector2Array([start + delta * interval.x, start + delta * interval.y]))
	return result

func _unknown_route_exits() -> Array[Vector2]:
	var result: Array[Vector2] = []
	for segment in _map_source.get("segments", []):
		var start := _source_point(segment.get("start", []))
		var finish := _source_point(segment.get("end", []))
		var direction := (finish - start).normalized()
		if direction == Vector2.ZERO: continue
		for piece in _visible_route_pieces(start, finish, str(segment.get("id", ""))):
			for point in [piece[0], piece[1]]:
				if point.distance_to(start) < 12 or point.distance_to(finish) < 12: continue
				var outside: Vector2 = point + direction * (-24 if point == piece[0] else 24)
				if _known_point(outside): continue
				var hidden := false
				for id in _map_data.spaces:
					if id in _map_data.visited: continue
					if _map_data.spaces[id].rect.has_point(outside): hidden = true; break
				if not hidden: continue
				var duplicate := false
				for old in result:
					if old.distance_to(point) < 70: duplicate = true; break
				if not duplicate: result.append(point)
	return result

func _map_shortcut_marks() -> Array:
	var marks := []
	for index in _map_data.get("shortcuts", []).size():
		var shortcut: Dictionary = _map_data.shortcuts[index]
		var gate: String = shortcut.gate_id
		for side in ["from", "to"]:
			if not shortcut.get(side + "_space", "") in _map_data.visited: continue
			marks.append({"gate_id": gate, "label": char(65 + index), "position": shortcut[side], "opened": bool(_map_data.gates.get(gate, false))})
	return marks

func _draw_shortcut_links(offset: Vector2) -> void:
	# Dotted arcs mean an unlocked freight transfer, never a walkable passage.
	for shortcut in _map_data.get("shortcuts", []):
		if not bool(_map_data.gates.get(shortcut.gate_id, false)): continue
		if not shortcut.from_space in _map_data.visited or not shortcut.to_space in _map_data.visited: continue
		var from_point: Vector2 = shortcut.from * _map_zoom + offset
		var to_point: Vector2 = shortcut.to * _map_zoom + offset
		if from_point.distance_to(to_point) > 340: continue # The return loop is paired by letter instead.
		var control := (from_point + to_point) * 0.5 + Vector2(0, -minf(55, from_point.distance_to(to_point) * 0.28))
		var dots := maxi(5, roundi(from_point.distance_to(to_point) / 8.0))
		for i in range(1, dots):
			var t := float(i) / dots
			var at: Vector2 = from_point * ((1.0-t)*(1.0-t)) + control * (2.0*t*(1.0-t)) + to_point * (t*t)
			if _map_view().has_point(at): _map.draw_circle(at, 1.25, Color("c18f7d", 0.60), true)

func _map_gate_world_points() -> Dictionary:
	var locations := {}
	for id in _map_data.get("gate_platforms", {}):
		var gate: PaperPlatform = _map_data.gate_platforms[id]
		var centre := gate.position + Vector2(gate.width, gate.collision_depth) * 0.5
		var best := INF
		for segment in _map_source.get("segments", []):
			if segment.get("kind", "") != "floor": continue
			var start := _source_point(segment.get("start", []))
			var finish := _source_point(segment.get("end", []))
			var at := Vector2(clampf(centre.x, minf(start.x,finish.x), maxf(start.x,finish.x)), start.y)
			if absf(at.x - centre.x) > gate.width * 0.5 + 20: continue
			if at.y < gate.position.y - 24 or at.y > gate.position.y + gate.collision_depth + 24: continue
			var score := at.distance_squared_to(centre)
			if score < best:
				best = score
				locations[id] = at
	return locations

func _clip_segment(start: Vector2, finish: Vector2, rect: Rect2) -> PackedVector2Array:
	# Clip authored floor/stair data to each known region before drawing; hidden routes stay hidden.
	var delta := finish - start
	var low := 0.0
	var high := 1.0
	var p := [-delta.x, delta.x, -delta.y, delta.y]
	var q := [start.x - rect.position.x, rect.end.x - start.x, start.y - rect.position.y, rect.end.y - start.y]
	for side in 4:
		if is_zero_approx(p[side]):
			if q[side] < 0: return PackedVector2Array()
		else:
			var t: float = q[side] / p[side]
			if p[side] < 0: low = maxf(low, t)
			else: high = minf(high, t)
			if low > high: return PackedVector2Array()
	return PackedVector2Array([start + delta * low, start + delta * high])

func _known_point(point: Vector2) -> bool:
	for id in _map_data.visited:
		if _map_data.spaces.has(id) and _map_data.spaces[id].rect.grow(6).has_point(point): return true
	return false

func _map_number_rects(factor: Vector2, offset: Vector2) -> Dictionary:
	# Numbers are native text on generated markers; only visible room centers get markers.
	var occupied: Array[Rect2] = [Rect2(_map_data.player * factor + offset - Vector2(18,18),Vector2(36,36))]
	for checkpoint in _map_data.checkpoints:
		var point: Vector2 = checkpoint if checkpoint is Vector2 else checkpoint.get("position",Vector2.ZERO)
		if _known_point(point): occupied.append(Rect2(point * factor + offset - Vector2(16,16),Vector2(32,32)))
	var result := {}
	for id in _map_data.visited:
		if not _map_data.spaces.has(id): continue
		var world := _map_anchor(str(id))
		var center: Vector2 = world * factor + offset + Vector2(0, -20)
		if not _map_view().grow(-16).has_point(center): continue
		var extent := Vector2(29, 27)
		var candidate := Rect2(center - extent * 0.5, extent)
		var best_score := INF
		for y in range(-8,9):
			for x in range(-8,9):
				var trial := Rect2(center - extent * 0.5 + Vector2(x * 12,y * 12),extent)
				if not Rect2(Vector2.ZERO,_map.size).encloses(trial): continue
				var overlaps := false
				for other in occupied:
					if trial.grow(2).intersects(other): overlaps = true; break
				if overlaps: continue
				var score := trial.get_center().distance_squared_to(center)
				if score < best_score:
					best_score = score
					candidate = trial
		if best_score == INF: continue
		result[id] = candidate
		occupied.append(candidate)
	return result

func _unhandled_key_input(event: InputEvent) -> void:
	if not is_panel_open() or not event is InputEventKey or not event.pressed: return
	if event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		close_requested.emit()
	elif panel_kind == "map":
		var action := ""
		match event.keycode:
			KEY_PLUS, KEY_EQUAL, KEY_KP_ADD: action = "zoom_in"
			KEY_MINUS, KEY_KP_SUBTRACT: action = "zoom_out"
			KEY_HOME: action = "player"
			KEY_F: action = "full"
		if not action.is_empty():
			_map_action(action)
			get_viewport().set_input_as_handled()
