extends SceneTree
## Deterministic cropping of approved complete generated poses; one scale per character.
func _initialize() -> void:
	var source := Image.load_from_file("res://assets/characters/npcs/chapter_actions_source_v1.png")
	assert(source != null and source.get_size() == Vector2i(1536,1024))
	# Generated alpha contains faint backdrop noise; sprites use hard opaque pixels.
	for y in source.get_height():
		for x in source.get_width():
			var color := source.get_pixel(x,y)
			if color.a < 0.5: color = Color(0,0,0,0)
			else: color.a = 1.0
			source.set_pixel(x,y,color)
	var rows := [
		{"id":"mara", "height":449.0, "crops":[Rect2i(177,53,265,449),Rect2i(651,53,264,449),Rect2i(1131,53,266,449)], "feet":[Vector2(309,502),Vector2(782,502),Vector2(1262,502)]},
		{"id":"vira", "height":439.0, "crops":[Rect2i(124,588,376,383),Rect2i(610,588,381,383),Rect2i(1098,532,402,439)], "feet":[Vector2(270,971),Vector2(755,971),Vector2(1273,971)]}
	]
	for row in rows:
		var output := Image.create(384,128,false,Image.FORMAT_RGBA8)
		var factor: float = 96.0 / row.height
		for index in 3:
			var region: Rect2i = row.crops[index]
			var frame := source.get_region(region)
			frame.resize(roundi(region.size.x*factor),roundi(region.size.y*factor),Image.INTERPOLATE_NEAREST)
			var anchor: Vector2 = (row.feet[index] - Vector2(region.position)) * factor
			output.blit_rect(frame,Rect2i(Vector2i.ZERO,frame.get_size()),Vector2i(index*128+64-roundi(anchor.x),120-roundi(anchor.y)))
		assert(output.save_png("res://assets/characters/npcs/%s_story_v1.png" % row.id) == OK)
	print("NPC STORY SPLIT: 2 complete-body 384x128 three-frame sheets; hard alpha, shared scales and authored foot anchors")
	quit()
