extends RefCounted
## Real cutaway masonry from the approved image construction records.
## All coordinates below are logical pixels, and depth alone uses 3D metres.
const P := 0.01
var stage: Node3D
var stone: StandardMaterial3D
var trim: StandardMaterial3D
var paving: StandardMaterial3D
var iron: StandardMaterial3D
var brass: StandardMaterial3D
var wood: StandardMaterial3D
var glass: StandardMaterial3D
var roof: StandardMaterial3D
var banner: StandardMaterial3D
var stained_glass: StandardMaterial3D
var close_stone: StandardMaterial3D

func build(host: Node3D) -> void:
	stage = host
	stone = _masonry(Color("777080"))
	trim = _masonry(Color("ada1ac"))
	paving = _masonry(Color("b6aab6"))
	paving.uv1_scale *= 0.625
	close_stone = StandardMaterial3D.new()
	var close_source := preload("res://assets/environments/crimson/close_facade_bays_v1.png")
	# Right of the last buttress: only masonry, no arch frame or vertical trim.
	close_stone.albedo_texture = ImageTexture.create_from_image(close_source.get_image().get_region(Rect2i(1872, 160, 112, 384)))
	close_stone.albedo_color = Color("70717e")
	close_stone.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	close_stone.uv1_triplanar = true
	close_stone.uv1_world_triplanar = true
	close_stone.uv1_scale = Vector3(200.0 / 112.0, 200.0 / 384.0, 200.0 / 112.0)
	close_stone.set_meta("authored_texture", close_stone.albedo_texture)
	stage.materials.append(close_stone)
	iron = stage._material(Rect2(), Color("55576a"), "iron")
	brass = stage._material(Rect2(), Color("b29b71"), "brass")
	wood = stage._material(Rect2(), Color("776454"), "wood")
	roof = stage._material(Rect2(), Color("3f485e"), "iron")
	banner = stage._material(Rect2(365, 660, 150, 405), Color.WHITE)
	banner.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	banner.alpha_scissor_threshold = 0.2
	stained_glass = StandardMaterial3D.new()
	stained_glass.albedo_texture = load("res://assets/environments/crimson/chapel_window_v1.png")
	stained_glass.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	stained_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	stained_glass.alpha_scissor_threshold = 0.15
	stained_glass.emission_enabled = true
	stained_glass.emission_texture = stained_glass.albedo_texture
	stained_glass.emission = Color.WHITE
	stained_glass.emission_energy_multiplier = 0.16
	stained_glass.set_meta("authored_texture", stained_glass.albedo_texture)
	stage.materials.append(stained_glass)
	glass = stage._material(Rect2(), Color("b9894c"), "parchment")
	glass.emission_enabled = true
	glass.emission = Color("e6a75c")
	glass.emission_energy_multiplier = 0.45
	stage.night = NightBackdrop.new()
	stage.night.name = "NightBackdrop"
	stage.scenery.add_child(stage.night)
	for index in range(5, 10):
		stage.night.layer("CastleSilhouette%d" % (index + 1), preload("res://assets/environments/crimson/castle_v3.png"), Vector3(index * 20.0 + 10, -5.1, -9), 20.0 / 1536.0)
	for module in stage.game.environment.modules:
		_floor(module)
	for stair in stage.game.environment.stairs:
		_stair(stair)
	for record in stage.game.environment.structure_records:
		_structure(record)
	_local_rooms()
	_arrival_station()
	_crane()
	_garden()
	_gallery()
	_bell_landmark()
	_archive_and_stairwell()
	_close_facade_layers()
	stage.foreground = preload("res://scenes/rooms/image_monastery_foreground.tscn").instantiate()
	stage.scenery.add_child(stage.foreground)

func _masonry(tint: Color) -> StandardMaterial3D:
	var mat: StandardMaterial3D = stage._material(Rect2(668, 42, 128, 62), tint)
	mat.uv1_triplanar = true
	mat.uv1_world_triplanar = true
	mat.uv1_scale = Vector3(3.12, 6.44, 3.12)
	return mat

func _close_facade_layers() -> void:
	# Keep the authored landmark silhouette at distance. At actor height use
	# separate story modules at two source texels per logical pixel, matching
	# the actor compositor instead of magnifying an entire small tower image.
	var texture := preload("res://assets/environments/crimson/close_facade_bays_v1.png")
	var sources := [Rect2(0, 0, 512, 768), Rect2(512, 0, 448, 768), Rect2(960, 0, 576, 768), Rect2(1536, 0, 512, 768)]
	for module in stage.game.environment.modules:
		var id: String = module.get_meta("structural_id", "")
		if module.one_way or module.collision_depth > 80 or not module.unlock_action.is_empty(): continue
		var spans: Array[Vector2] = []
		var wall_z := -2.12
		if id in ["F08", "F09", "F10", "F11"] or module.get_meta("interior_backwall", false):
			spans.append(Vector2(module.position.x, module.position.x + module.width))
			wall_z = -1.23
		elif id == "F07":
			spans.append(Vector2(module.position.x, module.position.x + module.width))
			wall_z = -1.58
		else:
			for record in stage.game.environment.structure_records:
				if str(record.id) not in ["B01", "B02", "B12"]: continue
				var rect := _record_rect(record)
				if module.position.y < rect.position.y or module.position.y > rect.end.y + 16: continue
				var left := maxf(module.position.x, rect.position.x)
				var right := minf(module.position.x + module.width, rect.end.x)
				if right > left: spans.append(Vector2(left, right))
		for span in spans:
			var x := span.x
			var index := 0
			while x < span.y - 1:
				var source: Rect2 = sources[index % sources.size()]
				var width := minf(source.size.x * 0.5, span.y - x)
				source.size.x = width * 2.0
				var rect := Rect2(x, module.position.y - 384, width, 384)
				var windows: Array = []
				for pane in [Rect2(230, 177, 78, 224), Rect2(1104, 190, 104, 214), Rect2(1307, 189, 104, 216)]:
					if source.encloses(pane): windows.append(pane)
				var prefix := "%sCloseStory%d_%d" % [id, int(span.x), index]
				var wall := _paperboard_cutout(rect, texture, source, windows, wall_z, prefix + "Wall")
				wall.set_meta("logical_per_texel", 0.5)
				wall.set_meta("ground_y", module.position.y)
				for pane_source in windows:
					var pane_rect := _paper_detail_rect(rect, source, pane_source)
					_box(pane_rect, wall_z - 0.10, 0.025, roof, prefix + "WindowRecess")
					var pane := _paperboard(pane_rect, texture, pane_source, wall_z - 0.055, prefix + "WindowGlass")
					pane.set_meta("wall_z", wall_z)
					_layered_window_reveal(pane_rect, wall_z - 0.025, prefix + "Window")
				_box(Rect2(x, module.position.y - 4, width, 8), (wall_z - 1.175) * 0.5, absf(wall_z + 1.175) + 0.02, stone, prefix + "FoundationContact")
				x += width
				index += 1

func _box(rect: Rect2, z: float, depth: float, material: Material, label: String) -> MeshInstance3D:
	return stage._box(Vector3(rect.get_center().x * P, -rect.get_center().y * P, z), Vector3(rect.size.x * P, rect.size.y * P, depth), material, label)

func _beam(a: Vector2, b: Vector2, width: float, z: float, depth: float, mat: Material, label: String) -> MeshInstance3D:
	var middle := (a + b) * 0.5
	var node: MeshInstance3D = stage._box(Vector3(middle.x * P, -middle.y * P, z), Vector3(a.distance_to(b) * P, width * P, depth), mat, label)
	node.rotation.z = -(b - a).angle()
	return node

func _extrude(points: PackedVector2Array, z_back: float, z_front: float, mat: Material, label: String) -> MeshInstance3D:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var triangles := Geometry2D.triangulate_polygon(points)
	for z in [z_back, z_front]:
		for k in range(0, triangles.size(), 3):
			for j in ([2, 1, 0] if z == z_back else [0, 1, 2]):
				var point := points[triangles[k + j]]
				surface.set_uv(point * P)
				surface.add_vertex(Vector3(point.x * P, -point.y * P, z))
	for i in points.size():
		var a := points[i]
		var b := points[(i + 1) % points.size()]
		for v in [Vector3(a.x * P, -a.y * P, z_back), Vector3(b.x * P, -b.y * P, z_back), Vector3(b.x * P, -b.y * P, z_front), Vector3(a.x * P, -a.y * P, z_back), Vector3(b.x * P, -b.y * P, z_front), Vector3(a.x * P, -a.y * P, z_front)]:
			surface.set_uv(Vector2(v.x, v.y))
			surface.add_vertex(v)
	surface.generate_normals()
	var node := MeshInstance3D.new()
	node.name = label
	node.mesh = surface.commit()
	node.material_override = mat
	stage.scenery.add_child(node, true)
	return node

func _floor(module: PaperPlatform) -> void:
	var first: int = stage.scenery.get_child_count()
	var at: Vector2 = module.position
	var width: float = module.width
	var height: float = module.collision_depth
	var id: String = module.get_meta("structural_id", str(module.name))
	if module.has_meta("gate_id") and height > 80:
		for dx in [3.0, width - 9.0]:
			_box(Rect2(at + Vector2(dx, 0), Vector2(6, height)), -0.25, 1.85, iron, id + "PortcullisUpright")
		for y in range(0, ceili(height), 48):
			_box(Rect2(at + Vector2(0, y), Vector2(width, minf(8, height - y))), -0.25, 1.85, brass, id + "PortcullisCrossbar")
	elif module.one_way:
		for x in range(0, ceili(width), 12):
			_box(Rect2(at + Vector2(x, 0), Vector2(4, height)), -0.25, 1.1, iron, id + "GrateSlat")
		for z in [-0.8, 0.3]:
			_box(Rect2(at, Vector2(width, height)), z, 0.06, iron, id + "EdgeGirder")
	else:
		_box(Rect2(at, Vector2(width, height)), -0.25, 1.85, stone, id + "MasonryBody")
		_box(Rect2(at + Vector2(0, -0.2), Vector2(width, minf(height, 4))), -0.25, 1.87, paving, id + "Paving")
		# Moulding is below the contact line, so actors retain their full silhouettes.
		if height >= 12:
			_box(Rect2(at + Vector2(0, height - 5), Vector2(width, 5)), -0.25, 1.9, trim, id + "Cornice")
		if id.begins_with("F"):
			_box(Rect2(at, Vector2(width, height)), -2.15, 2.0, stone, id + "RearSupportSlab")
	if id == "F20":
		# F20 is open grating: the rear girder is z=-0.8, not the stone-floor
		# railing depth. Include the rail in this landing's active visual group.
		_rear_rail(at, at + Vector2(width, 0), id, -0.8)
	var pieces: Array[Node] = []
	for index in range(first, stage.scenery.get_child_count()):
		var piece: Node = stage.scenery.get_child(index)
		piece.visible = module.active
		pieces.append(piece)
	stage.platform_visuals[module] = pieces
	if not module.unlock_action.is_empty() or module.one_way or height > 80: return
	if id.begins_with("F"):
		# Foundation lives behind the cutaway tunnels, with a real depth and end faces.
		var bottom := 3520.0
		if at.y < bottom and id not in ["F06", "F07", "F12", "F13"]:
			_box(Rect2(at + Vector2(0, height), Vector2(width, bottom - at.y - height)), -3.35, 1.6, stone, id + "RearFoundation")
		elif id in ["F06", "F07", "F12", "F13"]:
			for x in [at.x + 12, at.x + width - 40]:
				var foot := _lower_floor(x, at.y + height)
				_box(Rect2(x, at.y + height, 28, foot - at.y - height), -1.45, 0.40, stone, id + "SupportedPier")
				_box(Rect2(x - 10, foot - 18, 48, 18), -1.45, 0.75, trim, id + "PierFoot")
		_rear_rail(at, at + Vector2(width, 0), id)

func _lower_floor(x: float, below: float) -> float:
	var floor_y := 3520.0
	for module in stage.game.environment.modules:
		if module.position.y <= below or module.one_way or module.has_meta("gate_id"): continue
		if x >= module.position.x and x <= module.position.x + module.width:
			floor_y = minf(floor_y, module.position.y)
	return floor_y

func stair_samples(start: Vector2, offset: Vector2, tread: float) -> Array:
	var samples: Array = []
	var count := maxi(1, maxi(ceili(absf(offset.x) / tread), ceili(absf(offset.y) / 12.0)))
	for i in count:
		var a := start + offset * (float(i) / count)
		var b := start + offset * (float(i + 1) / count)
		samples.append({"left": minf(a.x, b.x), "right": maxf(a.x, b.x), "y": (a.y + b.y) * 0.5})
	return samples

func _stair(stair: Node2D) -> void:
	var a: Vector2 = stair.position
	var b: Vector2 = a + stair.end_offset
	var id: String = stair.get_meta("structural_id", str(stair.name))
	var depth: float = stair.stair_depth
	var samples := stair_samples(a, stair.end_offset, stair.visual_tread)
	if stair.get("one_way"):
		# Open maintenance flights have visible daylight between narrow treads.
		# Two thin stringers carry them; a solid riser or skirt would lie about
		# the intentionally passable underside of the gameplay component.
		for step in samples:
			var tread_width: float = (step.right - step.left) * 0.58
			var x: float = (step.right + step.left - tread_width) * 0.5
			_box(Rect2(x, step.y, tread_width, 2.5), -0.25, 1.72, iron, id + "OpenTread")
			_box(Rect2(x, step.y - 0.1, 1.5, 1.0), -0.25, 1.72, brass, id + "OpenTreadNosing")
			for z in [-1.02, 0.52]:
				_box(Rect2((step.left + step.right) * 0.5 - 1, step.y + 2, 2, 5), z, 0.07, iron, id + "OpenTreadBracket")
		for z in [-1.02, 0.52]:
			_beam(a + Vector2(0, 5), b + Vector2(0, 5), 4, z, 0.07, iron, id + "OpenSideBeam")
		_rear_rail(a, b, id)
		return
	for step in samples:
		_box(Rect2(step.left, step.y, step.right - step.left + 0.05, depth), -0.25, 1.85, stone, id + "TreadRiser")
		_box(Rect2(step.left, step.y - 0.1, step.right - step.left + 0.05, 2), -0.25, 1.86, paving, id + "TreadCap")
	_extrude(PackedVector2Array([a + Vector2(0, 6), b + Vector2(0, 6), b + Vector2(0, depth), a + Vector2(0, depth)]), -1.175, 0.675, stone, id + "ClosedStringer")
	# The stair flight also needs an actual retaining wall behind it. Flat floor
	# foundations cannot cover the sloped interval between their endpoints.
	# Keep its front behind recessed facade glass and every playable surface.
	_extrude(PackedVector2Array([a + Vector2(0, -80), b + Vector2(0, -80), Vector2(b.x, 3520), Vector2(a.x, 3520)]), -3.9, -2.62, stone, id + "ContinuousRearFoundation")
	_extrude(PackedVector2Array([a + Vector2(0, 6), b + Vector2(0, 6), b + Vector2(0, depth + 12), a + Vector2(0, depth + 12)]), -2.7, -1.17, stone, id + "RearContactApron")
	# A low retaining parapet follows the flight, not a huge blank screen that
	# hides the approved facade. Its coping and end piers explain the structure.
	var close_wall := _extrude(PackedVector2Array([a + Vector2(0, -64), b + Vector2(0, -64), b + Vector2(0, depth + 16), a + Vector2(0, depth + 16)]), -1.7, -1.22, close_stone, id + "CloseStairBackwall")
	close_wall.set_meta("logical_per_texel", 0.5)
	close_wall.set_meta("height_above_flight", 64.0)
	_beam(a + Vector2(0, -64), b + Vector2(0, -64), 5, -1.44, 0.54, stone, id + "RetainingCoping")
	var supports := [0.0, 0.5, 1.0] if absf(b.x - a.x) > 800 else [0.0, 1.0]
	for t in supports:
		var foot: Vector2 = a.lerp(b, t)
		_box(Rect2(foot.x - 5, foot.y - 64, 10, depth + 80), -1.35, 0.3, stone, id + "RetainingPier")
	_rear_rail(a, b, id)
	# Uprights terminate at this stair's own stringer; never float over a gap.
	if maxf(a.y, b.y) > 1900 and id != "S10":
		_extrude(PackedVector2Array([a + Vector2(0, -224), b + Vector2(0, -224), b + Vector2(0, depth), a + Vector2(0, depth)]), -2.5, -1.25, stone, id + "TunnelBackwall")

func _rear_rail(a: Vector2, b: Vector2, id: String, depth: float = -0.99) -> void:
	var count := maxi(1, ceili(absf(b.x - a.x) / 72.0))
	for i in count + 1:
		var point := a.lerp(b, float(i) / count)
		_box(Rect2(point + Vector2(-2, -36), Vector2(4, 39)), depth, 0.055, iron, id + "RearRailPost")
	_beam(a - Vector2(0, 36), b - Vector2(0, 36), 3, depth, 0.07, brass, id + "RearRailCap")
	_beam(a - Vector2(0, 16), b - Vector2(0, 16), 2, depth, 0.04, iron, id + "RearRailTie")

func _source(rect: Rect2) -> Rect2:
	return Rect2(Vector2(rect.position.x * 8, 1120 + (rect.position.y - 430) * 8), rect.size * 8)

func _record_rect(record: Dictionary) -> Rect2:
	return Rect2(Vector2(record.position[0], record.position[1]), Vector2(record.size[0], record.size[1]))

func _paperboard(rect: Rect2, texture: Texture2D, source: Rect2, z: float, label: String) -> Sprite3D:
	var card := Sprite3D.new()
	card.name = label
	card.texture = texture
	card.region_enabled = true
	card.region_rect = source
	card.pixel_size = rect.size.x * P / source.size.x
	card.position = Vector3(rect.get_center().x * P, -rect.get_center().y * P, z)
	card.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	card.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	card.alpha_scissor_threshold = 0.15
	card.shaded = true
	card.modulate = Color(0.84, 0.85, 0.91)
	card.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	stage.scenery.add_child(card)
	return card

func _paperboard_cutout(rect: Rect2, texture: Texture2D, source: Rect2,
		holes: Array, z: float, label: String) -> MeshInstance3D:
	var x_edges: Array[float] = [source.position.x, source.end.x]
	var y_edges: Array[float] = [source.position.y, source.end.y]
	for hole_value in holes:
		var hole: Rect2 = hole_value.intersection(source)
		if not hole.has_area():
			continue
		x_edges.append(hole.position.x)
		x_edges.append(hole.end.x)
		y_edges.append(hole.position.y)
		y_edges.append(hole.end.y)
	x_edges.sort()
	y_edges.sort()
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var texture_size := Vector2(texture.get_size())
	for x_index in range(x_edges.size() - 1):
		for y_index in range(y_edges.size() - 1):
			var cell := Rect2(x_edges[x_index], y_edges[y_index],
				x_edges[x_index + 1] - x_edges[x_index], y_edges[y_index + 1] - y_edges[y_index])
			var removed := false
			for hole_value in holes:
				var hole: Rect2 = hole_value
				if hole.has_point(cell.get_center()):
					removed = true
					break
			if removed:
				continue
			var source_points := [cell.position, Vector2(cell.position.x, cell.end.y),
				cell.end, Vector2(cell.end.x, cell.position.y)]
			for point_index in [0, 1, 2, 0, 2, 3]:
				var source_point: Vector2 = source_points[point_index]
				var local_ratio := (source_point - source.position) / source.size
				var logical_point := rect.position + local_ratio * rect.size
				surface.set_normal(Vector3(0, 0, 1))
				surface.set_uv(source_point / texture_size)
				surface.add_vertex(Vector3(logical_point.x * P, -logical_point.y * P, z))
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	material.albedo_color = Color(0.84, 0.85, 0.91)
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	material.alpha_scissor_threshold = 0.15
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.set_meta("authored_texture", texture)
	stage.materials.append(material)
	var wall := MeshInstance3D.new()
	wall.name = label
	wall.mesh = surface.commit()
	wall.material_override = material
	wall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	stage.scenery.add_child(wall)
	return wall

func _paper_detail_rect(card_rect: Rect2, card_source: Rect2, detail_source: Rect2) -> Rect2:
	var scale := card_rect.size / card_source.size
	return Rect2(card_rect.position + (detail_source.position - card_source.position) * scale,
		detail_source.size * scale)

func _layered_windows(card_rect: Rect2, texture: Texture2D, card_source: Rect2,
		details: Array, wall_z: float, label: String) -> void:
	for index in details.size():
		var detail_source: Rect2 = details[index]
		var rect := _paper_detail_rect(card_rect, card_source, detail_source)
		var prefix := "%s%d" % [label, index]
		# The wall mesh omits this rectangle. A dark inner plane and the exact
		# authored crop sit behind it; slim reveals bridge the real depth gap.
		_box(rect.grow(-maxf(1.0, minf(rect.size.x, rect.size.y) * 0.02)),
			wall_z - 0.10, 0.025, roof, prefix + "Recess")
		var pane := _paperboard(rect, texture, detail_source, wall_z - 0.055, prefix + "Glass")
		pane.modulate = Color(0.98, 0.94, 0.92, 1.0)
		pane.set_meta("wall_z", wall_z)
		_layered_window_reveal(rect, wall_z - 0.025, prefix)
		_layered_window_frame(rect, wall_z + 0.02, prefix)

func _layered_window_reveal(rect: Rect2, z: float, label: String) -> void:
	var width := clampf(minf(rect.size.x, rect.size.y) * 0.02, 1.5, 4.0)
	for x in [rect.position.x, rect.end.x]:
		_box(Rect2(x - width * 0.5, rect.position.y, width, rect.size.y),
			z, 0.07, roof, label + "Reveal")
	_box(Rect2(rect.position.x, rect.position.y - width * 0.5, rect.size.x, width),
		z, 0.07, roof, label + "Reveal")
	_box(Rect2(rect.position.x, rect.end.y - width * 0.5, rect.size.x, width),
		z, 0.07, roof, label + "Reveal")

func _layered_window_frame(rect: Rect2, z: float, label: String) -> void:
	var thickness := clampf(minf(rect.size.x, rect.size.y) * 0.024, 1.5, 4.0)
	var shoulder_y := rect.position.y + rect.size.y * 0.28
	var apex := Vector2(rect.get_center().x, rect.position.y - thickness * 0.2)
	var left_shoulder := Vector2(rect.position.x, shoulder_y)
	var right_shoulder := Vector2(rect.end.x, shoulder_y)
	for x in [rect.position.x, rect.end.x]:
		_box(Rect2(x - thickness * 0.5, shoulder_y, thickness, rect.end.y - shoulder_y),
			z, 0.045, trim, label + "FrameJamb")
	_beam(left_shoulder, apex, thickness, z, 0.045, trim, label + "FrameArch")
	_beam(apex, right_shoulder, thickness, z, 0.045, trim, label + "FrameArch")
	_box(Rect2(rect.position.x - thickness * 0.6, rect.end.y - thickness * 0.15,
		rect.size.x + thickness * 1.2, thickness * 0.72), z + 0.02, 0.065, trim, label + "FrameSill")

func _structure(record: Dictionary) -> void:
	var rect := _record_rect(record)
	var id: String = record.id
	match id:
		"B01": _gatehouse_landmark(rect)
		"B12": _hall_landmark(rect)
		"B02":
			var texture := preload("res://assets/environments/crimson/gatehouse_facade_v1.png")
			var source := Rect2(156, 0, 713, 1536)
			var window_sources := [
				Rect2(458, 458, 58, 76), Rect2(700, 280, 90, 192), Rect2(716, 805, 64, 190)
			]
			_paperboard_cutout(rect, texture, source, window_sources, -2.48, id + "PaintedCargoHouse")
			_layered_windows(rect, texture, source, window_sources, -2.48, "B02LayeredWindow")
		"B03", "B08", "B09", "B13":
			_box(rect, -2.25, 1.4, stone, id + "FoundationBackwall")
		"B04", "B05":
			# This backing still touches the real landing corbels; the visible
			# buttresses, windows and roof are a single authored paper facade.
			_box(rect, -2.8, 1.0, stone, id + "TowerPier")
			var source := Rect2(430, 0, 159, 1536) if id == "B04" else Rect2(590, 0, 109, 1536)
			_paperboard(rect, preload("res://assets/environments/crimson/bell_pier_facade_v1.png"), source, -2.28, id + "PaintedTowerPier")
		"B06":
			_box(Rect2(rect.position, Vector2(rect.size.x, 24)), -2.0, 1.3, trim, id + "BellSuspensionBeam")
			_box(Rect2(rect.position + Vector2(0, -26), Vector2(rect.size.x, 26)), -2.0, 1.5, stone, id + "BeamCoping")
		"B07": _bell(rect, id)
		"B10":
			# The drawing has a long shallow glazed lean-to, not a triangular gable.
			var glazing: StandardMaterial3D = stage._material(Rect2(), Color("718697"), "iron")
			glazing.roughness = 0.28
			_sloping_canopy(rect, glazing)
			_box(Rect2(rect.position, Vector2(rect.size.x, 18)), -3.6, 0.18, trim, "B10UpperRoofRail")
			_box(Rect2(rect.position.x - 120, rect.end.y, rect.size.x + 120, 18), -1.61, 0.18, iron, "B10EavesGutter")
		"B11":
			_arch(rect, -1.9, 0.65, 32, trim, id + "GateArch")
		"B14":
			# The large chapel pane is painted into the B12 elevation. A second
			# glass card would double the tracery at a different depth.
			pass
		"B15":
			# The construction plan adds the archive landing at y880. Its cabinet
			# must share that real support, not float at the source sketch's y832.
			_shelves(Rect2(6672, 296, 384, 584), id)
		"B16", "B17": _tank(rect, id)

func _window(rect: Rect2, id: String) -> void:
	_extrude(_arch_outline(rect), -2.49, -2.47, glass, id + "RecessedWindow")
	_arch(rect, -2.38, 0.14, 7, trim, id + "WindowFrame")
	_box(Rect2(rect.get_center().x - 2, rect.position.y + 28, 4, rect.size.y - 28), -2.30, 0.04, brass, id + "WindowMullion")
	_box(Rect2(rect.position.x - 5, rect.end.y, rect.size.x + 10, 8), -2.27, 0.32, trim, id + "WindowSill")
	_warm_window_light(rect.get_center(), clampf(rect.size.y * P, 1.4, 4.0), 0.58, id)

func _warm_window_light(at: Vector2, radius: float, energy: float, label: String) -> void:
	var light := OmniLight3D.new()
	light.name = label + "WindowLight"
	light.position = Vector3(at.x * P, -at.y * P, -1.65)
	light.light_color = Color("ffd18b")
	light.light_energy = energy
	light.omni_range = radius
	stage.scenery.add_child(light, true)

func _arch(rect: Rect2, z: float, depth: float, width: float, mat: Material, id: String) -> void:
	var shoulder := rect.position.y + rect.size.y * 0.34
	for x in [rect.position.x, rect.end.x]:
		_box(Rect2(x - width / 2, shoulder, width, rect.end.y - shoulder), z, depth, mat, id + "Jamb")
	var previous := Vector2(rect.position.x, shoulder)
	for i in range(1, 13):
		var t := float(i) / 12
		var point := Vector2(rect.position.x + rect.size.x * t, shoulder - _ogive(t) * rect.size.y * 0.34)
		_beam(previous, point, width, z, depth, mat, id + "Voussoir")
		previous = point

func _ogive(t: float) -> float:
	return sin(minf(t, 1.0 - t) * 2.0 * PI / 3.0) / sin(PI / 3.0)

func _arch_outline(rect: Rect2) -> PackedVector2Array:
	var points := PackedVector2Array()
	var shoulder := rect.position.y + rect.size.y * 0.34
	for i in 13:
		var t := float(i) / 12
		points.append(Vector2(rect.position.x + rect.size.x * t, shoulder - _ogive(t) * rect.size.y * 0.34))
	points.append(rect.end)
	points.append(Vector2(rect.position.x, rect.end.y))
	return points

func _roof(at: Vector2, width: float, rise: float, id: String) -> void:
	_extrude(PackedVector2Array([at, at + Vector2(width / 2, -rise), at + Vector2(width, 0), at + Vector2(width, 24), at + Vector2(0, 24)]), -4.4, -1.65, roof, id + "PitchedRoof")
	_beam(at, at + Vector2(width / 2, -rise), 16, -1.6, 0.20, trim, id + "GableTrim")
	_beam(at + Vector2(width / 2, -rise), at + Vector2(width, 0), 16, -1.6, 0.20, trim, id + "GableTrim")
	_box(Rect2(at + Vector2(0, 16), Vector2(width, 18)), -2.6, 2.15, trim, id + "RoofCornice")

func _bell(rect: Rect2, id: String) -> void:
	var top := Vector2(rect.get_center().x, rect.position.y)
	_box(Rect2(top - Vector2(12, 160), Vector2(24, 174)), -1.9, 0.24, iron, id + "VisibleHanger")
	var bronze: StandardMaterial3D = stage._material(Rect2(), Color("606c76"), "brass")
	var profile := [Vector2(0, 0.20), Vector2(0.12, 0.28), Vector2(0.30, 0.30), Vector2(0.60, 0.32), Vector2(0.79, 0.39), Vector2(0.88, 0.48), Vector2(0.94, 0.49), Vector2(1.0, 0.48)]
	for i in range(profile.size() - 1):
		var upper: Vector2 = profile[i]
		var lower: Vector2 = profile[i + 1]
		var y: float = rect.position.y + rect.size.y * (upper.x + lower.x) * 0.5
		stage._cylinder(Vector3(top.x * P, -y * P, -2.0), rect.size.x * P * lower.y, rect.size.x * P * upper.y, rect.size.y * P * (lower.x - upper.x), bronze, id + "CurvedBellBody")
	stage.bell_clapper = _box(Rect2(top.x - 10, rect.end.y - 90, 20, 110), -1.85, 0.20, iron, id + "Clapper")

func _shelves(rect: Rect2, id: String) -> void:
	_box(rect, -1.75, 0.8, wood, id + "CabinetBack")
	for y in range(int(rect.position.y + 40), int(rect.end.y), 80):
		_box(Rect2(rect.position.x, y, rect.size.x, 8), -1.46, 0.72, wood, id + "Shelf")
		for x in range(int(rect.position.x + 12), int(rect.end.x - 12), 20):
			_box(Rect2(x, y - 42, 13, 42), -1.32, 0.23, brass if posmod(x, 3) == 0 else wood, id + "BookSpine")
	for x in [rect.position.x, rect.end.x - 12]:
		_box(Rect2(x, rect.position.y, 12, rect.size.y), -1.45, 0.72, wood, id + "CabinetUpright")

func _tank(rect: Rect2, id: String) -> void:
	var center := rect.get_center()
	for x in [rect.position.x + 30, rect.end.x - 50]:
		_box(Rect2(x, rect.end.y - 24, 20, 40), -1.7, 0.55, iron, id + "TankSaddle")
	stage._cylinder(Vector3(center.x * P, -(center.y - 12) * P, -2.0), rect.size.x * P * 0.40, rect.size.x * P * 0.32, (rect.size.y - 24) * P, brass, id + "PressureVessel")
	for y in [rect.position.y + 80, rect.end.y - 90]:
		stage._cylinder(Vector3(center.x * P, -y * P, -2.0), rect.size.x * P * 0.41, rect.size.x * P * 0.41, 0.12, iron, id + "TankBand")
	_box(Rect2(center.x - 12, rect.position.y - 68, 24, 72), -2.0, 0.24, iron, id + "PipeToFlange")
	_box(Rect2(center.x - 25, rect.position.y - 5, 50, 12), -2.0, 0.50, brass, id + "Flange")

func _local_rooms() -> void:
	for module in stage.game.environment.modules:
		var id: String = module.get_meta("structural_id", "")
		if id not in ["F08", "F09", "F10", "F11"] and not module.get_meta("interior_backwall", false): continue
		var at: Vector2 = module.position
		var width: float = module.width
		# Keep the structural backing behind the cut paper facade's recessed
		# glass. Its thickness still closes the room and supports the road.
		_box(Rect2(at - Vector2(0, 256), Vector2(width, 260)), -2.25, 1.65, stone, id + "InteriorBackwall")
		# A painted frontage replaces the repeated box-built tunnel ribs. The
		# supporting wall and the actual road remain 3D.
		var painted_height := width * 724.0 / 2172.0
		var painting: Texture2D = preload("res://assets/environments/crimson/chapel_facade_v1.png") if id == "F11" else preload("res://assets/environments/crimson/industrial_facade_v1.png")
		var card_rect := Rect2(at - Vector2(0, painted_height), Vector2(width, painted_height))
		var card_source := Rect2(0, 0, 2172, 724)
		var window_sources := [
			Rect2(622, 205, 345, 510), Rect2(1400, 338, 92, 315), Rect2(2034, 318, 130, 350)
		] if id == "F11" else [
			Rect2(102, 95, 185, 322), Rect2(700, 108, 238, 267), Rect2(1470, 266, 105, 202)
		]
		_paperboard_cutout(card_rect, painting, card_source, window_sources,
			-1.26, id + "PaintedServiceFrontage")
		_layered_windows(card_rect, painting, card_source, window_sources,
			-1.26, id + "LayeredWindow")
	_cargo_setdress()

func _cargo_setdress() -> void:
	# The lower halls were visually empty between architectural ribs. Place a
	# few textured, non-colliding freight groups on real floor spans, behind the
	# rear railing. Keep their centers away from interaction/checkpoint markers.
	for group in [
		{"id":"WestCargo", "x":4070.0, "floor":2280.0},
		{"id":"EastCargo", "x":5420.0, "floor":2280.0},
		{"id":"HallStoresWest", "x":12960.0, "floor":2720.0},
		{"id":"HallStoresEast", "x":15160.0, "floor":2720.0},
	]:
		var x: float = group.x
		var floor_y: float = group.floor
		var label: String = group.id
		_box(Rect2(x, floor_y - 60, 72, 60), -1.17, 0.15, wood, label + "CargoCrateBase")
		_box(Rect2(x + 76, floor_y - 48, 58, 48), -1.17, 0.15, wood, label + "CargoCrateSide")
		_box(Rect2(x + 8, floor_y - 100, 62, 40), -1.16, 0.16, wood, label + "CargoCrateUpper")
		for y in [floor_y - 58, floor_y - 7]:
			_box(Rect2(x, y, 72, 4), -1.08, 0.08, iron, label + "CargoCrateBand")
		for edge in [x + 4, x + 65]:
			_box(Rect2(edge, floor_y - 56, 3, 52), -1.08, 0.08, brass, label + "CargoCrateReinforcement")
		var barrel_x := x + 170
		stage._cylinder(Vector3(barrel_x * P, -(floor_y - 27) * P, -1.17), 0.25, 0.25, 0.54, wood, label + "CargoBarrel")
		for y in [floor_y - 12, floor_y - 42]:
			stage._cylinder(Vector3(barrel_x * P, -y * P, -1.17), 0.26, 0.26, 0.04, iron, label + "CargoBarrelHoop")

func _lamp(at: Vector2, id: String) -> void:
	_box(Rect2(at - Vector2(4, 0), Vector2(8, 18)), -1.30, 0.12, brass, id + "SconceMount")
	_box(Rect2(at - Vector2(6, 22), Vector2(12, 24)), -1.21, 0.16, glass, id + "Lantern")
	# A few warm pools preserve the cold stone hierarchy; avoid one light per step.
	var light := OmniLight3D.new()
	light.name = id + "Lamplight"
	light.position = Vector3(at.x * P, -(at.y - 10) * P, -0.85)
	light.light_color = Color("ffc186")
	light.light_energy = 0.65
	light.omni_range = 2.6
	stage.scenery.add_child(light, true)

func _arrival_station() -> void:
	var rect := _source(Rect2(18, 320, 164, 110))
	var depot_texture := preload("res://assets/environments/crimson/industrial_facade_v1.png")
	var depot_source := Rect2(0, 0, 1086, 724)
	var depot_windows := [Rect2(102, 95, 185, 322), Rect2(700, 108, 238, 267)]
	# A drawn depot replaces the former full-screen timber slab. The shallow
	# masonry footing is behind the paper elevation; posts and roof remain real.
	_box(Rect2(rect.position.x, rect.end.y - 112, rect.size.x, 112), -3.55, 0.36,
		stone, "StationRearFoundation")
	_paperboard_cutout(rect, depot_texture, depot_source, depot_windows, -3.2, "StationPaintedDepot")
	_layered_windows(rect, depot_texture, depot_source, depot_windows, -3.2, "StationLayeredWindow")
	_roof(rect.position - Vector2(32, 0), rect.size.x + 64, 128, "Station")
	for x in [rect.position.x + 30, rect.end.x - 48]:
		_box(Rect2(x, rect.position.y, 18, rect.size.y), -1.42, 0.28, wood, "StationSupportedPost")
		_box(Rect2(x - 12, rect.end.y - 24, 42, 24), -1.42, 0.50, stone, "StationPostFoot")
	for x in range(int(rect.position.x + 180), int(rect.end.x), 300):
		_lamp(Vector2(x, rect.end.y - 95), "Station")
		_box(Rect2(x - 45, rect.end.y - 22, 90, 8), -1.38, 0.3, wood, "StationBench")
		for leg in [-36, 36]:
			_box(Rect2(x + leg, rect.end.y - 14, 6, 14), -1.38, 0.24, iron, "StationBenchLeg")
	_station_carriage()

func _station_carriage() -> void:
	# The carriage belongs to the arrival platform, not to its paper backdrop.
	# Its body, roof, axle and wheel faces have real depth; every part samples a
	# wood, metal, brass or stone texture already used by this scene.
	var ground := 1120.0
	_box(Rect2(1154, 1015, 218, 76), -0.84, 0.64, wood, "StationCarriageBody")
	_box(Rect2(1150, 1007, 226, 10), -0.48, 0.72, brass, "StationCarriageUpperBand")
	_box(Rect2(1160, 980, 208, 25), -0.84, 0.75, roof, "StationCarriageCanopy")
	_box(Rect2(1156, 978, 216, 6), -0.47, 0.78, brass, "StationCarriageRoofLip")
	for x in [1160.0, 1360.0]:
		_box(Rect2(x, 1001, 9, 49), -0.47, 0.14, brass, "StationCarriageCanopyPost")
	for x in [1180.0, 1285.0]:
		_box(Rect2(x, 1024, 71, 42), -0.47, 0.09, roof, "StationCarriageWindowRecess")
		_box(Rect2(x - 4, 1021, 79, 5), -0.39, 0.10, brass, "StationCarriageWindowHead")
		_box(Rect2(x - 4, 1066, 79, 5), -0.39, 0.10, brass, "StationCarriageWindowSill")
	_box(Rect2(1148, 1086, 231, 8), -0.43, 0.18, iron, "StationCarriageAxleFrame")
	_beam(Vector2(1373, 1083), Vector2(1432, 1100), 7, -0.60, 0.15, iron, "StationCarriageHitch")
	for wheel_index in 2:
		var x := 1202.0 if wheel_index == 0 else 1328.0
		var wheel: MeshInstance3D = stage._cylinder(Vector3(x * P, -(ground - 28) * P, -0.37), 0.28, 0.28, 0.08, iron, "StationCarriageWheel%d" % (wheel_index + 1))
		wheel.rotation.x = PI * 0.5
		for arc in 16:
			var center := Vector2(x, ground - 28)
			var a := center + Vector2.from_angle(TAU * arc / 16.0) * 27
			var b := center + Vector2.from_angle(TAU * (arc + 1) / 16.0) * 27
			_beam(a, b, 3, -0.29, 0.05, brass, "StationCarriageWheelRim")
		for spoke in 8:
			var angle := TAU * spoke / 8.0
			_beam(Vector2(x, ground - 28), Vector2(x, ground - 28) + Vector2.from_angle(angle) * 23, 3, -0.30, 0.05, brass, "StationCarriageWheelSpoke")
		_box(Rect2(x - 5, ground - 33, 10, 10), -0.25, 0.10, trim, "StationCarriageWheelHub")

func _crane() -> void:
	var base := _source_point(Vector2(527, 466))
	var head := _source_point(Vector2(527, 120))
	_box(Rect2(base - Vector2(72, 30), Vector2(144, 30)), -2.0, 1.1, stone, "CraneFooting")
	for side in [-1, 1]:
		_beam(base + Vector2(side * 50, -20), head + Vector2(side * 18, 0), 18, -2.0, 0.18, iron, "CraneLatticeLeg")
	for y in range(int(head.y + 80), int(base.y - 60), 144):
		_beam(Vector2(base.x - 38, y), Vector2(base.x + 38, y + 144), 8, -2.0, 0.1, iron, "CraneCrossBrace")
	var end := _source_point(Vector2(676, 148))
	var heel := _source_point(Vector2(480, 220))
	_beam(heel, end, 18, -2.0, 0.22, iron, "CraneBoom")
	_beam(heel + Vector2(0, 40), end + Vector2(0, 40), 12, -2.0, 0.20, iron, "CraneBoomLowerChord")
	for i in 18:
		_beam(heel.lerp(end, float(i) / 18), heel.lerp(end, float(i + 1) / 18) + Vector2(0, 40), 5, -2.0, 0.08, brass, "CraneBoomTruss")
	_beam(head, end, 7, -2.0, 0.08, brass, "CraneBoomStay")
	_beam(end, end + Vector2(0, 768), 5, -2.0, 0.08, iron, "CraneHangingCable")
	_box(Rect2(end + Vector2(-128, 768), Vector2(256, 192)), -2.0, 0.85, wood, "CraneSuspendedCargo")

func _garden() -> void:
	# Five complete window bays are present in the accepted generated sheet.
	# Preserve the sheet's actual proportions rather than stretching to old poles.
	var painting := preload("res://assets/environments/crimson/garden_facade_v2.png")
	var source := Rect2(20, 15, 2132, 681)
	var height := 1832.0 * source.size.y / source.size.x
	var facade := Rect2(10000, 1424 - height, 1832, height)
	var windows := [Rect2(107, 302, 331, 299), Rect2(514, 302, 328, 299), Rect2(921, 302, 329, 299), Rect2(1328, 302, 329, 299), Rect2(1736, 302, 329, 299)]
	_paperboard_cutout(facade, painting, source, windows, -2.48, "GardenPaintedFacade")
	_layered_windows(facade, painting, source, windows, -2.48, "GardenLayeredWindow")
	_box(Rect2(10000, 1418, 1832, 6), -2.52, 0.85, stone, "GardenFacadeFooting")
	# Re-seat the existing real lean-to roof on the authored eave. The old
	# scaffold was over twice the illustration height, leaving an empty canopy.
	for piece in stage.scenery.get_children():
		if str(piece.name).begins_with("B10TrueSlopedCanopy") or str(piece.name).begins_with("B10SlopedGlazingRafter") or str(piece.name) in ["B10UpperRoofRail", "B10EavesGutter"]:
			stage.scenery.remove_child(piece)
			piece.free()
	var roof_top := facade.position.y + 92.0 * height / source.size.y
	var roof_bottom := facade.position.y + 232.0 * height / source.size.y
	_sloping_canopy(Rect2(10000, roof_top, 1832, roof_bottom - roof_top), roof)
	_box(Rect2(10000, roof_bottom, 1832, 8), -1.61, 0.10, iron, "GardenAuthoredEaves")
	var rect := Rect2(10000, roof_bottom, 1832, 1424 - roof_bottom)
	for x in range(int(rect.position.x), int(rect.end.x), 320):
		_box(Rect2(x, rect.position.y, 16, rect.size.y), -1.45, 0.3, iron, "GardenCanopyColumn")
		_box(Rect2(x - 10, rect.end.y - 20, 36, 20), -1.45, 0.75, stone, "GardenColumnFoot")
		var rear_top := roof_top
		_box(Rect2(x, rear_top, 16, rect.end.y - rear_top), -3.6, 0.20, iron, "GardenRearCanopyColumn")
		_box(Rect2(x - 12, rect.end.y - 20, 40, 20), -3.4, 0.6, stone, "GardenRearColumnSupportedFoot")
	for x in range(10100, 11500, 288):
		_box(Rect2(x, 1398, 100, 26), -0.86, 0.40, stone, "GardenPlanter")
		var rose := Sprite3D.new()
		rose.name = "GardenAuthoredRose"
		rose.texture = preload("res://assets/environments/crimson/rose_bush_v1.png")
		rose.pixel_size = 0.0006
		var opaque := rose.texture.get_image().get_used_rect()
		var bottom_offset := (opaque.end.y - rose.texture.get_height() * 0.5) * rose.pixel_size
		rose.position = Vector3((x + 50) * P, -1398 * P + bottom_offset, -0.87)
		rose.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		rose.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		stage.scenery.add_child(rose)

func _gallery() -> void:
	for module in stage.game.environment.modules:
		if module.get_meta("structural_id", "") != "F07" or module.one_way: continue
		var at: Vector2 = module.position
		var width: float = module.width
		var painted_height := width * 724.0 / 2172.0
		var texture := preload("res://assets/environments/crimson/industrial_facade_v1.png")
		var card_rect := Rect2(at - Vector2(0, painted_height), Vector2(width, painted_height))
		var source := Rect2(0, 0, 2172, 724)
		var window_sources := [
			Rect2(102, 95, 185, 322), Rect2(700, 108, 238, 267), Rect2(1470, 266, 105, 202),
			Rect2(2034, 96, 126, 304)
		]
		_paperboard_cutout(card_rect, texture, source, window_sources, -1.65, "GalleryPaintedFrontage")
		_layered_windows(card_rect, texture, source, window_sources, -1.65, "GalleryLayeredWindow")

func _source_point(point: Vector2) -> Vector2:
	return Vector2(point.x * 8.0, 1120 + (point.y - 430) * 8.0)

func _pointed_arch(rect: Rect2, crown: float, z: float, depth: float, thickness: float, label: String) -> void:
	var shoulder := rect.position.y + crown
	for x in [rect.position.x, rect.end.x]:
		_box(Rect2(x - thickness * 0.5, shoulder, thickness, rect.end.y - shoulder), z, depth, trim, label + "Jamb")
	var previous := Vector2(rect.position.x, shoulder)
	for i in range(1, 25):
		var t := float(i) / 24.0
		var point := Vector2(lerpf(rect.position.x, rect.end.x, t), shoulder - _ogive(t) * crown)
		_beam(previous, point, thickness, z, depth, trim, label + "ArchStone")
		previous = point

func _flag(source_rect: Rect2, z: float, label: String) -> void:
	var rect := _source(source_rect)
	var node := MeshInstance3D.new()
	node.name = label
	var mesh := QuadMesh.new()
	mesh.size = rect.size * P
	node.mesh = mesh
	node.position = Vector3(rect.get_center().x * P, -rect.get_center().y * P, z)
	node.material_override = banner
	stage.scenery.add_child(node)
	# The drawn pole is carried by two real wall brackets.
	for x in [rect.position.x + 20, rect.end.x - 20]:
		_box(Rect2(x, rect.position.y + 14, 12, 14), z - 0.13, 0.34, brass, label + "WallBracket")

func _ring(center: Vector2, radius: float, width: float, z: float, label: String) -> void:
	for i in 48:
		var a := center + Vector2.from_angle(TAU * i / 48.0) * radius
		var b := center + Vector2.from_angle(TAU * (i + 1) / 48.0) * radius
		_beam(a, b, width, z, 0.18, trim, label)

func _rose_window(source_center: Vector2, source_radius: float, z: float, label: String) -> void:
	var center := _source_point(source_center)
	var radius := source_radius * 8.0
	var disk: MeshInstance3D = stage._cylinder(Vector3(center.x * P, -center.y * P, z - 0.14), radius * P, radius * P, 0.05, roof, label + "Recess")
	disk.rotation.x = PI * 0.5
	# Circular geometry samples only the authored rose, never a rectangular card.
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var texture_size := Vector2(stained_glass.albedo_texture.get_size())
	for i in 48:
		for direction in [Vector2.ZERO, Vector2.from_angle(TAU * i / 48.0), Vector2.from_angle(TAU * (i + 1) / 48.0)]:
			surface.set_uv((Vector2(407, 325) + direction * 143) / texture_size)
			var point: Vector2 = center + direction * radius * 0.86
			surface.add_vertex(Vector3(point.x * P, -point.y * P, z - 0.05))
	surface.generate_normals()
	var pane := MeshInstance3D.new()
	pane.name = label + "AuthoredRoseGlass"
	pane.mesh = surface.commit()
	pane.material_override = stained_glass
	stage.scenery.add_child(pane)
	_ring(center, radius, 12, z, label + "OuterRoseFrame")
	_ring(center, radius * 0.85, 6, z + 0.02, label + "InnerRoseFrame")
	_ring(center, radius * 0.19, 6, z + 0.06, label + "RoseHeart")
	for i in 8:
		var direction := Vector2.from_angle(TAU * i / 8.0)
		_ring(center + direction * radius * 0.52, radius * 0.25, 5, z + 0.05, label + "PetalTracery")
		_beam(center + direction * radius * 0.2, center + direction * radius * 0.84, 5, z + 0.04, 0.12, trim, label + "RadialTracery")

func _pinnacle(source_at: Vector2, width: float, rise: float, label: String) -> void:
	var at := _source_point(source_at)
	_roof(at - Vector2(width * 4, 0), width * 8, rise * 8, label)
	_box(Rect2(at - Vector2(5, rise * 8 + 28), Vector2(10, 40)), -1.6, 0.1, iron, label + "Finial")

func _bell_landmark() -> void:
	var arch := _source(Rect2(944, 114, 172, 388))
	_pointed_arch(arch, 52 * 8, -1.54, 0.94, 80, "BellGreatOpening")
	_pointed_arch(arch.grow(40), 59 * 8, -1.69, 0.80, 24, "BellOuterArchivolt")
	# Solid pierced-gable construction remains above the bell opening.
	var left := _source_point(Vector2(946, 109))
	var apex := _source_point(Vector2(1027, 33))
	var right := _source_point(Vector2(1115, 109))
	_extrude(PackedVector2Array([left, apex, right]), -3.2, -1.8, stone, "BellGableMasonry")
	_beam(left, apex, 28, -1.57, 0.36, trim, "BellGableRakingCornice")
	_beam(apex, right, 28, -1.57, 0.36, trim, "BellGableRakingCornice")
	_rose_window(Vector2(1027, 77), 21, -1.43, "BellGable")
	_pinnacle(Vector2(1027, 33), 10, 28, "BellCentralFinial")
	for source_x in [906.0, 1138.0]:
		_flag(Rect2(source_x - 14, 121, 28, 146), -1.08, "BellLongBanner" + str(source_x))
		for y in [84.0, 290.0, 392.0]:
			_box(_source(Rect2(source_x - 26, y, 52, 7)), -1.56, 0.58, trim, "BellPierProjectingCapital")
	# Small open belfry beneath each spire, matching the paired towers.
	for source_x in [911.0, 1140.0]:
		_box(_source(Rect2(source_x - 24, 58, 48, 26)), -2.2, 1.0, stone, "BellUpperBelfry")
		for dx in [-13.0, 4.0]:
			_window(_source(Rect2(source_x + dx, 62, 9, 18)), "BellBelfryLancet")
	for point in [Vector2(939, 480), Vector2(1118, 480)]:
		_lamp(_source_point(point), "BellCourt")

func _gatehouse_landmark(record_rect: Rect2) -> void:
	# Masonry backing and real passage preserve depth, but the distinctive
	# roof, windows, banners and stonework come from one painted elevation.
	_box(Rect2(record_rect.position.x, 1200, record_rect.size.x, record_rect.end.y - 1200), -3.6, 2.2, stone, "B01LowerGatehouseMasonry")
	var painted_height := record_rect.size.x * 1536.0 / 1024.0
	var texture := preload("res://assets/environments/crimson/gatehouse_facade_v1.png")
	var card_rect := Rect2(record_rect.position.x, record_rect.position.y,
		record_rect.size.x, painted_height)
	var source := Rect2(0, 0, 1024, 1536)
	var window_sources := [
		Rect2(144, 662, 88, 190), Rect2(455, 456, 64, 80), Rect2(697, 280, 94, 194),
		Rect2(712, 804, 72, 192), Rect2(873, 518, 78, 146)
	]
	_paperboard_cutout(card_rect, texture, source, window_sources, -2.48, "B01PaintedGatehouse")
	_layered_windows(card_rect, texture, source, window_sources, -2.48, "B01LayeredWindow")
	_pointed_arch(_source(Rect2(331, 327, 52, 103)), 28 * 8, -1.80, 0.65, 35, "B01StreetPassage")
	for point in [Vector2(204, 403), Vector2(321, 273), Vector2(384, 400)]:
		_lamp(_source_point(point), "B01Portal")

func _hall_landmark(record_rect: Rect2) -> void:
	# The illustrated facade defines the full upper silhouette. Only the
	# below-grade foundation needs masonry thickness under the pitched camera.
	_box(Rect2(record_rect.position.x, record_rect.end.y,
		record_rect.size.x, 420), -3.6, 2.2, stone, "B12ContinuedFoundation")
	var painted_height := record_rect.size.x
	var hall_texture := preload("res://assets/environments/crimson/chapel_grand_facade_v2.png")
	var hall_rect := Rect2(record_rect.position.x, record_rect.end.y - painted_height,
		record_rect.size.x, painted_height)
	var hall_source := Rect2(0, 0, 1254, 1254)
	var window_sources := [
		Rect2(488, 460, 105, 284), Rect2(586, 458, 112, 288), Rect2(694, 460, 102, 284),
		Rect2(112, 844, 126, 235), Rect2(1016, 844, 126, 235)
	]
	_paperboard_cutout(hall_rect, hall_texture, hall_source, window_sources, -2.48, "B12PaintedGreatHall")
	_layered_windows(hall_rect, hall_texture, hall_source, window_sources, -2.48, "B12LayeredWindow")
	# The closer, higher-resolution lower wing keeps actor-height masonry from
	# becoming coarse when the complete silhouette is viewed at gun distance.
	var lower_height := record_rect.size.x * 324.0 / 2172.0
	_paperboard(Rect2(record_rect.position.x, record_rect.end.y - lower_height,
		record_rect.size.x, lower_height),
		preload("res://assets/environments/crimson/industrial_facade_v1.png"),
		Rect2(0, 400, 2172, 324), -2.44, "B12PaintedLowerWing")
	for point in [Vector2(1646, 401), Vector2(1708, 439), Vector2(1846, 439), Vector2(1934, 401)]:
		_lamp(_source_point(point), "B12HallWall")

func _archive_and_stairwell() -> void:
	var archive_rect := _source(Rect2(792, 204, 99, 298))
	_box(archive_rect, -3.65, 2.3, stone, "ArchiveSideHouseRearMasonry")
	_paperboard(archive_rect, preload("res://assets/environments/crimson/gatehouse_facade_v1.png"),
		Rect2(200, 0, 510, 1536), -2.48, "ArchivePaintedSideHouse")
	_roof(_source_point(Vector2(784, 204)), 115 * 8, 45 * 8, "ArchiveSideHouseRoof")
	for source_x in [794.0, 881.0]:
		_box(_source(Rect2(source_x, 209, 10, 293)), -2.15, 0.52, trim, "ArchiveHouseButtress")
	for y in [287.0, 401.0]:
		_box(_source(Rect2(790, y, 104, 9)), -2.04, 0.68, trim, "ArchiveHouseBalconyCornice")
	_pointed_arch(_source(Rect2(809, 218, 67, 67)), 26 * 8, -2.12, 0.4, 28, "ArchiveUpperReadingWindow")
	_window(_source(Rect2(820, 230, 44, 52)), "ArchiveReadingGlass")
	_pointed_arch(_source(Rect2(803, 314, 79, 85)), 25 * 8, -1.24, 0.22, 24, "ArchiveCabinetRoom")
	_pointed_arch(_source(Rect2(814, 427, 55, 75)), 25 * 8, -2.12, 0.4, 28, "ArchiveGroundPortal")
	for at in [Vector2(808, 269), Vector2(876, 385), Vector2(877, 476)]:
		_lamp(_source_point(at), "ArchiveHouse")
	var stairwell_rect := _source(Rect2(1152, 165, 98, 347))
	_box(stairwell_rect, -3.45, 2.1, stone, "BellStairwellRearMasonry")
	_paperboard(stairwell_rect, preload("res://assets/environments/crimson/bell_pier_facade_v1.png"),
		Rect2(300, 0, 434, 1536), -2.39, "BellStairwellPaintedFacade")
	_roof(_source_point(Vector2(1149, 165)), 106 * 8, 53 * 8, "BellStairwellRoof")
	for source_x in [1153.0, 1243.0]:
		_box(_source(Rect2(source_x, 166, 7, 346)), -2.26, 0.42, trim, "BellStairwellRearPier")
	# Actual scene landings determine support and lamp positions after route edits.
	for module in stage.game.environment.modules:
		if module.get_meta("structural_id", "") != "F20": continue
		var at: Vector2 = module.position
		# Reach from inside the rear wall (-2.4) into the grating girder (-0.83).
		_box(Rect2(at + Vector2(0, module.collision_depth), Vector2(module.width, 16)), -1.6, 1.7, trim, "BellStairwellLandingCorbel")
		var lamp_at := at + Vector2(module.width * 0.5, -68)
		_box(Rect2(lamp_at + Vector2(-4, 5), Vector2(8, 8)), -1.85, 1.2, brass, "BellStairwellSconceWallBracket")
		_lamp(lamp_at, "BellStairwell")

func _sloping_canopy(rect: Rect2, material: Material) -> void:
	var corners := [Vector3(rect.position.x * P, -rect.position.y * P, -3.6), Vector3(rect.end.x * P, -rect.position.y * P, -3.6), Vector3(rect.end.x * P, -rect.end.y * P, -1.7), Vector3((rect.position.x - 120) * P, -rect.end.y * P, -1.7)]
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in [0, 2, 1, 0, 3, 2]:
		var vertex: Vector3 = corners[i]
		surface.set_uv(Vector2(vertex.x, vertex.z))
		surface.add_vertex(vertex)
	surface.generate_normals()
	var pane := MeshInstance3D.new()
	pane.name = "B10TrueSlopedCanopy"
	pane.mesh = surface.commit()
	pane.material_override = material
	stage.scenery.add_child(pane)
	var count := ceili(rect.size.x / 144.0)
	for i in count + 1:
		var t := float(i) / count
		var a: Vector3 = corners[0].lerp(corners[1], t)
		var b: Vector3 = corners[3].lerp(corners[2], t)
		var rafter: MeshInstance3D = stage._box((a + b) * 0.5, Vector3(0.08, 0.08, a.distance_to(b)), iron, "B10SlopedGlazingRafter")
		rafter.look_at(b)
