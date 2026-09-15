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
	glass = stage._material(Rect2(), Color("8d624c"), "glass")
	glass.emission_enabled = true
	glass.emission = Color("593c26")
	glass.emission_energy_multiplier = 0.3
	stage.night = NightBackdrop.new()
	stage.night.name = "NightBackdrop"
	stage.scenery.add_child(stage.night)
	for index in range(5, 10):
		stage.night.layer("CastleSilhouette%d" % index, preload("res://assets/environments/crimson/castle_v3.png"), Vector3(index * 20.0 + 10, -5.1, -9), 20.0 / 1536.0)
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

func _rear_rail(a: Vector2, b: Vector2, id: String) -> void:
	var count := maxi(1, ceili(absf(b.x - a.x) / 72.0))
	for i in count + 1:
		var point := a.lerp(b, float(i) / count)
		_box(Rect2(point + Vector2(-2, -36), Vector2(4, 39)), -0.99, 0.055, iron, id + "RearRailPost")
	_beam(a - Vector2(0, 36), b - Vector2(0, 36), 3, -0.99, 0.07, brass, id + "RearRailCap")
	_beam(a - Vector2(0, 16), b - Vector2(0, 16), 2, -0.99, 0.04, iron, id + "RearRailTie")

func _source(rect: Rect2) -> Rect2:
	return Rect2(Vector2(rect.position.x * 8, 1120 + (rect.position.y - 430) * 8), rect.size * 8)

func _record_rect(record: Dictionary) -> Rect2:
	return Rect2(Vector2(record.position[0], record.position[1]), Vector2(record.size[0], record.size[1]))

func _structure(record: Dictionary) -> void:
	var rect := _record_rect(record)
	var id: String = record.id
	match id:
		"B01", "B02", "B12":
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
			_box(rect, -2.0, 1.3, trim, id + "BellSuspensionBeam")
			_box(Rect2(rect.position + Vector2(0, -26), Vector2(rect.size.x, 26)), -2.0, 1.5, stone, id + "BeamCoping")
		"B07": _bell(rect, id)
		"B10":
			_roof(rect.position, rect.size.x, 112, id)
		"B11":
			_arch(rect, -1.9, 0.65, 32, trim, id + "GateArch")
		"B14":
			_extrude(_arch_outline(rect), -2.48, -2.44, glass, id + "StainedGlass")
			_arch(rect, -2.34, 0.15, 20, trim, id + "WindowArch")
			for i in range(1, 6):
				_box(Rect2(rect.position + Vector2(rect.size.x * i / 6.0 - 4, 60), Vector2(8, rect.size.y - 60)), -2.3, 0.08, brass, id + "Mullion")
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
	_box(Rect2(top - Vector2(12, 28), Vector2(24, 42)), -1.9, 0.24, iron, id + "VisibleHanger")
	stage._cylinder(Vector3(top.x * P, -(rect.position.y + rect.size.y * 0.46) * P, -2.0), rect.size.x * P * 0.44, rect.size.x * P * 0.23, rect.size.y * P * 0.80, brass, id + "CastBronzeBell")
	stage._cylinder(Vector3(top.x * P, -(rect.end.y - 35) * P, -2.0), rect.size.x * P * 0.51, rect.size.x * P * 0.46, 0.40, brass, id + "BellLip")
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
	var base := Vector2(528 * 8, 1408)
	var head := Vector2(base.x, -1000)
	_box(Rect2(base - Vector2(72, 30), Vector2(144, 30)), -2.0, 1.1, stone, "CraneFooting")
	for side in [-1, 1]:
		_beam(base + Vector2(side * 50, -20), head + Vector2(side * 18, 0), 18, -2.0, 0.18, iron, "CraneLatticeLeg")
	for y in range(-920, 1350, 144):
		_beam(Vector2(base.x - 38, y), Vector2(base.x + 38, y + 144), 8, -2.0, 0.1, iron, "CraneCrossBrace")
	var end := Vector2(676 * 8, -780)
	_beam(head, end, 28, -2.0, 0.28, iron, "CraneBoom")
	_beam(head - Vector2(0, 80), end, 7, -2.0, 0.08, brass, "CraneBoomStay")
	_beam(end, end + Vector2(0, 440), 5, -2.0, 0.08, iron, "CraneHangingCable")
	_box(Rect2(end + Vector2(-72, 440), Vector2(144, 120)), -2.0, 0.85, wood, "CraneSuspendedCargo")

func _garden() -> void:
	var rect := _source(Rect2(1250, 338, 229, 130))
	for x in range(int(rect.position.x), int(rect.end.x), 320):
		_box(Rect2(x, rect.position.y, 16, rect.size.y), -1.45, 0.3, iron, "GardenCanopyColumn")
		_box(Rect2(x - 10, rect.end.y - 20, 36, 20), -1.45, 0.75, stone, "GardenColumnFoot")
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
