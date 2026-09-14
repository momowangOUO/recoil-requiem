extends SceneTree

func _initialize() -> void:
	var image := Image.load_from_file("res://assets/characters/npcs/npcs_source_v2.png")
	image.convert(Image.FORMAT_RGBA8)
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x,y)
			if color.r > 0.55 and color.b > 0.55 and color.g < minf(color.r,color.b) * 0.6:
				image.set_pixel(x,y,Color.TRANSPARENT)
	var names := ["mara", "ina", "ruka"]
	for column in 3:
		var frames: Array[Image] = []
		var max_height := 0
		for row in 2:
			var frame := image.get_region(Rect2i(column * 512, row * 512, 512, 512))
			frame = frame.get_region(frame.get_used_rect())
			max_height = maxi(max_height, frame.get_height())
			frames.append(frame)
		var factor := 96.0 / max_height
		var output := Image.create(256,128,false,Image.FORMAT_RGBA8)
		for row in 2:
			var frame := frames[row]
			frame.resize(maxi(1,roundi(frame.get_width()*factor)), maxi(1,roundi(frame.get_height()*factor)),Image.INTERPOLATE_NEAREST)
			output.blit_rect(frame,Rect2i(Vector2i.ZERO,frame.get_size()),Vector2i(row*128+64-frame.get_width()/2,120-frame.get_height()))
		output.save_png("res://assets/characters/npcs/%s_idle_v2.png" % names[column])
	print("NPC source keyed and split into 3 shared-scale two-frame 256x128 sheets")
	quit()


