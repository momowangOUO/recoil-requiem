extends SceneTree

var failure_count := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failure_count += 1

func _run() -> void:
	if not ResourceLoader.exists("res://scripts/ui/lab_overlay.gd"):
		_check(false, "LabOverlay must exist and expose a working runtime editor")
		quit(1)
		return
	var overlay = load("res://scripts/ui/lab_overlay.gd").new()
	root.size = Vector2i(320, 180)
	root.add_child(overlay)
	var config := {
		"player": {"gravity": 1500.0, "air_control_y": 180.0, "custom_physics": 17},
		"weapons": [
			{"id":"revolver", "display_name":"NIGHTWATCH", "magazine_size":137, "fire_rate":3.0, "recoil_impulse":250.0, "reload_time":1.05, "damage": 30},
			{"id":"shotgun", "display_name":"BREACH", "magazine_size":2, "fire_rate":0.82, "recoil_impulse":720.0, "reload_time":0.62},
			{"id":"smg", "display_name":"STATIC", "magazine_size":24, "fire_rate":12.0, "recoil_impulse":92.0, "reload_time":1.55}
		],
		"active_weapon": 0, "measurement": true, "shake": false,
		"target_mode": true, "turn_speed": 110.0, "custom_root": "keep"
	}
	overlay.setup(config)
	overlay.show_panel(config)
	await process_frame
	await process_frame
	var frame = overlay.find_children("*", "PanelContainer", true, false)[0]
	_check(frame.get_global_rect().end.x <= 320 and frame.get_global_rect().end.y <= 180, "Panel must fit 320 x 180 after minimum-size layout")
	var captured: Array = []
	overlay.apply_requested.connect(func(value: Dictionary): captured.append(value))
	var measurement = overlay.get("_toggles")["measurement"]
	var shake = overlay.get("_toggles")["shake"]
	measurement.button_pressed = false
	shake.button_pressed = true
	measurement.button_pressed = true
	_check(shake.disabled and not shake.button_pressed, "Measurement mode must disable and clear camera shake")
	# Apply must enforce this even if state is changed programmatically.
	shake.button_pressed = true
	var gravity = overlay.find_child("Player_gravity", true, false)
	var air_y = overlay.find_child("Player_air_control_y", true, false)
	gravity.value = 200.0
	air_y.value = 1900.0
	overlay.find_child("Apply", true, false).pressed.emit()
	_check(captured.size() == 1, "Apply must emit exactly one configuration")
	if not captured.is_empty():
		var edited: Dictionary = captured[0]
		_check(edited.custom_root == "keep" and edited.player.custom_physics == 17 and edited.weapons[0].damage == 30, "Unexposed settings must survive Apply")
		_check(edited.weapons[0].magazine_size == 137, "Unsupported magazine tuning must preserve the original configuration exactly")
		_check(not edited.has("loadout"), "Applied config has no separate quick-gun loadout")
		_check(edited.player.air_control_y < edited.player.gravity, "Air vertical control must remain below gravity")
		_check(is_equal_approx(edited.player.air_control_y, 160.0), "Gravity 200 must clamp air control Y to the shared 80% boundary of 160")
		_check(edited.measurement and not edited.shake, "Applied measurement config must always suppress shake")
		_check(config.player.gravity == 1500.0 and config.active_weapon == 0, "Editing must never mutate the supplied configuration")
	_check(overlay.process_mode == Node.PROCESS_MODE_ALWAYS, "Panel must work while simulation is paused")
	paused = true
	var inventory := [
		{"occupied": true, "id": "revolver", "ammo": 4},
		{"occupied": true, "id": "shotgun", "ammo": 2},
		{"occupied": true, "id": "smg", "ammo": 19},
		{"occupied": false}, {"occupied": false}, {"occupied": false}
	]
	overlay.update_hud({"velocity": Vector2(30, -120), "health": 5, "weapon_id": "smg", "active_slot": 2, "inventory": inventory, "ammo": 19, "magazine":24, "reload_progress":0.5})
	var status = overlay.find_child("ReloadStatus", true, false)
	var all_slots_exist := true
	for number in range(1, 7):
		all_slots_exist = all_slots_exist and overlay.find_child("WeaponSlot%d" % number, true, false) != null
	_check(all_slots_exist, "HUD exposes all six numbered inventory slots")
	var selected_slot = overlay.find_child("WeaponSlot3", true, false)
	var empty_slot = overlay.find_child("WeaponSlot6", true, false)
	_check(selected_slot != null and selected_slot.text.begins_with("["), "HUD highlights the current weapon slot")
	_check(empty_slot != null and "-" in empty_slot.text, "HUD distinguishes empty weapon slots")
	_check(status != null, "HUD has explicit reload status")
	if status != null:
		_check("50%" in status.text, "HUD reload label follows current weapon progress")
		overlay.update_hud({"ammo": 6, "magazine":6, "reload_progress":-1.0})
		_check("READY" in status.text, "HUD clears reload status when magazine completes")
	overlay.show_notice("Test notice")
	overlay.hide_panel()
	paused = false
	overlay.queue_free()
	await process_frame
	var formal = load("res://scripts/ui/lab_overlay.gd").new()
	formal.lab_navigation = false
	root.add_child(formal)
	formal.setup(config)
	formal.show_panel(config)
	await process_frame
	await process_frame
	var pause_panel: Control = formal.find_child("TuningPanel", true, false)
	var pause_frame: PanelContainer = formal.find_child("PauseFrame", true, false)
	_check(pause_panel != null and pause_frame != null, "Campaign pause panel must expose its authored frame")
	if pause_panel != null and pause_frame != null:
		_check(is_equal_approx(pause_panel.scale.x, 0.25), "Campaign pause art should use native 1280 design units")
		var art: StyleBox = pause_frame.get_theme_stylebox("panel")
		_check(art is StyleBoxTexture and art.texture.resource_path.ends_with("journal_frame.png"), "Campaign pause frame must render the authored journal art")
		_check(art.content_margin_left >= 100 and art.content_margin_top >= 75, "Campaign pause content stays clear of the frame ornaments")
		var bounds := pause_frame.get_global_rect()
		_check(bounds.position.x >= 0 and bounds.position.y >= 0 and bounds.end.x <= 320 and bounds.end.y <= 180, "Campaign pause art must fit the game viewport")
		for key in ["Resume", "Apply"]:
			var button: Button = formal.find_child(key, true, false)
			_check(button != null and button.get_theme_stylebox("normal") is StyleBoxTexture, "%s uses an authored button state" % key)
			if button != null:
				_check(bounds.encloses(button.get_global_rect()), "%s remains within the authored pause frame" % key)
				for state in ["normal", "hover", "pressed", "disabled"]:
					var style: StyleBox = button.get_theme_stylebox(state)
					_check(style is StyleBoxTexture and style.texture.resource_path.ends_with("button_%s.png" % state), "%s has authored %s art" % [key, state])
				_check(button.get_theme_stylebox("focus") is StyleBoxEmpty, "Focus must not draw a second complete metal frame")
				_check(button.get_theme_color("font_focus_color") != button.get_theme_color("font_color"), "Keyboard focus remains visibly indicated")
				var normal: StyleBox = button.get_theme_stylebox("normal")
				_check(normal.content_margin_top >= 22 and normal.content_margin_bottom >= 22, "Button text remains clear of its authored upper/lower edge")
				var line_height: float = button.get_theme_font("font").get_height(button.get_theme_font_size("font_size"))
				_check(button.size.y >= line_height + normal.content_margin_top + normal.content_margin_bottom, "Button grows to contain its text and safe margins")
	formal.hide_panel()
	formal.show_story("档案记录", "已完成的调查会保留。\n下一段线索还有待确认。")
	await process_frame
	var story_frame: Panel = formal.find_child("StoryFrame", true, false)
	_check(story_frame != null and story_frame.get_theme_stylebox("panel") is StyleBoxTexture, "Campaign story card uses authored frame art")
	if story_frame != null:
		var bounds := story_frame.get_global_rect()
		_check(bounds.position.x >= 0 and bounds.position.y >= 0 and bounds.end.x <= 320 and bounds.end.y <= 180, "Campaign story art must fit the game viewport")
		var scroll: ScrollContainer = formal.find_child("StoryScroll", true, false)
		var hint: Label = formal.find_child("StoryHint", true, false)
		_check(scroll != null and hint != null, "Story body and hint remain separate controls")
		if scroll != null and hint != null:
			_check(scroll.get_global_rect().end.y <= hint.get_global_rect().position.y, "Story footer must not overlap scrolled text")
			_check(bounds.encloses(hint.get_global_rect()), "Story footer remains inside quiet frame area")
	formal.queue_free()
	await process_frame
	print("Overlay checks: ", "PASS" if failure_count == 0 else "FAIL")
	quit(0 if failure_count == 0 else 1)
