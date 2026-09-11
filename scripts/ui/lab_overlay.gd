class_name LabOverlay
extends CanvasLayer
## Compact, pause-safe runtime configuration editor. All changes use deep copies.

signal resume_requested()
signal apply_requested(config: Dictionary)
signal baseline_requested()
signal responsive_requested()
signal preset_requested(index: int)
signal reset_requested()

const BONE := Color("e8e5d9")
const MUTED := Color("8c969e")
const RED := Color("ed675d")
const CYAN := Color("6cddd3")
const INK := Color("111820")
const PLAYER_FIELDS := [
	["gravity", "Gravity", 100.0, 4000.0, 25.0, 1500.0],
	["jump_impulse", "Jump impulse", 100.0, 900.0, 10.0, 460.0],
	["walk_max_speed", "Walk speed", 10.0, 500.0, 5.0, 150.0],
	["ground_acceleration", "Ground accel", 100.0, 5000.0, 50.0, 1400.0],
	["ground_deceleration", "Ground brake", 100.0, 5000.0, 50.0, 1800.0],
	["air_control_x", "Air control X", 0.0, 1500.0, 10.0, 380.0],
	["air_control_y", "Air control Y", 0.0, 3900.0, 10.0, 180.0],
	["air_max_speed", "Air input speed", 50.0, 900.0, 10.0, 220.0],
	["air_deceleration", "Air release brake", 0.0, 1200.0, 10.0, 180.0],
	["ground_recoil_scale", "Ground kick X", 0.0, 1.0, 0.05, 0.45],
	["horizontal_recoil_scale", "Horizontal kick", 0.0, 2.0, 0.05, 1.0],
	["air_lift_speed", "Air lift ceiling (0=GDD)", 0.0, 1200.0, 10.0, 0.0],
	["terminal_velocity", "Fall terminal", 100.0, 2000.0, 25.0, 900.0],
	["soft_cap_x", "Soft cap X", 100.0, 2000.0, 25.0, 760.0],
	["soft_cap_y", "Soft cap Y", 100.0, 2000.0, 25.0, 900.0],
	["overspeed_drag_x", "Overcap drag X", 10.0, 4000.0, 25.0, 900.0],
	["overspeed_drag_y", "Overcap drag Y", 10.0, 4000.0, 25.0, 700.0],
]

var _config: Dictionary = {}
var _fields: Dictionary = {}
var _weapon_fields: Array[Dictionary] = []
var _toggles: Dictionary = {}
var _root: Control
var _panel: Control
var _title: Label
var _health: Label
var _speed: Label
var _weapon: Label
var _inventory_slots: Array[Label] = []
var _hit: Label
var _notice: Label
var _reload: ProgressBar
var _reload_status: Label
var _hp_cells: Array[ColorRect] = []
var _ammo_cells: Array[ColorRect] = []
var _turn_speed: SpinBox
var _notice_timer := 0.0
var _story: Control
var _story_title: Label
var _story_body: Label
var _story_scroll: ScrollContainer

func hide_story() -> void:
	if is_instance_valid(_story): _story.hide()

func show_story(title: String, content: String) -> void:
	_build()
	if combat != null: combat.suspend(true)
	_story_title.text = title
	_story_body.text = content
	_story_scroll.scroll_vertical = 0
	_notice.hide()
	_story.show()
var _built := false
var lab_navigation := true
var combat: CombatHud

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 30
	_build()

func setup(config: Dictionary) -> void:
	_build()
	_config = config.duplicate(true)
	_load_form()
	hide_panel()

func show_panel(config: Dictionary) -> void:
	_build()
	_config = config.duplicate(true)
	_load_form()
	_panel.show()
	if combat != null: combat.suspend(true)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.find_child("Resume", true, false).grab_focus()

func hide_panel() -> void:
	if not _built:
		return
	_panel.hide()
	if combat != null: combat.suspend(false)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var focused := get_viewport().gui_get_focus_owner()
	if focused != null:
		focused.release_focus()

func update_hud(metrics: Dictionary) -> void:
	_build()
	if combat != null:
		combat.sync(metrics)
		return
	var velocity: Vector2 = metrics.get("velocity", Vector2.ZERO)
	_title.text = "R/R  |  %02d  %s" % [int(metrics.get("preset", 0)) + 1, str(metrics.get("title", "RECOIL LAB")).to_upper()]
	_health.text = "HP"
	for i in _hp_cells.size():
		_hp_cells[i].color = RED if i < int(metrics.get("health", 5)) else Color("354350")
	_speed.text = "VX %+04d  VY %+04d  RISE %.1f" % [roundi(velocity.x), roundi(velocity.y), float(metrics.get("height", 0))]
	_speed.visible = bool(metrics.get("measurement", true))
	var short_names := {"revolver": "REVOLVER", "shotgun": "SHOTGUN", "smg": "SMG"}
	_weapon.text = "[%d] %s  %02d/%02d" % [int(metrics.get("active_slot", 0)) + 1, short_names.get(str(metrics.get("weapon_id", "revolver")), "REVOLVER"), int(metrics.get("ammo", 6)), int(metrics.get("magazine", 6))]
	var inventory: Array = metrics.get("inventory", [])
	var abbreviations := {"revolver": "R", "shotgun": "S", "smg": "M"}
	var active := int(metrics.get("active_slot", 0))
	for i in _inventory_slots.size():
		var item: Dictionary = inventory[i] if i < inventory.size() else {"occupied": false}
		var occupied := bool(item.get("occupied", false))
		var mark := str(abbreviations.get(str(item.get("id", "")), "?")) if occupied else "-"
		_inventory_slots[i].text = "[%d%s]" % [i + 1, mark] if i == active else " %d%s " % [i + 1, mark]
		_inventory_slots[i].add_theme_color_override("font_color", CYAN if i == active else (BONE if occupied else Color("53606a")))
	_hit.text = str(metrics.get("last_hit", ""))
	var progress := float(metrics.get("reload_progress", -1))
	_reload.visible = progress >= 0
	_reload.value = clampf(progress, 0, 1)
	var tint := ReloadFeedback.progress_color(progress)
	_reload.add_theme_stylebox_override("fill", _style(tint))
	_reload_status.text = ("SHELL " if metrics.get("per_shell", false) else "RELOAD ") + "%d%%" % roundi(progress * 100) if progress >= 0 else "READY / AMMO UNLIMITED"
	_reload_status.add_theme_color_override("font_color", tint if progress >= 0 else MUTED)
	for i in _ammo_cells.size():
		_ammo_cells[i].visible = i < int(metrics.get("magazine", 6))
		_ammo_cells[i].color = CYAN if i < int(metrics.get("ammo", 6)) else Color("354350")

func show_notice(message: String) -> void:
	_build()
	if combat != null:
		combat.notify(message)
		return
	_notice.text = message
	_notice_timer = 3.5
	_notice.show()

func _process(delta: float) -> void:
	if _notice_timer > 0:
		_notice_timer -= delta
		if _notice_timer <= 0:
			_notice.hide()

func _style(color: Color, border: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1 if border.a > 0 else 0)
	style.set_content_margin_all(2)
	return style

func _theme() -> Theme:
	var result := Theme.new()
	result.default_font_size = 8
	result.set_color("font_color", "Label", BONE)
	result.set_color("font_color", "Button", BONE)
	result.set_color("font_hover_color", "Button", CYAN)
	for kind in ["Button", "OptionButton"]:
		result.set_stylebox("normal", kind, _style(Color("26303b")))
		result.set_stylebox("hover", kind, _style(Color("33444d"), CYAN))
		result.set_stylebox("pressed", kind, _style(Color("41575d"), CYAN))
		result.set_stylebox("focus", kind, _style(Color.TRANSPARENT, CYAN))
	result.set_stylebox("normal", "LineEdit", _style(Color("0d1219"), Color("34424f")))
	result.set_color("font_color", "LineEdit", CYAN)
	result.set_constant("minimum_character_width", "SpinBox", 4)
	result.set_stylebox("panel", "TabContainer", _style(INK))
	result.set_stylebox("tab_selected", "TabContainer", _style(Color("304048")))
	result.set_stylebox("tab_unselected", "TabContainer", _style(Color("19222c")))
	result.set_color("font_selected_color", "TabContainer", CYAN)
	result.set_color("font_unselected_color", "TabContainer", MUTED)
	result.set_font_size("font_size", "TabContainer", 8)
	result.set_stylebox("background", "ProgressBar", _style(Color("26303b")))
	result.set_stylebox("fill", "ProgressBar", _style(CYAN))
	return result

func _label(parent: Node, value: String, color: Color = BONE) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _place(control: Control, rect: Rect2) -> void:
	control.position = rect.position
	control.size = rect.size

func _button(parent: Node, title: String, action: Callable, node_name: String = "") -> Button:
	var button := Button.new()
	button.text = title
	if not node_name.is_empty():
		button.name = node_name
	button.pressed.connect(action)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(button)
	return button

func _build() -> void:
	if _built:
		return
	_built = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.name = "LabInterface"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = _theme()
	add_child(_root)
	for rect in [Rect2(0, 0, 320, 26 if lab_navigation else 18), Rect2(0, 145, 320, 35)]:
		var plate := ColorRect.new()
		plate.color = Color(0.035, 0.055, 0.08, 0.93)
		plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_root.add_child(plate)
		_place(plate, rect)
	_title = _label(_root, "R/R  |  01 RECOIL LAB", BONE)
	_place(_title, Rect2(6, 3, 256, 11))
	_health = _label(_root, "HP 5/5", RED)
	_place(_health, Rect2(258, 3, 16, 11))
	for i in 5:
		var cell := ColorRect.new()
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_root.add_child(cell)
		_place(cell, Rect2(277 + i * 7, 7, 5, 5))
		_hp_cells.append(cell)
	_speed = _label(_root, "", CYAN)
	_place(_speed, Rect2(6, 14, 260, 11))
	_weapon = _label(_root, "", BONE)
	_weapon.name = "CurrentWeapon"
	_place(_weapon, Rect2(6, 146, 144, 11))
	for i in WeaponController.SLOT_COUNT:
		var slot := _label(_root, " %d- " % (i + 1), Color("53606a"))
		slot.name = "WeaponSlot%d" % (i + 1)
		slot.add_theme_font_size_override("font_size", 7)
		slot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_place(slot, Rect2(151 + i * 27, 146, 27, 10))
		_inventory_slots.append(slot)
	_reload = ProgressBar.new()
	_reload.max_value = 1
	_reload.show_percentage = false
	_reload.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_reload)
	_place(_reload, Rect2(6, 166, 110, 2))
	_reload.hide()
	_reload_status = _label(_root, "READY", MUTED)
	_reload_status.name = "ReloadStatus"
	_reload_status.add_theme_font_size_override("font_size", 7)
	_place(_reload_status, Rect2(6, 157, 140, 9))
	for i in 24:
		var cell := ColorRect.new()
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_root.add_child(cell)
		_place(cell, Rect2(160 + i * 6, 166, 4, 3))
		_ammo_cells.append(cell)
	_hit = _label(_root, "", RED)
	_place(_hit, Rect2(6, 137 if lab_navigation else 19, 300, 11))
	var hint := _label(_root, "WASD / SPACE / LMB / 1-6 guns / E use / J notes / M route / TAB", MUTED)
	_place(hint, Rect2(6, 170, 308, 10))
	hint.add_theme_font_size_override("font_size", 7)
	_notice = _label(_root, "", CYAN)
	_notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(_notice, Rect2(10, 28, 300, 13))
	_notice.hide()
	_story = Control.new()
	if not lab_navigation:
		for child in _root.get_children():
			if child is CanvasItem: child.hide()
		combat = CombatHud.new()
		combat.name = "CombatHud"
		_root.add_child(combat)
	_story.name = "StoryCard"
	_story.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_story)
	var story_back := Panel.new()
	story_back.add_theme_stylebox_override("panel", _style(Color("111820"), Color("84705a")))
	_story.add_child(story_back)
	_place(story_back, Rect2(28, 34, 264, 108))
	_story_title = _label(_story, "", CYAN)
	_place(_story_title, Rect2(40, 43, 240, 14))
	_story_scroll = ScrollContainer.new()
	_story_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_story.add_child(_story_scroll)
	_place(_story_scroll, Rect2(40, 62, 240, 59))
	var scroll_bar := _story_scroll.get_v_scroll_bar()
	scroll_bar.add_theme_stylebox_override("scroll", _style(Color("202c34")))
	scroll_bar.add_theme_stylebox_override("grabber", _style(Color("84705a")))
	scroll_bar.add_theme_stylebox_override("grabber_highlight", _style(CYAN))
	scroll_bar.add_theme_stylebox_override("grabber_pressed", _style(CYAN))
	var blank := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	blank.fill(Color.TRANSPARENT)
	var empty_icon := ImageTexture.create_from_image(blank)
	for icon in ["increment", "decrement", "increment_highlight", "decrement_highlight", "increment_pressed", "decrement_pressed"]:
		scroll_bar.add_theme_icon_override(icon, empty_icon)
	_story_body = _label(_story_scroll, "", BONE)
	_story_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_story_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_story_body.add_theme_font_size_override("font_size", 8)
	var story_hint := _label(_story, "滚轮阅读 · E / ESC 返回 · 世界已暂停", MUTED)
	_place(story_hint, Rect2(40, 127, 240, 10))
	_story.hide()
	_panel = Control.new()
	_panel.name = "TuningPanel"
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(_panel)
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.035, 0.05, 0.93)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.add_child(shade)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", _style(INK, Color("42525c")))
	_panel.add_child(frame)
	_place(frame, Rect2(5, 5, 310, 170))
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 2)
	frame.add_child(layout)
	var heading := HBoxContainer.new()
	layout.add_child(heading)
	var header := _label(heading, "RECOIL LAB / PAUSED" if lab_navigation else "CRIMSON MONASTERY / PAUSED", RED)
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for i in range(3 if lab_navigation else 0):
		_button(heading, "F%d" % (i + 1), func(): preset_requested.emit(i))
	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.custom_minimum_size.y = 110
	layout.add_child(tabs)
	var movement := _tab(tabs, "Movement")
	_label(movement, "Units: px/s, px/s2. Scroll for caps / drag.", MUTED)
	for entry in PLAYER_FIELDS:
		var spin := _number(movement, entry[1], entry[2], entry[3], entry[4])
		spin.name = "Player_" + entry[0]
		_fields[entry[0]] = spin
	var weapons := _tab(tabs, "Weapons")
	_label(weapons, "Impulse is opposite your aim. Scroll for all 3.", MUTED)
	for i in range(3):
		_label(weapons, ["01 / REVOLVER", "02 / SHOTGUN", "03 / SMG"][i], CYAN)
		var fields := {}
		fields["recoil_impulse"] = _number(weapons, "Recoil impulse", 1, 2000, 5)
		fields["fire_rate"] = _number(weapons, "Fire rate / sec", 0.1, 30, 0.01)
		fields["reload_time"] = _number(weapons, "Reload seconds", 0.1, 10, 0.01)
		_weapon_fields.append(fields)
	var trial := _tab(tabs, "Trial")
	_label(trial, "Arsenal: 1 REVOLVER / 2 SHOTGUN / 3 SMG / 4-6 EMPTY", CYAN)
	_label(trial, "1-6 select a slot. Q / wheel cycles occupied slots.", MUTED)
	for item in [["measurement", "Show velocity / rise"], ["shake", "Camera shake"], ["target_mode", "Fixed target (off = live)"]]:
		var checkbox := CheckBox.new()
		checkbox.text = item[1]
		trial.add_child(checkbox)
		_toggles[item[0]] = checkbox
	_toggles["measurement"].toggled.connect(func(_enabled: bool): _sync_measurement_shake())
	_turn_speed = _number(trial, "Target turn deg/sec", 1, 720, 5)
	_label(trial, "Apply restarts the trial. Values are session-only.", MUTED)
	var footer := HBoxContainer.new()
	if combat != null:
		var settings := _tab(tabs, "HUD")
		var sizing := _number(settings, CombatHud.COPY.data.scale, 1.0, 2.0, 0.25)
		sizing.value = 1.0
		sizing.value_changed.connect(func(value: float): combat.ui_scale = value)
		for key in ["contrast", "motion", "toggle", "reverse"]:
			var option := CheckBox.new()
			option.text = CombatHud.COPY.data[key]
			settings.add_child(option)
			var field: String = {"contrast":"high_contrast","motion":"reduced_motion","toggle":"view_toggle","reverse":"reverse_wheel"}[key]
			option.toggled.connect(func(value: bool): combat.set(field,value))
		var input_hint := _label(settings, CombatHud.COPY.data.hint, MUTED)
		input_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	footer.add_theme_constant_override("separation", 3)
	layout.add_child(footer)
	_button(footer, "Resume", func(): resume_requested.emit(), "Resume")
	_button(footer, "Apply", _apply, "Apply")
	_button(footer, "GDD", func(): baseline_requested.emit())
	_button(footer, "Responsive", func(): responsive_requested.emit())
	_button(footer, "Reset", func(): reset_requested.emit())
	_panel.hide()

func _tab(tabs: TabContainer, title: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = title
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	tabs.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 2)
	scroll.add_child(content)
	return content

func _number(parent: Node, caption: String, low: float, high: float, step_value: float) -> SpinBox:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var label := _label(row, caption)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var number := SpinBox.new()
	number.min_value = low
	number.max_value = high
	number.step = step_value
	number.custom_minimum_size.x = 80
	number.get_line_edit().add_theme_font_size_override("font_size", 8)
	row.add_child(number)
	return number

func _load_form() -> void:
	var player: Dictionary = _config.get("player", {})
	for entry in PLAYER_FIELDS:
		_fields[entry[0]].value = player.get(entry[0], entry[5])
	var weapons: Array = _config.get("weapons", [])
	for i in range(_weapon_fields.size()):
		if i >= weapons.size():
			continue
		for key in _weapon_fields[i]:
			_weapon_fields[i][key].value = weapons[i].get(key, 1)
	for key in _toggles:
		_toggles[key].button_pressed = bool(_config.get(key, true))
	_sync_measurement_shake()
	_turn_speed.value = float(_config.get("turn_speed", 110))

func _sync_measurement_shake() -> void:
	var measuring: bool = _toggles["measurement"].button_pressed
	_toggles["shake"].disabled = measuring
	if measuring:
		_toggles["shake"].button_pressed = false

func _apply() -> void:
	# Commit a pending typed SpinBox edit before reading its value.
	var focus := get_viewport().gui_get_focus_owner()
	if focus is LineEdit:
		focus.text_submitted.emit(focus.text)
	var result := _config.duplicate(true)
	if not result.has("player"):
		result["player"] = {}
	for key in _fields:
		result["player"][key] = _fields[key].value
	result["player"]["air_control_y"] = minf(result["player"]["air_control_y"], result["player"]["gravity"] * 0.8)
	var weapons: Array = result.get("weapons", [])
	for i in range(mini(weapons.size(), _weapon_fields.size())):
		for key in _weapon_fields[i]:
			weapons[i][key] = _weapon_fields[i][key].value
	for key in _toggles:
		result[key] = _toggles[key].button_pressed
	if result["measurement"]:
		result["shake"] = false
	result["turn_speed"] = _turn_speed.value
	apply_requested.emit(result)
