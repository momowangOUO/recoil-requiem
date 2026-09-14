extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.content_scale_size = Vector2i(320,180)
	root.size = Vector2i(1280,720)
	var backdrop := TextureRect.new()
	backdrop.texture = ImageTexture.create_from_image(Image.load_from_file("res://docs/screenshots/gothic_rig.png"))
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_SCALE
	backdrop.size = Vector2(320,180)
	root.add_child(backdrop)
	var i := 0
	for id in ["mara","ina","ruka"]:
		var npc = load("res://scripts/campaign/campaign_npc.gd").new()
		npc.npc_id = id
		npc.position = Vector2(64 + i * 92, 111)
		root.add_child(npc)
		assert(npc._frames.size() == 2)
		assert(npc._sizes[0] == npc._sizes[1])
		i += 1
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/campaign_npc_comparison.png")
	print("NPC FIXTURE PASS: three two-frame sheets, fixed cell scale, GPU capture")
	quit()
