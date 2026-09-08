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
		"loadout": [0, 1], "measurement": true, "shake": false,
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
	var first = overlay.find_child("Slot0", true, false)
	first.select(1)
	first.item_selected.emit(1)
	overlay.find_child("Apply", true, false).pressed.emit()
	_check(captured.size() == 1, "Apply must emit exactly one configuration")
	if not captured.is_empty():
		var edited: Dictionary = captured[0]
		_check(edited.custom_root == "keep" and edited.player.custom_physics == 17 and edited.weapons[0].damage == 30, "Unexposed settings must survive Apply")
		_check(edited.weapons[0].magazine_size == 137, "Unsupported magazine tuning must preserve the original configuration exactly")
		_check(edited.loadout[0] != edited.loadout[1], "Equipped slots must remain distinct")
		_check(edited.player.air_control_y < edited.player.gravity, "Air vertical control must remain below gravity")
		_check(is_equal_approx(edited.player.air_control_y, 160.0), "Gravity 200 must clamp air control Y to the shared 80% boundary of 160")
		_check(edited.measurement and not edited.shake, "Applied measurement config must always suppress shake")
		_check(config.player.gravity == 1500.0 and config.loadout == [0, 1], "Editing must never mutate the supplied configuration")
	_check(overlay.process_mode == Node.PROCESS_MODE_ALWAYS, "Panel must work while simulation is paused")
	paused = true
	overlay.update_hud({"velocity": Vector2(30, -120), "health": 5, "ammo": 4, "magazine":6, "reload_progress":0.5})
	var status = overlay.find_child("ReloadStatus", true, false)
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
	print("Overlay checks: ", "PASS" if failure_count == 0 else "FAIL")
	quit(0 if failure_count == 0 else 1)
