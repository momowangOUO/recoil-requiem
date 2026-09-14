class_name CampaignUI
extends Control

signal close_requested
signal choice_selected(id: String)
signal side_selected(id: String)

const STATUS_COPY := {"track":"追踪", "tracked":"正在追踪", "complete":"已完成", "active":"进行中"}

const COPY := {"main":"当前目标", "side":"支线", "journal":"日志", "map":"地图", "tasks":"任务", "clues":"线索", "people":"人物", "consequences":"后果", "empty":"暂无记录。", "close":"关闭 · Esc", "keys":"J 日志　M 地图", "map_legend":"● 当前位置　◇ 检查点　× 锁闭　— 已开通", "unknown":"未探索入口"}
const INK := Color("eee4d2")
const SILVER := Color("b4b1b8")
var panel_kind := ""
var tracker: VBoxContainer
var panel: PanelContainer
var content: VBoxContainer
var _main: Label
var _side: Label
var _entries: Array = []
var _category := "tasks"
var _atlas: Texture2D
var _map: Control
var _map_data: Dictionary = {}
var _map_selected := ""
var _font_multiplier := 1.0
var _tracker_art: Panel

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
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("54333d") if state in ["hover", "pressed"] else Color("292630")
		if state == "disabled": style.bg_color = Color("34313a")
		style.border_color = SILVER
		style.set_border_width_all(2)
		style.content_margin_left = 14
		style.content_margin_right = 14
		style.content_margin_top = 8
		style.content_margin_bottom = 8
		style.set_corner_radius_all(3)
		if state == "focus":
			style.draw_center = false
			style.border_color = INK
		theme.set_stylebox(state, "Button", style)
	theme.set_color("font_disabled_color", "Button", Color("ada3a6"))
	theme.set_color("font_hover_color", "Button", Color("fff2db"))
	if ResourceLoader.exists("res://assets/ui/campaign/campaign_atlas.png"):
		_atlas = load("res://assets/ui/campaign/campaign_atlas.png")
	else:
		# Development fixture before the editor's asset-import pass.
		var atlas_image := Image.load_from_file("res://assets/ui/campaign/campaign_atlas.png")
		if atlas_image != null and not atlas_image.is_empty():
			_atlas = ImageTexture.create_from_image(atlas_image)
	tracker = VBoxContainer.new()
	tracker.position = Vector2(854, 36)
	tracker.size = Vector2(374, 180)
	tracker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tracker.add_theme_constant_override("separation", 8)
	add_child(tracker)
	_tracker_art = Panel.new()
	_tracker_art.position = Vector2(824, 22)
	_tracker_art.size = Vector2(422, 188)
	_tracker_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tracker_surface := StyleBoxFlat.new()
	tracker_surface.bg_color = Color(0.19, 0.13, 0.16, 0.96)
	tracker_surface.border_color = Color("8e7277")
	tracker_surface.border_width_left = 3
	tracker_surface.corner_radius_top_left = 3
	tracker_surface.corner_radius_bottom_left = 3
	_tracker_art.add_theme_stylebox_override("panel", tracker_surface)
	add_child(_tracker_art)
	move_child(_tracker_art, 0)
	_main = _label("", 26)
	tracker.add_child(_main)
	_side = _label("", 24)
	tracker.add_child(_side)
	tracker.add_child(_label(COPY.keys, 24, SILVER))
	panel = PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.mouse_force_pass_scroll_events = false
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.19, 0.16, 0.20, 0.98)
	bg.border_color = SILVER
	bg.set_border_width_all(1)
	bg.set_content_margin_all(36)
	bg.set_corner_radius_all(5)
	bg.border_color = Color("8e7277")
	panel.add_theme_stylebox_override("panel", bg)
	add_child(panel)
	panel.hide()
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	panel.add_child(content)
	get_window().size_changed.connect(_adapt_type)
	tracker.minimum_size_changed.connect(func(): _fit_tracker.call_deferred())
	_adapt_type()

func _fit_tracker() -> void:
	if _tracker_art:
		_tracker_art.size.y = maxf(188,tracker.get_combined_minimum_size().y + 40)

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
	_main.text = COPY.main + "\n" + main_text if not main_text.is_empty() else ""
	_side.text = COPY.side + "\n" + side_text if not side_text.is_empty() else ""
	_side.visible = not side_text.is_empty()

func is_panel_open() -> bool:
	return not panel_kind.is_empty()

func close_panel() -> void:
	panel_kind = ""
	panel.hide()
	tracker.show()
	if _tracker_art: _tracker_art.show()

func _open(kind: String, title: String) -> void:
	panel_kind = kind
	tracker.visible = kind == "dialogue"
	if _tracker_art: _tracker_art.visible = tracker.visible
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	panel.position = Vector2(272, 94) if kind != "dialogue" else Vector2(290, 368)
	panel.size = Vector2(920, 550) if kind != "dialogue" else Vector2(900, 310)
	var header := HBoxContainer.new()
	content.add_child(header)
	var heading := _label(title, 30)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	var close := Button.new()
	close.text = COPY.close
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

func show_dialogue(speaker: String, lines: Array, choices: Array) -> void:
	_open("dialogue", speaker)
	var body := _scroll()
	for line in lines:
		body.add_child(_label(str(line)))
	for choice in choices:
		var button := Button.new()
		button.text = str(choice.get("text", ""))
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = 46
		var id := str(choice.get("id", ""))
		button.pressed.connect(func(): choice_selected.emit(id))
		body.add_child(button)

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

func show_map(spaces: Dictionary, connections: Array, visited: Array, gate_states: Dictionary, player_position: Vector2, checkpoints: Array) -> void:
	_open("map", COPY.map)
	_map_data = {"spaces":spaces, "connections":connections, "visited":visited, "gates":gate_states, "player":player_position, "checkpoints":checkpoints}
	_map_selected = ""
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 16)
	content.add_child(row)
	_map = Control.new()
	_map.custom_minimum_size = Vector2(0, 300)
	_map.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_map.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_map.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map.clip_contents = true
	row.add_child(_map)
	_map.draw.connect(_draw_map)
	_map.resized.connect(func(): _map.queue_redraw())
	var legend_scroll := ScrollContainer.new()
	legend_scroll.custom_minimum_size.x = 276
	legend_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	row.add_child(legend_scroll)
	var legend := VBoxContainer.new()
	legend.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	legend.add_theme_constant_override("separation", 8)
	legend_scroll.add_child(legend)
	for id in visited:
		if not spaces.has(id): continue
		var button := Button.new()
		button.text = "%02d  %s" % [visited.find(id) + 1, str(spaces[id].get("title",id))]
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(func():
			_map_selected = str(id)
			_map.queue_redraw())
		legend.add_child(button)
	content.add_child(_label(COPY.map_legend, 24, SILVER))

func _draw_map() -> void:
	var spaces: Dictionary = _map_data.spaces
	var visited: Array = _map_data.visited
	var bounds := Rect2()
	var first := true
	for id in visited:
		if not spaces.has(id): continue
		var rect: Rect2 = spaces[id].rect
		bounds = rect if first else bounds.merge(rect)
		first = false
	if first: return
	# This is a room/connectivity diagram, not a distance-measuring overlay.
	# Independent axes keep the three floors legible across the long monastery.
	var factor := Vector2((_map.size.x - 90) / maxf(bounds.size.x, 1), (_map.size.y - 70) / maxf(bounds.size.y, 1))
	var offset := (_map.size - bounds.size * factor) * 0.5 - bounds.position * factor
	for id in visited:
		if not spaces.has(id): continue
		var source: Rect2 = spaces[id].rect
		var rect := Rect2(source.position * factor + offset, source.size * factor)
		var selected := str(id) == _map_selected
		_map.draw_rect(rect, Color("75404b") if selected else Color("493039"))
		_map.draw_rect(rect, INK if selected else SILVER, false, 3 if selected else 2)
	for connection in _map_data.connections:
		var a = connection.get("from", "")
		var b = connection.get("to", "")
		if not spaces.has(a) or not spaces.has(b): continue
		if not a in visited and not b in visited: continue
		var start: Vector2 = spaces[a].rect.get_center() * factor + offset
		var end: Vector2 = spaces[b].rect.get_center() * factor + offset
		var a_rect := Rect2(spaces[a].rect.position * factor + offset, spaces[a].rect.size * factor)
		var b_rect := Rect2(spaces[b].rect.position * factor + offset, spaces[b].rect.size * factor)
		var direction := (end - start).normalized()
		start = _edge(a_rect, direction)
		end = _edge(b_rect, -direction)
		if not a in visited:
			start = end - direction * 30
		if not b in visited:
			end = start + direction * 30
		var gate: String = str(connection.get("gate_id", ""))
		var opened := gate.is_empty() or bool(_map_data.gates.get(gate, false))
		if start.distance_to(end) < 16:
			var center := (start + end) * 0.5
			start = center - direction * 8
			end = center + direction * 8
		_map.draw_line(start, end, SILVER if opened else Color("ca6471"), 3)
		if not opened:
			var middle := (start + end) * 0.5
			_map.draw_line(middle - Vector2(5, 5), middle + Vector2(5, 5), Color("ca6471"), 3)
			_map.draw_line(middle - Vector2(5, -5), middle + Vector2(5, -5), Color("ca6471"), 3)
	for id in visited:
		if not spaces.has(id): continue
		var source: Rect2 = spaces[id].rect
		var rect := Rect2(source.position * factor + offset, source.size * factor)
		var number := "%02d" % (visited.find(id) + 1)
		var font_size := roundi(24 * _font_multiplier)
		var text_size := ThemeDB.fallback_font.get_string_size(number,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size)
		var position := rect.get_center() + Vector2(-text_size.x * 0.5, font_size * 0.32)
		_map.draw_rect(Rect2(position + Vector2(-2,-font_size),text_size + Vector2(4,2)),Color("302330"))
		_map.draw_string(ThemeDB.fallback_font,position,number,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,INK)
	for checkpoint in _map_data.checkpoints:
		var point := Vector2.ZERO
		if checkpoint is Vector2:
			point = checkpoint
		elif checkpoint is Dictionary:
			point = checkpoint.get("position", Vector2.ZERO)
		else: continue
		var known := false
		for id in visited:
			if spaces.has(id) and spaces[id].rect.has_point(point): known = true
		if known:
			var at := point * factor + offset
			_map.draw_polyline(PackedVector2Array([at + Vector2(0,-7), at + Vector2(7,0), at + Vector2(0,7), at + Vector2(-7,0), at + Vector2(0,-7)]), INK, 2)
	_map.draw_circle(_map_data.player * factor + offset, 6, Color("e5ba89"))

func _edge(rect: Rect2, direction: Vector2) -> Vector2:
	var distance := minf(rect.size.x * 0.5 / maxf(absf(direction.x), 0.001), rect.size.y * 0.5 / maxf(absf(direction.y), 0.001))
	return rect.get_center() + direction * distance

func _unhandled_key_input(event: InputEvent) -> void:
	if is_panel_open() and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		close_requested.emit()
