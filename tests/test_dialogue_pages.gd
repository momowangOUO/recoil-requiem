extends SceneTree

var checks := 0
var failures := 0
var selected := ""

func _initialize() -> void: run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func settle(frames := 3) -> void:
	for i in frames: await process_frame

func key(code: int, down: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = down
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func capture(path: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/" + path + ".png")

func run() -> void:
	if not "--campaign-test" in OS.get_cmdline_user_args():
		push_error("Requires --campaign-test; never load or write the user's save")
		quit(1)
		return
	var presentation = load("res://scenes/game.tscn").instantiate()
	root.add_child(presentation)
	await settle(12)
	presentation.flow.hide()
	presentation.run_started = true
	var game = presentation.stage.game
	var session = game.campaign_session
	var ui = session.ui
	game.player.manual_control = true
	game.player.invulnerability = 10000
	ui.choice_selected.connect(func(id): selected = id)
	key(KEY_E, true)
	session.dialogue("mara", ["mon.mara.hello", "mon.player.target", "mon.mara.ask"], [["later", "mon.tools.later.choice"]])
	await settle()
	check(ui._dialogue_index == 0 and not ui._dialogue_armed, "Held opening input preserves first utterance")
	check(ui.find_children("CurrentUtterance", "Label", true, false).size() == 1, "Only one utterance is rendered")
	check(ui.find_children("*", "ScrollContainer", true, false).is_empty(), "Dialogue has no transcript scroll")
	check(ui._dialogue_portrait.name == "DialoguePortrait_mara", "First utterance has Mara portrait")
	check(ui._dialogue_actions.get_child(0) is Label, "Choices are absent before last utterance")
	key(KEY_E, false)
	await settle()
	check(ui._dialogue_index == 0 and ui._dialogue_armed, "Release arms without advancing")
	key(KEY_E, true)
	await settle()
	check(ui._dialogue_index == 1 and ui._dialogue_portrait.name == "DialoguePortrait_mara", "Second sentence retains same speaker portrait")
	check(str(ui._dialogue_pages[0].text) + str(ui._dialogue_pages[1].text) == session.text("mon.mara.hello"), "Sentence split preserves exact reviewed wording and punctuation")
	key(KEY_E, false)
	await settle()
	key(KEY_E, true)
	await settle()
	check(ui._dialogue_index == 2 and ui._dialogue_portrait.name == "DialoguePortrait_player", "Fresh E advances to actual player portrait")
	check(ui.find_child("CurrentUtterance", true, false).text == session.text("mon.player.target"), "Visible utterance matches reviewed text")
	check(paused and game.reading, "Advancing keeps gameplay paused")
	await capture("dialogue_player_1280")
	key(KEY_E, false)
	await settle()
	key(KEY_SPACE, true)
	await settle()
	check(ui._dialogue_index == 3 and ui._dialogue_actions.get_child(0) is Button, "Fresh Space reaches final utterance and reveals choices")
	check(selected.is_empty(), "Arrival at final utterance never submits choice")
	key(KEY_SPACE, false)
	await settle()
	key(KEY_ENTER, true)
	await settle()
	check(selected == "later" and not ui.is_panel_open(), "Fresh Enter submits focused stable choice ID and resumes safely")
	key(KEY_ENTER, false)
	await settle()
	session.dialogue("mara", ["mon.mara.hello", "mon.player.entry", "mon.mara.ask"])
	await settle()
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = ui._dialogue_row.get_global_rect().get_center()
	root.push_input(click, true)
	click = click.duplicate()
	click.pressed = false
	root.push_input(click, true)
	await settle()
	check(ui._dialogue_index == 1, "Clicking quiet sentence area advances exactly one utterance")
	key(KEY_ESCAPE, true)
	await settle()
	check(not ui.is_panel_open() and ui._dialogue_pages.is_empty() and not paused, "Escape safely clears pagination and resumes")
	check(not is_instance_valid(ui._dialogue_portrait) and not is_instance_valid(ui._dialogue_illustration), "Closing removes independent portrait and quest overlays")
	key(KEY_ESCAPE, false)
	for person in ["player", "mara", "ina", "ruka", "celine", "vira"]:
		var line_id: String = "mon.player.target" if person == "player" else "mon." + person + ".hello"
		session.dialogue(person, [line_id])
		await settle()
		var portrait: TextureRect = ui._dialogue_portrait
		check(portrait.texture != null, "Actual speaker portrait resolves: " + person)
		await capture("dialogue_portrait_" + person + "_1280")
	for dimensions in [Vector2i(960,540), Vector2i(1280,720), Vector2i(1920,1080), Vector2i(2560,1080)]:
		root.size = dimensions
		session.dialogue("mara", ["mon.mara.hello"])
		await settle()
		check(ui.panel.get_rect().end.y <= 720 and ui.panel.get_rect().end.x <= 1280, "Dialogue bounds at %s" % dimensions)
		check(ui._dialogue_portrait.get_parent() == ui and ui._dialogue_portrait.position.y + 100 < ui.panel.position.y, "Portrait is independent and protrudes above frame at %s" % dimensions)
		check(ui._dialogue_portrait.get_rect().intersects(ui.panel.get_rect()), "Portrait overlaps the frame at %s" % dimensions)
		var utterance: Label = ui.find_child("CurrentUtterance", true, false)
		check(utterance.get_global_rect().end.y < ui._dialogue_actions.get_global_rect().position.y, "Text does not overlap actions at %s" % dimensions)
		await capture("dialogue_mara_%dx%d" % [dimensions.x, dimensions.y])
		session.dialogue("", ["mon.tools.inspect"], [["tools_ina", "mon.tools.return.choice"], ["tools_mara", "mon.tools.keep.choice"], ["later", "mon.tools.later.choice"]])
		await settle()
		check(not is_instance_valid(ui._dialogue_portrait), "Inspection never invents a speaking character")
		check(ui._dialogue_actions.get_child_count() == 3, "All three choices preserved at %s" % dimensions)
		check(ui.panel.get_rect().end.y <= 720, "Three-choice panel fits at %s" % dimensions)
		await capture("dialogue_tools_choices_%dx%d" % [dimensions.x, dimensions.y])
		for portrait in ui.find_children("Quest_*", "TextureRect", true, false):
			check(portrait.texture != null, "Quest illustration resolves at %s" % dimensions)
	session.close()
	presentation.free()
	paused = false
	print("DIALOGUE PAGINATION STAGE RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
