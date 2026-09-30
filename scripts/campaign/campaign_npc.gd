class_name CampaignNPC
extends Node2D

@export var npc_id := "mara"
@export_file("*.png") var art_path := ""
@export var display_height := 42.0
@export var art_grid := Vector2i(4, 2)
@export var art_region := Rect2i()
@export var facing_left := false
var _frames: Array[Texture2D] = []
var _sizes: Array[Vector2] = []
var _offsets: Array[Vector2] = []
var _elapsed := 0.0
var _frame := 0
var _own_sheet := true
var _motion_path: Array[Vector2] = []
var _cover_time := 0.0
signal path_finished

func walk_path(path: Array[Vector2]) -> void:
	_motion_path = path.duplicate()
	_elapsed = 0.0

func play_cover(target: Vector2) -> void:
	facing_left = target.x < position.x
	_cover_time = 0.36

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	reload_art()

func reload_art() -> void:
	_frames.clear()
	_sizes.clear()
	_offsets.clear()
	var path := art_path if not art_path.is_empty() else "res://assets/characters/npcs/%s_idle_v2.png" % npc_id
	var image: Image
	if ResourceLoader.exists(path):
		var resource = load(path)
		if resource is Texture2D: image = resource.get_image()
	else:
		image = Image.load_from_file(path)
	if image == null or image.is_empty():
		push_warning("Campaign NPC art unavailable: " + path)
		return
	image.convert(Image.FORMAT_RGBA8)
	# Authored NPC assets are two 128px cells. External enemy sheets use a
	# neutral first cell from their action grid; never animate attack poses.
	var own_sheet := path.contains("/npcs/")
	_own_sheet = own_sheet
	var authored_anchor := Vector2.INF
	var authored_frames: Array = []
	var authored_scale := 0.0
	var manifest_path := "res://assets/characters/campaign/manifest_data.gd"
	if not own_sheet and ResourceLoader.exists(manifest_path):
		var manifest = load(manifest_path).DATA
		for kind in ["elite", "boss"]:
			if path != manifest.get(kind,{}).get("path", ""): continue
			var first: Dictionary = manifest[kind].frames[0]
			authored_frames = manifest[kind].frames
			authored_scale = manifest[kind].scale
			var r: Array = first.region
			art_region = Rect2i(r[0],r[1],r[2],r[3])
			authored_anchor = Vector2(first.anchor[0],first.anchor[1])
	var columns := 2 if own_sheet else maxi(1, art_grid.x)
	var rows := 1 if own_sheet else maxi(1, art_grid.y)
	var cell := Vector2i(image.get_width() / columns, image.get_height() / rows)
	for x in image.get_width():
		for y in image.get_height():
			var color := image.get_pixel(x,y)
			if color.r > 0.55 and color.b > 0.55 and color.g < minf(color.r,color.b) * 0.6:
				image.set_pixel(x,y,Color.TRANSPARENT)
	var count := 2 if own_sheet else maxi(1, authored_frames.size())
	for i in count:
		var region := Rect2i(Vector2i(i * cell.x, 0), cell)
		if not own_sheet and art_region.has_area(): region = art_region
		if not authored_frames.is_empty():
			var pose: Dictionary = authored_frames[i]
			region = Rect2i(pose.region[0],pose.region[1],pose.region[2],pose.region[3])
			authored_anchor = Vector2(pose.anchor[0],pose.anchor[1])
		var frame := image.get_region(region)
		var used := frame.get_used_rect()
		if used.size.y <= 0: continue
		if not own_sheet and authored_anchor == Vector2.INF: frame = frame.get_region(used)
		_frames.append(ImageTexture.create_from_image(frame))
		var factor := display_height / (96.0 if own_sheet else float(frame.get_height()))
		if authored_scale > 0: factor = authored_scale
		var dimensions := Vector2(frame.get_width(),frame.get_height()) * factor
		_sizes.append(dimensions)
		if authored_anchor != Vector2.INF:
			_offsets.append((Vector2(region.position) - authored_anchor) * factor)
		else:
			_offsets.append(Vector2(-dimensions.x * 0.5, -120.0 * factor if own_sheet else -dimensions.y))
	_frame = 0
	_elapsed = 0
	queue_redraw()

func _process(delta: float) -> void:
	_elapsed += delta
	_cover_time = maxf(0.0, _cover_time - delta)
	var walking := not _motion_path.is_empty()
	if walking:
		var destination := _motion_path[0]
		facing_left = destination.x < position.x
		position = position.move_toward(destination, delta * 96.0)
		if position.distance_to(destination) < 0.1:
			_motion_path.pop_front()
			if _motion_path.is_empty(): path_finished.emit()
	if _frames.size() < 2: return
	var next := int(_elapsed / 0.85) % _frames.size() if _own_sheet else 0
	if not _own_sheet and walking: next = 1 + int(_elapsed / 0.14) % 2
	elif not _own_sheet and _cover_time > 0: next = 4 if _cover_time > 0.18 else 5
	if next != _frame:
		_frame = next
		queue_redraw()

func _draw() -> void:
	if _frames.is_empty(): return
	var dimensions := _sizes[_frame]
	var rect := Rect2(_offsets[_frame], dimensions)
	if facing_left:
		rect.position.x = -rect.position.x
		rect.size.x *= -1
	draw_texture_rect(_frames[_frame], rect, false)


