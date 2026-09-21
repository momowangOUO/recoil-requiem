extends SceneTree
## Actual main-scene coverage for opening context, interaction feedback and tracker transitions.

const Data = preload("res://scripts/campaign/monastery_data.gd")

var presentation: Control
var game: RecoilLab
var checks := 0
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func settle(count := 4) -> void:
	for i in count:
		await process_frame

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/onboarding_" + label + ".png")

func labels_contain(node: Node, copy: String) -> bool:
	for label in node.find_children("*", "Label", true, false):
		if copy in label.text: return true
	return false

func run() -> void:
	root.size = Vector2i(960, 540)
	presentation = load("res://scenes/game.tscn").instantiate()
	root.add_child(presentation)
	await settle(20)
	game = presentation.stage.game
	game.player.manual_control = true
	game.player.invulnerability = 10000
	var session = game.campaign_session
	var ui: CampaignUI = session.ui
	var opening := Data.onboarding_ui()
	check(ui._opening.visible, "Opening self-talk is visible during the first objective")
	check(str(opening.lines[0]) in ui._opening.text and str(opening.lines[1]) in ui._opening.text, "Opening states the known target and immediate route")
	check(ui._opening.get_line_count() == 2, "Opening remains two deliberate subtitle lines with the shared pixel font at 960")
	check(ui._opening.get_rect().end.y <= ui._controls.position.y and ui._controls.get_rect().end.y <= 720, "Opening subtitle and small control hint occupy separate bottom-center bands")
	check(ui._opening.get_parent() == ui and ui._controls.get_parent() == ui and ui._completion.get_parent() == ui, "Opening, controls and completion feedback are independent of the objective tracker")
	check(ui.tracker.get_child_count() == 2 and ui._main.get_parent() == ui.tracker and ui._side.get_parent() == ui.tracker, "Tracker contains only the current objective and selected side quest")
	check(ui._controls.text == opening.opening_controls and "A / D" in ui._controls.text and "空格" in ui._controls.text and "左键" in ui._controls.text, "Independent opening hint teaches movement, jump, aim and fire in two lines")
	var tracker_texture_size := ui._tracker_art.texture.get_size()
	check(is_equal_approx(ui._tracker_art.size.x / ui._tracker_art.size.y, tracker_texture_size.x / tracker_texture_size.y), "Tracker frame keeps the authored texture aspect ratio")
	check(ui._tracker_art.get_rect().end.y <= 720, "Compact tracker remains inside the native canvas")
	check(ui.tracker.position.y >= ui._tracker_art.position.y + 50, "Tracker text clears the ornate top border with the shared pixel font")
	var pause_key := InputEventKey.new()
	pause_key.physical_keycode = KEY_ESCAPE
	pause_key.pressed = true
	game._input(pause_key)
	ui._process(0.0)
	check(game.paused and not ui.visible, "External Esc pause hides the entire campaign layer instead of leaking hints below settings")
	var resume_key := InputEventKey.new()
	resume_key.physical_keycode = KEY_TAB
	resume_key.pressed = true
	game._input(resume_key)
	ui._process(0.0)
	check(not game.paused and ui.visible and ui._opening.visible and ui.tracker.visible, "Campaign layer restores its prior opening state after Tab closes external pause")
	var spawn_interaction: Dictionary = session.nearest()
	if spawn_interaction.is_empty():
		check(not ui.interaction_prompt_visible(), "Natural spawn with no nearby point has no invented interaction")
	else:
		var spawn_id := str(spawn_interaction.get("id", ""))
		var spawn_hint := Data.interaction_prompt(spawn_id, spawn_interaction.get("npc", false), session.has("met_" + spawn_id))
		var spawn_target := "" if str(spawn_hint.target).is_empty() else "　" + str(spawn_hint.target)
		var expected_spawn := str(opening.interact).replace("{action}", str(spawn_hint.action)).replace("{target}", spawn_target)
		check(ui.interaction_prompt_visible() and ui._interaction_label.text == expected_spawn, "Natural spawn shows only the interaction resolved from the real nearest point")
	await capture("spawn_960")
	session.event("inner_reached")
	check(Data.main_title_id(session.state.snapshot().facts) == "mon.main01.title" and session.text("mon.main01.title") in ui._main.text, "Early exploration cannot replace the still-executable first meeting objective")

	ui.set_interaction_prompt("", "交谈")
	check(ui.interaction_prompt_visible() and ui._interaction_label.text == "E　交谈", "Nearby NPC gets an explicit E interaction prompt without revealing identity")
	check(not ui._opening.visible and not ui._controls.visible, "A concrete world interaction replaces the transient opening and tutorial copy")
	check(ui._interaction_art.position.x >= 400 and ui._interaction_art.get_rect().end.x <= 880, "Interaction prompt stays in the lower center, clear of the left combat HUD")
	var tools_prompt := Data.interaction_prompt("tools", false)
	ui.set_interaction_prompt(tools_prompt.target, tools_prompt.action)
	check(ui._interaction_label.text == "E　调查　工具箱", "Authored action mapping names the nearby quest prop")
	ui.set_interaction_prompt()

	for point in session.points:
		if point.id == "mara": game.player.position = point.position + Vector2(-24, 0)
	# This is a location fixture, not traversal: settle the presentation before
	# E pauses its camera, otherwise the screenshot freezes halfway from spawn.
	presentation.stage._update_camera(3.0)
	presentation.stage._physics_process(0.0)
	session.refresh()
	await settle(3)
	check(ui.interaction_prompt_visible() and ui._interaction_label.text == "E　交谈", "Real Mara position shows an anonymous talk prompt before the first meeting")
	await capture("mara_prompt_960")
	var e_key := InputEventKey.new()
	e_key.physical_keycode = KEY_E
	e_key.pressed = true
	check(session.handle_input(e_key), "Actual E input is consumed by the campaign session")
	await settle(3)
	check(ui.panel_kind == "dialogue" and session.has("met_mara"), "Actual E at Mara opens the approved first conversation")
	ui._process(0.0)
	check(ui.visible, "Campaign-owned paused dialogue remains visible")
	check(ui.panel.position.x >= 260, "Dialogue quiet frame stays clear of the lower-left combat HUD")
	check(not ui._opening.visible and not ui._controls.visible and not ui._completion.visible and not ui.tracker.visible, "Dialogue modal hides onboarding, controls, completion feedback and objective tracker")
	check(ui._modal_scrim.visible, "Dialogue modal dims the world HUD instead of mixing it with conversation text")
	check(ui._controls.text == opening.controls and "E" in ui._controls.text and "J" in ui._controls.text and "M" in ui._controls.text, "First conversation replaces basic controls with the compact interaction/log/map hint")
	check(ui._completion_active and str(opening.completed).replace("{objective}", str(opening.objective)) == ui._completion.text, "Main objective transition queues an independent short completion result")
	var dialogue_style: StyleBoxTexture = ui.panel.get_theme_stylebox("panel")
	check(dialogue_style.texture_margin_top >= 90 and dialogue_style.texture_margin_bottom >= 90, "Dialogue nine-slice protects the full-height corner ornaments")
	check(Data.main_title_id(session.state.snapshot().facts) == "mon.main02.title", "Reaching the inner court early still sends the player to Vira before departure")
	check(session.text(Data.main_title_id(session.state.snapshot().facts)) in ui._main.text, "Pure monastery objective selection matches the live tracker")
	await capture("mara_dialogue_960")
	session.close()
	check(ui.tracker.visible and ui._tracker_art.visible and not ui._controls.visible and ui._completion.visible and not ui._modal_scrim.visible, "Closing dialogue restores only the tracker, live prompt and unexpired completion result")
	await capture("tracker_after_mara_960")

	root.size = Vector2i(1280, 720)
	await settle(3)
	await capture("tracker_plain_1280")
	var journal_key := InputEventKey.new()
	journal_key.physical_keycode = KEY_J
	journal_key.pressed = true
	check(session.handle_input(journal_key), "Actual J input opens the campaign journal")
	await settle(3)
	check(not ui.interaction_prompt_visible(), "World interaction prompt hides behind a journal or dialogue panel")
	check(ui._modal_scrim.visible, "Journal uses the same quiet modal backdrop")
	check(labels_contain(ui.panel, session.text("mon.main01.hint")), "Completed opening context remains available in the journal")
	check(ui.panel.get_rect().end.x <= 1280 and ui.panel.get_rect().end.y <= 720, "Journal review stays inside the 1280 canvas")
	for button in ui.panel.find_children("*", "Button", true, false):
		check(button.size.y >= 68, "Journal button frame leaves a real vertical text safe area: " + button.text)
	await capture("journal_review_1280")
	session.close()
	check(ui.interaction_prompt_visible(), "Nearby interaction prompt returns after closing the journal")

	var map_key := InputEventKey.new()
	map_key.physical_keycode = KEY_M
	map_key.pressed = true
	check(session.handle_input(map_key), "Actual M input opens the campaign map for button-layout review")
	await settle(3)
	var focus_button: Button
	for button in ui.panel.find_children("*", "Button", true, false):
		check(button.size.y >= 68, "Map button frame leaves a real vertical text safe area: " + button.text)
		check(button.get_theme_stylebox("focus") is StyleBoxEmpty, "Keyboard focus never layers a second ornate frame: " + button.text)
		if button.text == "回到当前位置": focus_button = button
	await capture("map_buttons_1280")
	check(focus_button != null, "Map focus fixture finds the return-to-player button")
	if focus_button != null:
		focus_button.grab_focus()
		await settle(2)
		check(focus_button.has_focus(), "Map button exposes a real keyboard-focus state")
		await capture("map_buttons_focus_1280")
	session.close()

	var transcript_ids: Array = []
	for i in 8:
		transcript_ids.append("mon.records.note")
	# Deliberate overflow fixture: session.dialogue supplies the real pause/modal path.
	session.dialogue("", transcript_ids, [["later", "mon.records.keep.choice"]])
	await settle(3)
	check(ui.panel.get_rect().end.y <= 720, "Long dialogue remains inside the native canvas")
	check(not ui.tracker.visible and not ui._controls.visible and not ui._completion.visible, "Long dialogue stress state contains no competing tracker or transient hints")
	var scroll: ScrollContainer = ui.find_children("*", "ScrollContainer", true, false)[0]
	check(scroll.get_v_scroll_bar().max_value > scroll.size.y, "Long dialogue keeps real scroll overflow")
	check(labels_contain(ui.panel, session.text("mon.records.note")), "Long dialogue text stays readable in the quiet content area")
	await capture("long_dialogue_stress_1280")
	session.close()
	ui.set_interaction_prompt()
	await create_timer(3.1, true).timeout
	check(not ui._completion.visible, "Completion feedback disappears instead of accumulating")
	root.size = Vector2i(960, 540)
	game.set_process(false)
	game.set_physics_process(false)
	ui.set_tracker("沿门楼石阶进入外庭", "到货梯间取回伊娜落下的工具箱")
	ui._completion.hide()
	await settle(3)
	check(ui._side.visible and "当前目标　" in ui._main.text and "支线　" in ui._side.text, "Compact tracker keeps main and selected-side labels inline")
	var tracker_text_bottom := ui.tracker.position.y
	for label in [ui._main, ui._side]:
		if label.visible: tracker_text_bottom = maxf(tracker_text_bottom, ui.tracker.position.y + label.position.y + label.size.y)
	var tracker_inner_top := ui._tracker_art.position.y + ui._tracker_art.size.y * 47.0 / 183.0
	var tracker_inner_bottom := ui._tracker_art.position.y + ui._tracker_art.size.y * 135.0 / 183.0
	check(ui.tracker.position.y >= tracker_inner_top + 6, "Main objective clears the real upper silver border at 960")
	check(tracker_text_bottom <= tracker_inner_bottom - 8, "Main and selected side objective clear the real lower silver border at 960")
	check(is_equal_approx(ui._tracker_art.size.x / ui._tracker_art.size.y, tracker_texture_size.x / tracker_texture_size.y), "Selected side objective expands the tracker proportionally without stretching ornaments")
	check("沿门楼石阶进入外庭" in ui._main.text and "到货梯间取回伊娜落下的工具箱" in ui._side.text, "Tracker retains both complete objective texts")
	await capture("tracker_main_side_960")
	presentation.free()
	print("CAMPAIGN ONBOARDING UI STAGE RESULT: %d checks, %d failures; natural spawn, real Mara E dialogue, 960/1280 review and paused long-dialogue stress" % [checks, failures])
	quit(1 if failures else 0)
