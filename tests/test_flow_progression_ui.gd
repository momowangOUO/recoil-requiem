extends SceneTree

var failures := 0
var checks := 0
var selected := ""

func _initialize() -> void: run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func settle(frames := 3) -> void:
	for i in frames: await process_frame

func run() -> void:
	var presentation = load("res://scenes/game.tscn").instantiate()
	root.add_child(presentation)
	await settle(12)
	var game = presentation.stage.game
	var session = game.campaign_session
	var ui = session.ui
	var actor = game.player
	actor.manual_control = true
	actor.invulnerability = 10000
	check(ui.tutorial_action == "move", "First lesson teaches movement only")
	ui._process(20.0)
	check(ui._controls.visible, "Elapsed time never completes an unperformed action")
	var frame := InputFrame.new()
	frame.move = Vector2.RIGHT
	frame.aim_world = actor.position + Vector2(100, -26)
	for i in 32:
		actor.step(frame, 1.0 / 60)
		presentation._physics_process(1.0 / 60)
	check(session.has("tutorial_move") and ui.tutorial_action != "move", "Actual walking completes and persists movement lesson")
	actor.position = game.environment.story_positions.tutorial_jump
	presentation._update_tutorial()
	check(ui.tutorial_action == "jump", "Jump prompt belongs to the authored optional crate landing")
	ui.show_dialogue("", ["维拉今晚要离开修道院。"], [])
	check(not ui._controls.visible, "Dialogue suppresses the pending contextual lesson")
	ui.close_panel()
	ui.set_interaction_prompt()
	check(ui._controls.visible, "Unperformed lesson resumes after dialogue")
	for i in 10: actor.step(InputFrame.new(), 1.0 / 60)
	Input.action_press("jump")
	frame = InputFrame.new()
	frame.jump_pressed = true
	actor.step(frame, 1.0 / 60)
	presentation._physics_process(0.0)
	Input.action_release("jump")
	check(session.has("tutorial_jump"), "A successful jump completes the optional lesson")
	actor.position = game.environment.story_positions.tutorial_shoot
	presentation._update_tutorial()
	check(ui.tutorial_action == "shoot", "Shooting lesson belongs to the safe authored platform")
	frame = InputFrame.new()
	frame.fire_pressed = true
	frame.fire_held = true
	frame.aim_world = actor.position + Vector2(-100, -26)
	actor.step(frame, 1.0 / 60)
	check(session.has("tutorial_shoot"), "A successful shot completes shooting")
	var runtime = actor.weapons.current()
	runtime.ammo = 1
	presentation._update_tutorial()
	check(ui.tutorial_action == "reload", "Low ammunition introduces reload after shooting")
	runtime.start_reload()
	presentation._physics_process(0.0)
	runtime.cancel_reload()
	runtime.tick(runtime.data.reload_time, true)
	presentation._physics_process(0.0)
	check(not session.has("tutorial_reload"), "Cancelling before ammunition enters does not complete reload")
	runtime.start_reload()
	presentation._physics_process(0.0)
	runtime.tick(runtime.data.reload_time, true)
	presentation._physics_process(0.0)
	check(session.has("tutorial_reload"), "Real inserted ammunition completes reload")
	actor.weapons.select_weapon(2)
	check(session.has("tutorial_switch"), "Successful equipment change persists switch completion")
	presentation._update_tutorial()
	check(ui.tutorial_action == "smg", "First switch gives one current-weapon use hint")
	frame = InputFrame.new()
	frame.fire_held = true
	frame.aim_world = actor.position + Vector2(-100, -26)
	actor.step(frame, 1.0 / 60)
	check(presentation._tutorial_weapon_tip.is_empty(), "Using the selected gun completes its action hint")
	actor.melee.start(actor)
	presentation._physics_process(0.0)
	check(session.has("tutorial_claw"), "Actual claw action persists completion")
	var map_key := InputEventKey.new()
	map_key.physical_keycode = KEY_M
	map_key.pressed = true
	session.handle_input(map_key)
	presentation._process(0.0)
	check(session.has("tutorial_map"), "Opening the actual map completes its lesson")
	session.close()

	actor.position = Vector2(1256,584)
	actor.velocity = Vector2.ZERO
	for tick in 18:
		await physics_frame
		actor.step(InputFrame.new(),1.0/60)
	presentation._update_tutorial()
	check(ui.tutorial_action == "drop" and ui._controls.text.begins_with("S"),"An unexplored grate teaches the actual downward input")
	frame = InputFrame.new()
	frame.drop_pressed = true
	actor.step(frame,1.0/60)
	presentation._physics_process(0.0)
	check(session.has("tutorial_drop"),"Only an actual drop completes the contextual instruction")

	ui.choice_selected.connect(func(id): selected = id)
	session.pause()
	var held := InputEventKey.new()
	held.physical_keycode = KEY_SPACE
	held.keycode = KEY_SPACE
	held.pressed = true
	Input.parse_input_event(held)
	Input.flush_buffered_events()
	ui.show_departure([session.text("mon.flow.departure.body"), session.text("mon.flow.departure.tools")], [{"id":"later", "text":session.text("mon.flow.departure.wait")}, {"id":"go_test", "text":session.text("mon.flow.departure.go")}], session.text("mon.flow.departure.title"))
	ui._process(0.0)
	var confirm: Button = ui._departure_buttons[1]
	confirm.pressed.emit()
	check(selected.is_empty() and confirm.disabled, "Held dialogue input cannot submit departure")
	held = held.duplicate()
	held.pressed = false
	Input.parse_input_event(held)
	Input.flush_buffered_events()
	ui._process(0.0)
	check(selected.is_empty() and not confirm.disabled, "Releasing old input only arms confirmation")
	confirm.pressed.emit()
	check(selected == "go_test", "A separate button action confirms departure")
	for dimensions in [Vector2i(960,540), Vector2i(1280,720), Vector2i(1920,1080), Vector2i(2560,1080)]:
		root.size = dimensions
		await settle()
		check(ui.panel.get_rect().end.y <= 720, "Departure content fits at %s" % dimensions)
		for button in ui._departure_buttons:
			check(button.size.x <= ui.panel.size.x - 180 and button.size.y >= 72, "Departure button safe area at %s" % dimensions)
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://artifacts/flow_departure_%dx%d.png" % [dimensions.x, dimensions.y])
	ui.close_panel()
	presentation.run_started = true
	presentation.show_title()
	root.size = Vector2i(960,540)
	await settle()
	check(not presentation.flow.context.location.is_empty() and not presentation.flow.context.current_objective.is_empty(), "Continue receives actual location and current objective")
	check(presentation.flow.stack.get_node("ContinueLocation").text == presentation.flow.context.location, "Continue location is rendered")
	check(presentation.flow.stack.get_node("ContinueObjective").text == presentation.flow.context.current_objective, "Continue objective is rendered")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/flow_continue_960.png")
	presentation.free()
	paused = false
	print("FLOW PROGRESSION UI STAGE RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
