class_name CampaignUI
extends Control

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
var _entries: Array = []
var _category := "tasks"
var _map: Control
var _map_data: Dictionary = {}
var _map_selected := ""
var _font_multiplier := 1.0
var _tracker_art: Panel
var _art: Dictionary = {}
var _map_source: Dictionary = {}
var _map_zoom := 0.14
var _map_pan := Vector2.ZERO
var _map_focus := Vector2.ZERO
var _map_dragging := false
var _map_full := false

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
		theme.set_stylebox(state, "Button", _style("button_" + state, 22, 14, 24, 14, 27, 9, 27, 9, state != "focus"))
	theme.set_color("font_disabled_color", "Button", Color("ada3a6"))
	theme.set_color("font_hover_color", "Button", Color("2c1c20"))
	var map_file := FileAccess.open(MAP_SOURCE, FileAccess.READ)
	if map_file != null:
		var decoded: Variant = JSON.parse_string(map_file.get_as_text())
		if decoded is Dictionary: _map_source = decoded
	tracker = VBoxContainer.new()
	tracker.position = Vector2(905, 76)
	tracker.size = Vector2(272, 206)
	tracker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tracker.add_theme_constant_override("separation", 8)
	add_child(tracker)
	_tracker_art = Panel.new()
	_tracker_art.position = Vector2(818, 23)
	_tracker_art.size = Vector2(412, 250)
	_tracker_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tracker_art.add_theme_stylebox_override("panel", _style("tracker_frame", 86, 37, 37, 35, 0, 0, 0, 0))
	add_child(_tracker_art)
	move_child(_tracker_art, 0)
	_main = _label("", 23)
	tracker.add_child(_main)
	_side = _label("", 21)
	tracker.add_child(_side)
	panel = PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.mouse_force_pass_scroll_events = false
	panel.add_theme_stylebox_override("panel", _style("journal_frame", 100, 62, 100, 62, 104, 61, 104, 54))
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
		var lowest := tracker.position.y
		for child in tracker.get_children():
			if child.visible: lowest = maxf(lowest, tracker.position.y + child.position.y + child.size.y)
		# The authored tracker has transparent guards above and below its visible border.
		_tracker_art.size.y = maxf(250, lowest - _tracker_art.position.y + 58)

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
	_main.text = COPY.main + "\n" + main_text if not main_text.is_empty() else ""
	_side.text = COPY.side + "\n" + side_text if not side_text.is_empty() else ""
	_side.visible = not side_text.is_empty()
	_fit_tracker.call_deferred()

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
	panel.position = Vector2(120, 38) if kind != "dialogue" else Vector2(170, 355)
	panel.size = Vector2(1040, 644) if kind != "dialogue" else Vector2(940, 325)
	panel.add_theme_stylebox_override("panel", _style("dialogue_frame", 62, 42, 62, 42, 82, 43, 82, 42) if kind == "dialogue" else _style("journal_frame", 100, 62, 100, 62, 104, 61, 104, 54))
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
		action.custom_minimum_size.y = 38
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
	var legend_scroll := ScrollContainer.new()
	legend_scroll.custom_minimum_size.x = 232
	legend_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	row.add_child(legend_scroll)
	var legend := VBoxContainer.new()
	legend.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	legend.add_theme_constant_override("separation", 6)
	legend_scroll.add_child(legend)
	for id in visited:
		if not spaces.has(id): continue
		var button := Button.new()
		button.text = "%02d  %s" % [visited.find(id) + 1, str(spaces[id].get("title",id))]
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = 45
		for state in ["normal", "hover", "pressed", "focus", "disabled"]:
			button.add_theme_stylebox_override(state, _style("button_" + state, 22, 14, 22, 14, 17, 9, 17, 9, state != "focus"))
		button.pressed.connect(func():
			_map_selected = str(id)
			_map_focus = spaces[id].rect.get_center()
			_map_pan = Vector2.ZERO
			_map_zoom = _local_map_zoom()
			_map_full = false
			_map.queue_redraw())
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

func _draw_map() -> void:
	if _map_data.is_empty() or _map.size.x < 10: return
	var parchment := _texture("map_parchment")
	if parchment != null:
		_map.draw_texture_rect(parchment, Rect2(Vector2.ZERO, _map.size), false, Color(0.85, 0.79, 0.72, 0.90))
	var offset := _map_offset()
	var factor := Vector2.ONE * _map_zoom
	var spaces: Dictionary = _map_data.spaces
	var visited: Array = _map_data.visited
	var strip := AtlasTexture.new()
	strip.atlas = _texture("map_route")
	strip.region = Rect2(82, 29, 280, 20)
	for segment in _map_source.get("segments", []):
		var start := _source_point(segment.get("start", []))
		var end := _source_point(segment.get("end", []))
		for id in visited:
			if not spaces.has(id): continue
			var piece := _clip_segment(start, end, spaces[id].rect.grow(5))
			if piece.size() == 2:
				_draw_route(piece[0] * _map_zoom + offset, piece[1] * _map_zoom + offset, strip, bool(segment.get("one_way", false)))
	var landmark_size := clampf(_map_zoom * 750.0, 62.0, 108.0)
	var marker_size := clampf(_map_zoom * 155.0, 11.0, 25.0)
	for landmark in _map_source.get("landmarks", []):
		if not landmark.get("space_id", "") in visited: continue
		var at := _source_point(landmark.get("position", [])) * _map_zoom + offset
		if _map_view().grow(80).has_point(at):
			_draw_icon(str(landmark.get("art", "")), at - Vector2(0, landmark_size * 0.33), Vector2.ONE * landmark_size, Color(1, 1, 1, 0.83))
	for connection in _map_data.connections:
		var a: String = str(connection.get("from", ""))
		var b: String = str(connection.get("to", ""))
		if not spaces.has(a) or not spaces.has(b): continue
		var known_a := a in visited
		var known_b := b in visited
		if not known_a and not known_b: continue
		var from_point: Vector2 = spaces[a].rect.get_center()
		var to_point: Vector2 = spaces[b].rect.get_center()
		if known_a != known_b:
			var known: String = a if known_a else b
			var hidden: String = b if known_a else a
			var toward: Vector2 = (spaces[hidden].rect.get_center() - spaces[known].rect.get_center()).normalized()
			var entrance: Vector2 = _edge(spaces[known].rect, toward) * _map_zoom + offset
			_draw_icon("map_unknown", entrance, Vector2.ONE * marker_size)
			continue
		var gate: String = str(connection.get("gate_id", ""))
		if gate.is_empty(): continue
		var between := (from_point + to_point) * 0.5 * _map_zoom + offset
		_draw_icon("map_open" if bool(_map_data.gates.get(gate, false)) else "map_lock", between, Vector2.ONE * marker_size)
	for checkpoint in _map_data.checkpoints:
		var point: Vector2 = checkpoint if checkpoint is Vector2 else checkpoint.get("position", Vector2.ZERO)
		if _known_point(point): _draw_icon("map_checkpoint", point * _map_zoom + offset, Vector2.ONE * marker_size)
	var numbers := _map_number_rects(factor, offset)
	for id in numbers:
		if _map_zoom < 0.06 and str(id) != _map_selected: continue
		var rect: Rect2 = numbers[id]
		_draw_icon("map_selection", rect.get_center(), Vector2(30, 30), Color(1, 1, 1, 0.9 if str(id) == _map_selected else 0.65))
		var number := "%02d" % (visited.find(id) + 1)
		_map.draw_string(ThemeDB.fallback_font, rect.position + Vector2(2, 19), number, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, INK)
	_draw_icon("map_player", _map_data.player * _map_zoom + offset, Vector2.ONE * maxf(18.0, marker_size * 1.2))

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

func _draw_route(start: Vector2, finish: Vector2, strip: Texture2D, one_way: bool) -> void:
	var length := start.distance_to(finish)
	if length < 2: return
	# The generated engraved strip is widened into the actual stone deck or metal stair footprint.
	# Both passes use authored art; no speculative room-to-room connectors are painted.
	var width := clampf(_map_zoom * (112.0 if one_way else 168.0), 5.0, 24.0)
	_map.draw_set_transform(start, (finish - start).angle())
	_map.draw_texture_rect(strip, Rect2(0, -width * 0.5, length, width), false, Color("7d645e") if one_way else Color("aa9080"))
	_map.draw_texture_rect(strip, Rect2(0, -width * 0.22, length, width * 0.44), false, Color("d8ba9f") if one_way else Color("fff0ca"))
	_map.draw_set_transform(Vector2.ZERO)

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
		var center: Vector2 = _map_data.spaces[id].rect.get_center() * factor + offset
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

func _edge(rect: Rect2, direction: Vector2) -> Vector2:
	var distance := minf(rect.size.x * 0.5 / maxf(absf(direction.x), 0.001), rect.size.y * 0.5 / maxf(absf(direction.y), 0.001))
	return rect.get_center() + direction * distance

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
