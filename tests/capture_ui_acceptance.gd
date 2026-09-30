extends SceneTree
## Real scenes/game.tscn GPU acceptance, with explicit staged story/map states.
var presentation: Control
var game: RecoilLab
var checks := 0
var selected := ""

func _initialize() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		push_error(label)
		quit(1)
func settle(count := 4) -> void:
	for i in count: await process_frame
func capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/ui_acceptance_" + label + ".png")
func click(button: Button) -> void:
	var move := InputEventMouseMotion.new()
	move.position = button.get_global_rect().get_center()
	root.push_input(move,true)
	await process_frame
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = button.get_global_rect().get_center()
	root.push_input(press,true)
	await process_frame
	press = press.duplicate()
	press.pressed = false
	root.push_input(press,true)
	await process_frame

func run() -> void:
	root.size = Vector2i(1280,720)
	presentation = load("res://scenes/game.tscn").instantiate()
	root.add_child(presentation)
	await settle(20)
	game = presentation.stage.game
	game.player.manual_control = true
	game.player.invulnerability = 10000
	var session = game.campaign_session
	var ui = session.ui
	var hud = game.overlay.combat
	check(ui.panel.get_theme_stylebox("panel") is StyleBoxTexture,"Panel uses authored imagegen nine-patch artwork")
	check(ui.panel.get_theme_stylebox("panel").content_margin_left >= 82,"Panel text stays in the quiet center, clear of corner ornament")
	check(ui.theme.get_stylebox("focus","Button") is StyleBoxEmpty,"Focus border cannot paint over the button surface")
	check(ui.theme.has_stylebox("disabled","Button"),"Disabled buttons have an authored state")
	await capture("combat_1280")
	await RenderingServer.frame_post_draw
	var background_pixel := root.get_texture().get_image().get_pixel(800,680)
	ui.modulate.a = 0
	hud.modulate.a = 0
	await settle(2)
	await capture("world_without_ui_1280")
	var world_pixel: Color = root.get_texture().get_image().get_pixel(800,680)
	check(absf(world_pixel.r - background_pixel.r) + absf(world_pixel.g - background_pixel.g) + absf(world_pixel.b - background_pixel.b) < 0.025,"Bottom dark field belongs to rendered world, allowing tiny animated-light variance")
	ui.modulate.a = 1
	hud.modulate.a = 1
	check(not hud.ring_state().visible,"Idle ammunition ring is hidden")
	var input := InputFrame.new()
	input.fire_pressed = true
	input.aim_world = game.player.aim_origin() + Vector2(180,0)
	game.player.step(input,1.0/60)
	await settle(2)
	check(hud.shot_time > 0 and hud.ring_state().visible,"Real successful shot shows transient ammo ring")
	await capture("shot_1280")
	await create_timer(0.4).timeout
	check(not hud.ring_state().visible,"Shot-only ring disappears after its 0.35 second window")
	var weapon = game.player.weapons.current()
	weapon.start_reload()
	weapon.tick(0.4,true)
	await settle(2)
	check(is_equal_approx(hud.ring_state().ratio,weapon.progress()),"HUD reload ring matches actual WeaponRuntime progress")
	await capture("reload_1280")
	session.pause()
	var paused_progress: float = weapon.progress()
	await settle(4)
	check(is_equal_approx(weapon.progress(),paused_progress),"Paused world freezes actual reload progress")
	session.close()
	weapon.cancel_reload()
	await settle(2)
	check(not hud.ring_state().visible,"Cancelled reload removes the ring")
	game.player.weapons.select_weapon(1)
	weapon = game.player.weapons.current()
	weapon.ammo = 0
	weapon.start_reload()
	weapon.tick(weapon.data.reload_time * 1.4,true)
	await settle(2)
	check(weapon.ammo == 1 and is_equal_approx(hud.ring_state().ratio,weapon.progress()),"Shotgun next-shell ring uses current shell progress")
	await capture("shotgun_shell_1280")
	var spaces: Dictionary = {}
	for id in game.environment.space_bounds:
		spaces[id] = {"rect":game.environment.space_bounds[id],"title":session.Data.SPACE_NAMES[int(id.trim_prefix("mon_"))-1]}
	ui.choice_selected.connect(func(id): selected = id)
	session.event("met_ina")
	session.event("met_ruka")
	session.close()
	var journal_key := InputEventKey.new()
	journal_key.physical_keycode = KEY_J
	journal_key.pressed = true
	Input.parse_input_event(journal_key)
	await settle(3)
	check(ui.panel_kind == "journal" and paused,"Actual J key opens journal and pauses world")
	var tracking_buttons: Array = ui.find_children("*","Button",true,false)
	var tracking_scroll: ScrollContainer = ui.find_children("*","ScrollContainer",true,false)[0]
	tracking_scroll.scroll_vertical = int(tracking_scroll.get_v_scroll_bar().max_value)
	await settle(2)
	await click(tracking_buttons[-1])
	check(session.selected_side == "records","Real journal click selects one side quest")
	session.close()
	for dimensions in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(960,540),Vector2i(2560,1080)]:
		root.size = dimensions
		await settle(3)
		await capture("tracker_%d" % dimensions.x)
		check(ui._side.text.contains(session.text("mon.records.title")) and not ui._side.text.contains(session.text("mon.tools.title")),"Tracker shows exactly the chosen side quest")
		session.pause()
		ui.show_map(spaces,game.environment.connections,spaces.keys(),game.environment.gate_states,game.player.position,game.environment.checkpoints)
		await settle(3)
		check(ui.panel.get_rect().end.y <= 720,"Map panel fits canvas at " + str(dimensions))
		var buttons: Array = ui.find_children("*","Button",true,false)
		check(buttons.size() == 21,"Map has close, four navigation controls, and all 16 visited room names")
		for id in spaces:
			var found := false
			for button in buttons:
				if button.text.ends_with(spaces[id].title): found = true
			check(found,"Full explored room name available: " + str(id))
		if dimensions.x == 1280:
			var wheel := InputEventMouseButton.new()
			wheel.button_index = MOUSE_BUTTON_WHEEL_UP
			wheel.pressed = true
			wheel.position = ui._map.get_global_rect().get_center()
			var old_zoom: float = ui._map_zoom
			root.push_input(wheel,true)
			var wheel_release := wheel.duplicate()
			wheel_release.pressed = false
			root.push_input(wheel_release,true)
			await settle(2)
			check(ui._map_zoom > old_zoom,"Real mouse wheel zooms the paused M map")
			await click(buttons.filter(func(button): return button.text == "全图")[0])
			await settle(2)
			check(ui._map_full and is_equal_approx(ui._map_zoom,ui._full_map_zoom()),"Full-map button works while paused")
			await click(buttons.filter(func(button): return button.text == "回到当前位置")[0])
			await settle(2)
			check(ui._world_at_map(ui._map.size * 0.5).distance_to(game.player.position) < 2,"Return-player button works while paused")
			var map_center: Vector2 = ui._map.get_global_rect().get_center()
			var hover_map := InputEventMouseMotion.new()
			hover_map.position = map_center
			root.push_input(hover_map,true)
			await settle(1)
			var drag_press := InputEventMouseButton.new()
			drag_press.button_index = MOUSE_BUTTON_LEFT
			drag_press.pressed = true
			drag_press.position = map_center
			root.push_input(drag_press,true)
			await settle(1)
			var drag_move := InputEventMouseMotion.new()
			drag_move.position = map_center + Vector2(30,-10)
			drag_move.relative = Vector2(30,-10)
			root.push_input(drag_move,true)
			await settle(1)
			var drag_release := drag_press.duplicate()
			drag_release.position = drag_move.position
			drag_release.pressed = false
			root.push_input(drag_release,true)
			await settle(1)
			check(ui._map_pan.length() > 10,"Real mouse drag pans the paused M map")
		await click(buttons[5])
		await settle(2)
		check(not ui._map_selected.is_empty(),"Map legend selects/highlights known space")
		check(ui.theme.default_font_size * dimensions.x / 1280.0 >= 24,"Native text is at least 24px")
		await capture("map16_%d" % dimensions.x)
		# Long exchanges retain one readable sentence and gate their final options.
		var transcript: Array = []
		for i in 8: transcript.append(session.text("mon.records.note"))
		ui.show_dialogue("玛拉",transcript,[{"id":"ui_test","text":session.text("mon.records.keep.choice")}])
		await settle(3)
		check(ui.panel.get_rect().end.y <= 720,"Long dialogue stays within canvas")
		check(ui.find_children("*","ScrollContainer",true,false).is_empty(),"Dialogue never becomes a scrolling transcript")
		check(ui.find_children("CurrentUtterance","Label",true,false).size() == 1,"Only the current sentence is visible")
		while ui._dialogue_index + 1 < ui._dialogue_pages.size():
			ui.advance_dialogue()
			await settle(1)
		buttons = ui.find_children("*","Button",true,false)
		await click(ui._dialogue_actions.get_child(0))
		check(selected == "ui_test","Final dialogue option accepts real mouse click while paused")
		await capture("dialogue_bottom_%d" % dimensions.x)
		session.close()
	ui.show_map(spaces,game.environment.connections,[spaces.keys()[0]],game.environment.gate_states,game.player.position,game.environment.checkpoints)
	await settle(3)
	check(ui.find_children("*","Button",true,false).size() == 6,"Unexplored 15 room names are absent")
	await capture("map_fog_960")
	ui.close_panel()
	check(ui.tracker.visible,"Tracker returns unchanged after closing map")
	presentation.free()
	print("UI ACCEPTANCE PASS: %d checks, actual main scene, 960/1280/1920/wide requested, 16-room map, fog, paused map wheel/buttons and dialogue click, live shot/reload" % checks)
	quit()
