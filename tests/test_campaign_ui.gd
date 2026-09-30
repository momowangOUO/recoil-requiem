extends SceneTree

var ui: Control
var selected := ""
var closed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.content_scale_size = Vector2i(320, 180)
	root.size = Vector2i(1280, 720)
	var backdrop := TextureRect.new()
	backdrop.texture = ImageTexture.create_from_image(Image.load_from_file("res://docs/screenshots/combat_hud_rest.png"))
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_SCALE
	backdrop.size = Vector2(320, 180)
	root.add_child(backdrop)
	ui = load("res://scripts/ui/campaign_ui.gd").new()
	root.add_child(ui)
	ui.choice_selected.connect(func(id): selected = id)
	ui.close_requested.connect(func(): closed += 1)
	ui.set_tracker("沿门楼石阶进入外庭", "找回伊娜的工具箱")
	ui.show_dialogue("玛拉", ["玛拉：前门不让带枪。你从哪儿进来的？"], [{"id":"entry", "text":"运输站旁边的石阶。那条路还通着。"}])
	await process_frame
	await process_frame
	ui.advance_dialogue()
	await process_frame
	await process_frame
	assert(ui.panel.get_rect().end.x <= 1280 and ui.panel.get_rect().end.y <= 720)
	var buttons := ui.find_children("*", "Button", true, false)
	assert(buttons.size() == 2)
	paused = true
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = ui._dialogue_actions.get_child(0).get_global_rect().get_center()
	root.push_input(click, true)
	click = click.duplicate()
	click.pressed = false
	root.push_input(click, true)
	await process_frame
	assert(selected == "entry")
	ui._dialogue_close.pressed.emit()
	assert(closed == 1)
	paused = false
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/ui_campaign_dialogue_1280.png")
	ui.show_journal([{"title":"外庭", "body":"从运输站沿道路下石阶，穿过门楼进入外庭。", "category":"tasks"}])
	await process_frame
	await process_frame
	assert(ui.panel.get_rect().end.y <= 720)
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/ui_campaign_journal_1280.png")
	root.size = Vector2i(1920, 1080)
	ui.show_map({"a":{"rect":Rect2(0,0,400,240),"title":"外庭"}, "b":{"rect":Rect2(450,0,500,240),"title":"货梯"}, "secret":{"rect":Rect2(1050,0,600,240),"title":"SECRET MUST NOT RENDER"}}, [{"from":"a","to":"b","gate_id":"g"}, {"from":"b","to":"secret","gate_id":""}], ["a","b"], {"g":false}, Vector2(120,180), [Vector2(80,180)])
	await process_frame
	await process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/ui_campaign_map_1920.png")
	ui.close_panel()
	assert(not ui.is_panel_open() and ui.tracker.visible)
	print("CAMPAIGN UI STAGE RESULT: PASS; panel bounds, paused choice/close signals, tracker persistence; 1280/1920 fixtures")
	quit()
