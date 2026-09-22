extends Control
## 640x360 pixel world, native-resolution UI. Logical gameplay remains 320x180.

@export var campaign_enabled := true
var stage: CrimsonStage3D
var stage_viewport: SubViewport
var mouse_screen := Vector2(160, 90)
const FlowUI = preload("res://scripts/ui/player_flow_ui.gd")
var flow
var settings_path := "user://player_settings.cfg"
var player_settings := {"volume": 1.0, "fullscreen": false, "shake": false}
var settings_error := ""
var completion_seen := false
var run_started := false
var _return_page := "title"
var _confirm_return_page := "title"
var _developer_pause := false
var _test_mode := false

func _enter_tree() -> void:
	# Custom draw_string calls and 3D labels share the native UI's authored glyphs.
	ThemeDB.fallback_font = preload("res://assets/fonts/unifont-18.0.01.otf")

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
	if campaign_enabled and stage.game.campaign_session != null:
		_test_mode = "--campaign-test" in OS.get_cmdline_user_args()
		var layer := CanvasLayer.new()
		layer.layer = 40
		add_child(layer)
		flow = FlowUI.new()
		layer.add_child(flow)
		flow.action_requested.connect(handle_flow_action)
		flow.setting_changed.connect(set_player_setting)
		stage.game.campaign_session.save_status_changed.connect(func(_status: Dictionary): refresh_flow())
		completion_seen = stage.game.campaign_session.has("returned")
		get_tree().auto_accept_quit = false
		if not _test_mode:
			load_player_settings()
			get_window().focus_exited.connect(_on_focus_exited)
			show_title()

func _input(event: InputEvent) -> void:
	if event is InputEventMouse:
		mouse_screen = event.position
	if flow != null:
		if flow.visible:
			if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE:
				if flow.page == "pause": _resume_play()
				elif flow.page in ["settings", "help"]: handle_flow_action("back")
				elif flow.page in ["restart", "quit_unsaved"]: handle_flow_action("cancel")
				get_viewport().set_input_as_handled()
			return
		if event is InputEventKey and event.pressed and not event.echo:
			var game = stage.game
			if event.physical_keycode == KEY_ESCAPE and not game.campaign_session.ui.is_panel_open():
				if _developer_pause and game.paused:
					_developer_pause = false
					game.resume_trial()
				else: _show_flow("pause")
				get_viewport().set_input_as_handled()
				return
			if event.physical_keycode == KEY_TAB and not game.campaign_session.ui.is_panel_open():
				_developer_pause = not game.paused
	if is_instance_valid(stage):
		stage._input(event)

func get_aim_screen() -> Vector2:
	return mouse_screen

func _process(_delta: float) -> void:
	if flow == null: return
	_update_player_shake()
	var session = stage.game.campaign_session
	if flow.visible:
		_hide_gameplay_ui()
	elif not completion_seen and session.has("returned") and not session.ui.is_panel_open() and not stage.game.paused:
		completion_seen = true
		_show_flow("completed")

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and flow != null:
		handle_flow_action("quit")

func _on_focus_exited() -> void:
	if flow != null and not flow.visible and not _developer_pause and not stage.game.campaign_session.ui.is_panel_open():
		_show_flow("pause")

func _hide_gameplay_ui() -> void:
	var game = stage.game
	game.overlay.hide()
	game.reticle.hide()
	game.campaign_session.ui.hide()
	if game.overlay.combat != null:
		game.overlay.combat.suspend(true)
		game.overlay.combat.hide()

func _flow_context() -> Dictionary:
	var session = stage.game.campaign_session
	var messages: Array[String] = []
	if session.save_status.code in ["recovered", "load_failed", "write_failed"]:
		messages.append(session.save_status.message)
	if not settings_error.is_empty(): messages.append(settings_error)
	return {"has_progress": run_started or session.loaded_from_disk, "save_code": session.save_status.code, "status": "\n".join(messages), "settings": player_settings}

func _show_flow(page: String) -> void:
	var game = stage.game
	game.paused = true
	game.reading = false
	game.player.clear_jump_buffer()
	game.input_adapter.suppress()
	game.overlay.hide_panel()
	game.audio.stop_all()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_hide_gameplay_ui()
	flow.show_page(page, _flow_context())

func show_title() -> void:
	_show_flow("title")

func refresh_flow() -> void:
	if flow == null or not flow.visible: return
	# Rebuild when an error adds/removes a recovery button. Setting edits only
	# update status, so dragging the volume slider never destroys its focus.
	var context := _flow_context()
	if context.save_code != flow.context.get("save_code", ""):
		flow.show_page(flow.page, context)
	else:
		flow.context = context
		flow.update_status(context.status)
		flow.update_settings(player_settings)

func _resume_play() -> void:
	flow.hide()
	_developer_pause = false
	var game = stage.game
	game.overlay.show()
	game.resume_trial()
	game.input_adapter.suppress()
	if game.overlay.combat != null: game.overlay.combat.suspend(false)
	game.campaign_session.ui.show()
	game.campaign_session.ui._process(0.0)
	run_started = true

func handle_flow_action(id: String) -> void:
	if flow == null: return
	var game = stage.game
	var session = game.campaign_session
	match id:
		"begin", "continue", "explore":
			if session.save_status.code != "load_failed" or flow.page != "title": _resume_play()
		"settings", "help":
			_return_page = flow.page
			_show_flow(id)
		"back": _show_flow(_return_page)
		"restart":
			if session.save_status.code == "load_failed": return
			_confirm_return_page = flow.page
			_show_flow("restart")
		"confirm":
			if flow.page != "restart" or session.save_status.code == "load_failed": return
			if session.restart_chapter() != OK:
				refresh_flow()
				return
			completion_seen = false
			game.reset_trial(3)
			_apply_player_settings()
			_resume_play()
		"cancel": _show_flow(_confirm_return_page)
		"checkpoint":
			session.state.restore_checkpoint()
			game.reset_trial(3)
			_apply_player_settings()
			_resume_play()
		"title_return":
			if session.save_now() == OK: show_title()
			else: refresh_flow()
		"retry_save":
			session.save_now()
			refresh_flow()
		"retry_load":
			if session.load_save() == OK:
				completion_seen = session.has("returned")
				game.reset_trial(3)
				_apply_player_settings()
				show_title()
			else: refresh_flow()
		"journal":
			_resume_play()
			session.pause()
			session.ui.show_journal(session.journal_entries())
		"quit":
			if session.save_now() == OK: get_tree().quit()
			else:
				_confirm_return_page = flow.page if flow.visible else "pause"
				_show_flow("quit_unsaved")
		"quit_unsaved":
			if flow.page == "quit_unsaved": get_tree().quit()

func load_player_settings() -> Error:
	var config := ConfigFile.new()
	settings_error = ""
	var candidate := {"volume": 1.0, "fullscreen": false, "shake": false}
	var error := config.load(settings_path)
	if error != OK and error != ERR_FILE_NOT_FOUND:
		settings_error = FlowUI.COPY.settings_load_failed
	elif error == OK:
		for key in candidate:
			var value: Variant = config.get_value("player", key, candidate[key])
			if (key == "volume" and (value is float or value is int)) or (key != "volume" and value is bool):
				candidate[key] = clampf(float(value), 0.0, 1.0) if key == "volume" else value
			else:
				error = ERR_INVALID_DATA
				settings_error = FlowUI.COPY.settings_load_failed
				break
	player_settings = candidate if error == OK else {"volume": 1.0, "fullscreen": false, "shake": false}
	_apply_player_settings()
	refresh_flow()
	return error

func set_player_setting(key: String, value: Variant) -> void:
	if not player_settings.has(key): return
	player_settings[key] = clampf(float(value), 0.0, 1.0) if key == "volume" else bool(value)
	_apply_player_settings()
	var config := ConfigFile.new()
	for setting in player_settings: config.set_value("player", setting, player_settings[setting])
	var error := config.save(settings_path)
	settings_error = "" if error == OK else FlowUI.COPY.settings_failed
	refresh_flow()

func _apply_player_settings() -> void:
	AudioServer.set_bus_volume_linear(0, float(player_settings.volume))
	stage.game.config.shake = bool(player_settings.shake)
	if not player_settings.shake: stage.game.shake_time = 0
	if DisplayServer.get_name() != "headless":
		var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if player_settings.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != mode: DisplayServer.window_set_mode(mode)
	_update_player_shake()

func _update_player_shake() -> void:
	# The old 2D camera is disabled in the 3D presentation. Feed its existing
	# recoil/hurt shake into the actual perspective camera; do not alter physics.
	var game = stage.game
	var offset := Vector2.ZERO
	if game.config.shake and not game.config.measurement and game.shake_time > 0 and not game.paused:
		offset = game.camera.offset * CrimsonStage3D.PIXEL
	stage.camera.h_offset = offset.x
	stage.camera.v_offset = -offset.y
