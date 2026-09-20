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

func build(host: Node3D) -> void:
	stage = host
	stone = _masonry(Color("777080"))
	trim = _masonry(Color("ada1ac"))
	paving = _masonry(Color("b6aab6"))
	paving.uv1_scale *= 0.625
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
	_hall_details()
	_bell_landmark()
	_archive_and_stairwell()
	stage.scenery.add_child(preload("res://scenes/rooms/image_monastery_foreground.tscn").instantiate())

func _masonry(tint: Color) -> StandardMaterial3D:
	var mat: StandardMaterial3D = stage._material(Rect2(668, 42, 128, 62), tint)
	mat.uv1_triplanar = true
	mat.uv1_world_triplanar = true
	mat.uv1_scale = Vector3(3.12, 6.44, 3.12)
	return mat

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
	_rear_rail(a, b, id)
	# Uprights terminate at this stair's own stringer; never float over a gap.
	if maxf(a.y, b.y) > 1900:
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

func _structure(record: Dictionary) -> void:
	var rect := _record_rect(record)
	var id: String = record.id
	match id:
		"B01": _gatehouse_landmark(rect)
		"B12": _hall_landmark(rect)
		"B02":
			_box(rect, -3.6, 2.2, stone, id + "RearWall")
			_facade(rect, id)
			_roof(rect.position + Vector2(-40, 0), rect.size.x + 80, 220 if id != "B12" else 640, id)
		"B03", "B08", "B09", "B13":
			_box(rect, -2.25, 1.4, stone, id + "FoundationBackwall")
		"B04", "B05":
			_box(rect, -2.4, 2.4, stone, id + "TowerPier")
			for y in range(int(rect.position.y), int(rect.end.y), 240):
				_box(Rect2(rect.position.x - 12, y, rect.size.x + 24, 18), -2.4, 2.55, trim, id + "PierCourse")
			_roof(rect.position + Vector2(-36, 0), rect.size.x + 72, 420, id)
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
			_chapel_window(rect, id)
		"B15":
			# The construction plan adds the archive landing at y880. Its cabinet
			# must share that real support, not float at the source sketch's y832.
			_shelves(Rect2(6672, 296, 384, 584), id)
		"B16", "B17": _tank(rect, id)

func _facade(rect: Rect2, id: String) -> void:
	# The building silhouette follows the drawing; interior bays follow actor scale.
	for x in [rect.position.x + 24, rect.end.x - 52]:
		_box(Rect2(x, rect.position.y, 28, rect.size.y), -2.31, 0.32, trim, id + "EdgePilaster")
	for y in range(int(rect.position.y + 110), int(minf(rect.end.y, 1800) - 170), 320):
		for x in range(int(rect.position.x + 110), int(rect.end.x - 100), 260):
			_window(Rect2(x, y, 72, 150), id)
		_box(Rect2(rect.position.x, y + 180, rect.size.x, 12), -2.32, 0.25, trim, id + "StoreyBand")

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
		_box(Rect2(at - Vector2(0, 256), Vector2(width, 260)), -2.10, 1.65, stone, id + "InteriorBackwall")
		for x in range(int(at.x + 36), int(at.x + width - 60), 256):
			_arch(Rect2(x, at.y - 218, 186, 218), -1.32, 0.15, 12, trim, id + "TunnelRib")
			_lamp(Vector2(x + 12, at.y - 75), id)
		_box(Rect2(at - Vector2(0, 182), Vector2(width, 8)), -1.30, 0.08, iron, id + "ServicePipe")
		for x in range(int(at.x + 40), int(at.x + width), 320):
			_box(Rect2(x, at.y - 190, 6, 24), -1.29, 0.14, brass, id + "PipeBracket")

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
	_box(Rect2(rect.position, Vector2(rect.size.x, rect.size.y)), -3.2, 0.55, wood, "StationRearWall")
	_roof(rect.position - Vector2(32, 0), rect.size.x + 64, 128, "Station")
	for x in [rect.position.x + 30, rect.end.x - 48]:
		_box(Rect2(x, rect.position.y, 18, rect.size.y), -1.42, 0.28, wood, "StationSupportedPost")
		_box(Rect2(x - 12, rect.end.y - 24, 42, 24), -1.42, 0.50, stone, "StationPostFoot")
	for x in range(int(rect.position.x + 180), int(rect.end.x), 300):
		_lamp(Vector2(x, rect.end.y - 95), "Station")
		_box(Rect2(x - 45, rect.end.y - 22, 90, 8), -1.38, 0.3, wood, "StationBench")
		for leg in [-36, 36]:
			_box(Rect2(x + leg, rect.end.y - 14, 6, 14), -1.38, 0.24, iron, "StationBenchLeg")

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
	var rect := _source(Rect2(1250, 338, 229, 130))
	for x in range(int(rect.position.x), int(rect.end.x), 320):
		_box(Rect2(x, rect.position.y, 16, rect.size.y), -1.45, 0.3, iron, "GardenCanopyColumn")
		_box(Rect2(x - 10, rect.end.y - 20, 36, 20), -1.45, 0.75, stone, "GardenColumnFoot")
		var rear_top := _source_point(Vector2(0, 306)).y
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
		_box(Rect2(at - Vector2(0, 228), Vector2(width, 24)), -1.65, 0.65, stone, "GalleryContinuousArchitrave")
		for x in range(int(at.x + 20), int(at.x + width - 170), 224):
			_arch(Rect2(x, at.y - 204, 176, 204), -1.65, 0.45, 16, trim, "GalleryOpenGothicBay")
			for px in [x, x + 176]:
				_box(Rect2(px - 14, at.y - 18, 28, 18), -1.65, 0.65, stone, "GallerySupportedColumnFoot")

func _hall_details() -> void:
	# Human-scale wall treatment below the high window, backed by the authored hall.
	for x in range(13000, 15700, 320):
		_arch(Rect2(x, 1168, 176, 256), -1.4, 0.25, 16, trim, "HallLowerBlindArcade")
		_lamp(Vector2(x + 220, 1330), "Hall")
		_box(Rect2(x + 198, 1396, 36, 28), -1.44, 0.56, stone, "HallPilasterFoot")
		_box(Rect2(x + 208, 1168, 16, 228), -1.44, 0.28, trim, "HallPilaster")

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
	# Shared lower body, low west wing, and high east gatehouse are distinct masses.
	_box(Rect2(record_rect.position.x, _source_point(Vector2(0, 210)).y, record_rect.size.x, record_rect.end.y - _source_point(Vector2(0, 210)).y), -3.6, 2.2, stone, "B01LowerGatehouseMasonry")
	_box(_source(Rect2(282, 83, 120, 347)), -3.6, 2.2, stone, "B01HighGateTower")
	_roof(_source_point(Vector2(164, 209)), 126 * 8, 78 * 8, "B01WestSteepRoof")
	_box(_source(Rect2(190, 195, 92, 18)), -3.5, 2.2, stone, "B01WestRoofSeat")
	_box(_source(Rect2(282, 78, 120, 10)), -3.5, 2.5, trim, "B01CrenellatedParapet")
	for source_x in range(286, 403, 18):
		_box(_source(Rect2(source_x, 68, 6, 10)), -2.3, 0.3, stone, "B01ParapetMerlon")
		_box(_source(Rect2(source_x + 2, 60, 2, 8)), -2.3, 0.15, iron, "B01RoofIronFinial")
	for source_x in [286.0, 298.0]:
		_box(_source(Rect2(source_x, 17, 6, 61)), -3.3, 0.6, stone, "B01TallChimney")
	for source_x in [211.0, 250.0]:
		for source_y in [164.0, 258.0, 359.0]:
			_window(_source(Rect2(source_x, source_y, 11, 28)), "B01WestWingWindow")
	for source_x in [292.0, 380.0]:
		_box(_source(Rect2(source_x, 91, 10, 339)), -2.27, 0.45, trim, "B01GateButtress")
	_flag(Rect2(318, 142, 27, 108), -2.11, "B01GateLongBanner")
	_pointed_arch(_source(Rect2(331, 327, 52, 103)), 28 * 8, -1.80, 0.65, 35, "B01StreetPassage")
	_pointed_arch(_source(Rect2(324, 239, 39, 52)), 18 * 8, -2.12, 0.40, 22, "B01BalconyPortal")
	for source_y in [216.0, 307.0]:
		_box(_source(Rect2(192, source_y, 211, 7)), -2.26, 0.36, trim, "B01ProjectingFloorCornice")
	for point in [Vector2(204, 403), Vector2(321, 273), Vector2(384, 400)]:
		_lamp(_source_point(point), "B01Portal")

func _hall_landmark(record_rect: Rect2) -> void:
	_box(record_rect, -3.6, 2.2, stone, "B12HallRearMasonry")
	_roof(_source_point(Vector2(1587, 139)), 398 * 8, 87 * 8, "B12GreatGabledRoof")
	var arch := _source(Rect2(1634, 108, 321, 360))
	_pointed_arch(arch, 117 * 8, -1.8, 1.15, 112, "B12GreatHallArch")
	_pointed_arch(arch.grow(48), 125 * 8, -1.94, 0.90, 24, "B12OuterHallArchivolt")
	for source_x in [1646.0, 1934.0]:
		_box(_source(Rect2(source_x - 8, 135, 16, 333)), -1.90, 0.76, trim, "B12HallButtress")
		_pinnacle(Vector2(source_x, 132), 33, 120, "B12HallFlankingSpire")
	for source_x in [1680.0, 1887.0]:
		_pointed_arch(_source(Rect2(source_x, 318, 42, 112)), 34 * 8, -2.15, 0.45, 24, "B12LowerStatueNiche")
	_flag(Rect2(1664, 180, 34, 158), -1.30, "B12WestHangingBanner")
	_flag(Rect2(1850, 180, 34, 158), -1.30, "B12EastHangingBanner")
	_rose_window(Vector2(1786, 93), 12, -1.34, "B12RoofRose")
	for point in [Vector2(1646, 401), Vector2(1708, 439), Vector2(1846, 439), Vector2(1934, 401)]:
		_lamp(_source_point(point), "B12HallWall")

func _chapel_window(rect: Rect2, id: String) -> void:
	var material: StandardMaterial3D = stained_glass.duplicate()
	var atlas := AtlasTexture.new()
	atlas.atlas = stained_glass.albedo_texture
	atlas.region = Rect2(66, 9, 682, 1877)
	material.albedo_texture = atlas
	material.emission_texture = atlas
	material.set_meta("authored_texture", atlas)
	stage.materials.append(material)
	# Preserve the source window's authored proportions. Width and upper anchor
	# use B14; its sill extends to the lower tracery seen in the concept drawing.
	var fitted := Rect2(rect.position, Vector2(rect.size.x, rect.size.x * 1877.0 / 682.0))
	var pane := MeshInstance3D.new()
	pane.name = id + "AuthoredChapelWindow"
	var mesh := QuadMesh.new()
	mesh.size = fitted.size * P
	pane.mesh = mesh
	pane.position = Vector3(fitted.get_center().x * P, -fitted.get_center().y * P, -2.37)
	pane.material_override = material
	stage.scenery.add_child(pane)
	_pointed_arch(fitted.grow(22), fitted.size.y * 0.35, -2.23, 0.24, 18, id + "StoneRecess")
	_box(Rect2(fitted.position.x - 30, fitted.end.y, fitted.size.x + 60, 26), -2.18, 0.5, trim, id + "ProjectingStoneSill")
	for fraction in [0.25, 0.60, 0.92]:
		_warm_window_light(fitted.position + Vector2(fitted.size.x * 0.5, fitted.size.y * fraction), 5.0, 0.6, id)

func _archive_and_stairwell() -> void:
	_box(_source(Rect2(792, 204, 99, 298)), -3.65, 2.3, stone, "ArchiveSideHouseRearMasonry")
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
	_box(_source(Rect2(1152, 165, 98, 347)), -3.45, 2.1, stone, "BellStairwellRearMasonry")
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
