extends SceneTree

var checks := 0
var failures := 0
var presentation: Control
var fixture := "user://player_flow_%s" % Time.get_ticks_usec()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func _initialize() -> void:
	if "--flow-startup-check" in OS.get_cmdline_user_args() and not OS.get_environment("APPDATA").ends_with("player-flow-startup-user"):
		push_error("Startup test requires its dedicated isolated APPDATA")
		quit(1)
		return
	run.call_deferred()

func settle(count := 4) -> void:
	for i in count: await process_frame

func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	var release := InputEventKey.new()
	release.physical_keycode = code
	release.pressed = false
	Input.parse_input_event(release)
	await settle(2)

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/player_flow_" + label + ".png")

func run() -> void:
	root.size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(fixture)
	presentation = load("res://scenes/game.tscn").instantiate()
	root.add_child(presentation)
	await settle(12)
	check(presentation.has_method("show_title"), "Main presentation exposes the actual player title flow")
	if not presentation.has_method("show_title"):
		presentation.free()
		finish()
		return
	if "--flow-startup-check" in OS.get_cmdline_user_args():
		await run_startup_checks()
		finish()
		return
	var game = presentation.stage.game
	var session = game.campaign_session
	game.player.manual_control = true
	game.player.invulnerability = 10000
	check(not presentation.flow.visible and not paused, "Campaign-test fixtures skip automatic startup menu")
	presentation.settings_path = fixture + "/settings.cfg"
	session.save_path = fixture + "/save.json"
	session.autosave = true
	check(session.load_save() == OK, "Player-flow save fixture is isolated")
	presentation.show_title()
	await settle()
	check(presentation.flow.page == "title" and paused and game.paused, "Title pauses the existing world")
	check(not game.reticle.visible and not session.ui.visible and not game.overlay.combat.visible, "Title hides all unrelated gameplay overlays")
	check(presentation.flow.buttons.has("begin") and not presentation.flow.buttons.has("continue"), "A fresh slot is offered Start, not Continue")
	check(not presentation.flow.buttons.has("restart"), "Fresh title does not duplicate Start with Restart")
	for dimensions in [Vector2i(960,540),Vector2i(1280,720),Vector2i(1920,1080),Vector2i(2560,1080)]:
		root.size = dimensions
		await settle(5)
		var flow = presentation.flow
		check(flow.art_rect.encloses(flow.content.get_rect()), "Menu stays in generated image bounds at %s" % dimensions)
		check(flow.content.position.x >= flow.art_rect.position.x + flow.art_rect.size.x * 0.69, "Native content stays in the authored right-side quiet area at %s" % dimensions)
		for button in flow.buttons.values():
			check(button.get_theme_stylebox("focus") is StyleBoxEmpty, "Focus does not duplicate generated button ornament")
			check(button.size.x <= flow.content.size.x + 1, "Buttons fit the safe content width at %s" % dimensions)
		await capture("title_%dx%d" % [dimensions.x, dimensions.y])
	root.size = Vector2i(1280,720)
	presentation.handle_flow_action("begin")
	await settle()
	check(not paused and not presentation.flow.visible and game.reticle.visible, "Start restores play and reticle")
	check(session.ui.visible and game.overlay.visible, "Resuming restores the campaign UI and HUD host")
	await key(KEY_ESCAPE)
	await settle()
	check(paused and presentation.flow.page == "pause" and not game.overlay._panel.visible, "Esc opens player pause without leaking into the lab input")
	await capture("pause_1280")
	await key(KEY_ESCAPE)
	check(not paused and not presentation.flow.visible, "One Esc resumes exactly once")
	await key(KEY_TAB)
	check(game.overlay._panel.visible and paused and not presentation.flow.visible, "Tab retains developer tuning")
	await key(KEY_TAB)
	check(not paused, "Tab resumes developer tuning")
	await key(KEY_ESCAPE)
	presentation.handle_flow_action("help")
	await settle()
	check(presentation.flow.page == "help", "Pause opens actual help page")
	await capture("help_1280")
	presentation.handle_flow_action("back")
	presentation.handle_flow_action("settings")
	presentation.set_player_setting("volume", 0.25)
	presentation.set_player_setting("shake", true)
	check(is_equal_approx(AudioServer.get_bus_volume_linear(0), 0.25) and game.config.shake, "Settings change master audio and actual camera-shake config")
	check(presentation.flow.volume_control.value == 25 and presentation.flow.buttons.shake.button_pressed, "Visible settings reflect the actual runtime values")
	var saved := ConfigFile.new()
	check(saved.load(presentation.settings_path) == OK and saved.get_value("player", "shake") == true, "Settings persist in an actual ConfigFile")
	presentation.player_settings.volume = 0.8
	check(presentation.load_player_settings() == OK and is_equal_approx(presentation.player_settings.volume, 0.25), "Loading persisted settings restores actual runtime values")
	presentation.flow.volume_control.value = 35
	check(is_equal_approx(AudioServer.get_bus_volume_linear(0), 0.35), "Actual slider signal updates audio")
	presentation.flow.buttons.shake.button_pressed = false
	check(not game.config.shake, "Actual generated toggle button updates the setting")
	presentation.flow.buttons.shake.button_pressed = true
	check(game.config.shake, "Toggle can turn camera shake back on")
	await settle()
	await capture("settings_1280")
	if DisplayServer.get_name() != "headless":
		presentation.flow.buttons.fullscreen.button_pressed = true
		await settle(4)
		check(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN, "Fullscreen toggle changes the actual OS window")
		presentation.flow.buttons.fullscreen.button_pressed = false
		await settle(4)
		check(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED, "Fullscreen toggle restores a window")
		root.size = Vector2i(1280,720)
	var good_settings_path: String = presentation.settings_path
	presentation.settings_path = fixture + "/blocked.cfg"
	DirAccess.make_dir_absolute(presentation.settings_path)
	presentation.set_player_setting("volume", 0.5)
	check(not presentation.settings_error.is_empty() and not presentation.flow.status.text.is_empty(), "Settings write failures remain visible")
	presentation.settings_path = good_settings_path
	presentation.set_player_setting("volume", 0.25)
	check(presentation.settings_error.is_empty(), "Successful settings retry clears its error")
	presentation.handle_flow_action("back")
	presentation.handle_flow_action("continue")
	game.camera.offset = Vector2(2, -2)
	game.shake_time = 0.08
	presentation._update_player_shake()
	check(stage_shakes(), "Enabled shake reaches the actual perspective camera")
	presentation.set_player_setting("shake", false)
	check(not stage_shakes(), "Disabling shake immediately clears perspective camera offsets")
	await key(KEY_ESCAPE)
	check(session.save_now() == OK, "Prepare real saved progress")
	session.event("met_mara")
	var previous: Dictionary = session.state.snapshot()
	presentation.handle_flow_action("title_return")
	check(presentation.flow.page == "title" and presentation.flow.buttons.has("continue"), "Return to title saves then offers Continue")
	presentation.handle_flow_action("restart")
	check(presentation.flow.page == "restart" and session.state.snapshot() == previous, "Restart requires a separate confirmation before changing progress")
	presentation.handle_flow_action("confirm")
	await settle(5)
	check(not session.has("met_mara") and not paused, "Confirmed restart restores chapter start")
	check(not session.restart_backup_path.is_empty() and FileAccess.file_exists(session.restart_backup_path), "Restart keeps a durable backup outside rotating autosave")
	var prior = session.Store.new()
	prior.configure(session.Data.catalog(), session.Data.quests())
	check(prior.load_from(session.restart_backup_path) == OK and prior.has_flag("met_mara"), "Restart archive actually contains old chapter progress")
	# Existing task completion is simulated; this is not a traversal/playthrough.
	session.event("returned")
	session.dialogue("", ["mon.exit.notice"])
	await settle()
	check(not presentation.flow.visible, "Completion cannot interrupt an open dialogue")
	session.close()
	await settle()
	check(presentation.flow.page == "completed" and presentation.flow.visible and paused, "Completion appears after the final dialogue closes")
	await capture("completed_1280")
	presentation.handle_flow_action("journal")
	check(session.ui.panel_kind == "journal" and not presentation.flow.visible, "Completion can open real journal records")
	session.close()
	await settle()
	check(not presentation.flow.visible, "Completion is shown once per play session")
	await key(KEY_ESCAPE)
	DirAccess.make_dir_absolute(session.save_path + ".tmp")
	presentation.handle_flow_action("title_return")
	check(presentation.flow.page == "pause" and session.save_status.code == "write_failed", "Failed save blocks a pretend-success return to title")
	check(not presentation.flow.status.text.is_empty() and presentation.flow.buttons.has("retry_save"), "Save failure has a persistent status and retry action")
	presentation.handle_flow_action("quit")
	check(presentation.flow.page == "quit_unsaved", "Failed exit requires explicit unsaved-progress confirmation")
	presentation.handle_flow_action("cancel")
	DirAccess.remove_absolute(session.save_path + ".tmp")
	presentation.handle_flow_action("retry_save")
	check(session.save_status.code == "ready", "Player can retry the failed save")
	# Never confirm the actual quit action in the test runner.
	presentation.show_title()
	session.autosave = false
	session._set_save_status("load_failed", ERR_INVALID_DATA)
	presentation.refresh_flow()
	check(presentation.flow.buttons.restart.disabled and presentation.flow.buttons.has("retry_load"), "Rejected saves cannot be overwritten by the new-game button")
	var before: Dictionary = session.state.snapshot()
	presentation.handle_flow_action("confirm")
	check(session.state.snapshot() == before, "Direct restart action is also guarded after failed load")
	run_copy_review(presentation.flow.COPY)
	paused = false
	presentation.free()
	finish()

func run_copy_review(copy: Dictionary) -> void:
	var reviewed := {}
	for line in FileAccess.get_file_as_string("res://game-text/player-flow-review.md").split("\n"):
		if not line.begins_with("| "): continue
		var cells := line.split("|")
		if cells.size() >= 4 and copy.has(cells[1].strip_edges()):
			reviewed[cells[1].strip_edges()] = cells[2].strip_edges().replace("\\n", "\n")
	check(reviewed == copy, "Decoded player-menu text exactly matches standalone reviewed draft")

func stage_shakes() -> bool:
	return not is_zero_approx(presentation.stage.camera.h_offset) or not is_zero_approx(presentation.stage.camera.v_offset)

func run_startup_checks() -> void:
	check(presentation.flow.visible and presentation.flow.page == "title" and paused, "Normal production launch automatically opens a paused title page")
	var session = presentation.stage.game.campaign_session
	check(session.save_status.code == "ready", "A production startup has no invented save warning")
	# This mode is guarded by an isolated APPDATA directory before loading game.
	session.event("returned")
	check(session.save_now() == OK, "Completed progress is saved in the isolated startup profile")
	presentation.free()
	paused = false
	presentation = load("res://scenes/game.tscn").instantiate()
	root.add_child(presentation)
	await settle(12)
	check(presentation.flow.buttons.has("continue") and presentation.completion_seen, "Completed save loads into title with Continue and completion already acknowledged")
	presentation.handle_flow_action("continue")
	await settle(5)
	check(not presentation.flow.visible and not paused and presentation.stage.game.campaign_session.has("returned"), "Loading a completed chapter allows exploration without reopening completion")
	presentation.free()
	paused = false

func clean_fixture(path: String) -> void:
	assert(path == fixture or path.begins_with(fixture + "/"))
	for item in DirAccess.get_files_at(path): DirAccess.remove_absolute(path + "/" + item)
	for item in DirAccess.get_directories_at(path): clean_fixture(path + "/" + item)
	DirAccess.remove_absolute(path)

func finish() -> void:
	clean_fixture(fixture)
	print("PLAYER FLOW STAGE RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
