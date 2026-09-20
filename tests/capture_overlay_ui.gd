extends SceneTree
## GPU review of the generated formal pause and story art in the actual game.

func _initialize() -> void:
	run.call_deferred()

func settle(frames: int = 4) -> void:
	for i in frames:
		await process_frame

func capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/overlay_v2_%s.png" % label)

func run() -> void:
	root.size = Vector2i(1280, 720)
	var presentation: Control = load("res://scenes/game.tscn").instantiate()
	root.add_child(presentation)
	await settle(16)
	var overlay: LabOverlay = presentation.stage.game.overlay
	for dimensions in [Vector2i(960, 540), Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(2560, 1080)]:
		root.size = dimensions
		overlay.show_panel(presentation.stage.game.config)
		await settle(5)
		await capture("pause_%d_%d" % [dimensions.x, dimensions.y])
		if dimensions.x == 1280:
			var tabs: TabContainer = overlay.find_children("*", "TabContainer", true, false)[0]
			for page in range(1, tabs.get_tab_count()):
				tabs.current_tab = page
				await settle(2)
				await capture("pause_tab_%d" % page)
			tabs.current_tab = 0
		overlay.hide_panel()
		overlay.show_story("档案记录", "莉芙再次核对钟楼里的记录。\n\n" + "若有人提前拿走证据，后来的人只会见到空抽屉。\n".repeat(18))
		await settle(4)
		await capture("story_%d_%d" % [dimensions.x, dimensions.y])
		overlay.hide_story()
	presentation.free()
	print("OVERLAY V2 CAPTURE COMPLETE: 11 screenshots")
	quit()
