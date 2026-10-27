extends "res://scripts/rooms/image_monastery_visual.gd"
## Authored facade crops follow the compact map; physics remains scene-owned.
const ARCHITECTURE = preload("res://assets/environments/crimson/monastery_architecture_v2.png")
const DETAIL_ART := {
	"glass":{"texture":preload("res://assets/environments/crimson/rebuild_stained_glass_v1.png"),"source":Rect2(164,12,771,1397)},
	"saint":{"texture":preload("res://assets/environments/crimson/rebuild_saint_v1.png"),"source":Rect2(97,106,552,1877)},
	"reredos":{"texture":preload("res://assets/environments/crimson/rebuild_reredos_v1.png"),"source":Rect2(111,72,619,1708)},
	"crown":{"texture":preload("res://assets/environments/crimson/rebuild_red_crown_v1.png"),"source":Rect2(34,129,1576,680)},
	"branches":{"texture":preload("res://assets/environments/crimson/rebuild_tree_branches_v1.png"),"source":Rect2(41,111,1077,1159)},
	"ivy":{"texture":preload("res://assets/environments/crimson/rebuild_ivy_v1.png"),"source":Rect2(221,50,445,1691)},
	"door":{"texture":preload("res://assets/environments/crimson/rebuild_service_door_v1.png"),"source":Rect2(69,69,776,1598)},
	"crate":{"texture":preload("res://assets/environments/crimson/rebuild_crate_face_v1.png"),"source":Rect2(141,83,1166,918)},
	"books":{"texture":preload("res://assets/environments/crimson/archive_bookshelf_v1.png"),"source":Rect2(0,0,1024,1536)},
	"rose":{"texture":preload("res://assets/environments/crimson/rebuild_rose_shrub_v1.png"),"source":Rect2(43,71,1408,909)},
	"lantern":{"texture":preload("res://assets/environments/crimson/rebuild_lantern_v1.png"),"source":Rect2(202,187,483,1350)}}
const PANELS := [
	{"id":"StationNear","texture":preload("res://assets/environments/crimson/rebuild_gate_near.png"),"reference":Rect2(0,200,430,320),"clip":Vector2(0,400)},
	{"id":"CargoNear","texture":preload("res://assets/environments/crimson/rebuild_cargo_near.png"),"reference":Rect2(400,200,500,440),"clip":Vector2(400,800)},
	{"id":"BellNear","texture":preload("res://assets/environments/crimson/rebuild_bell_near.png"),"reference":Rect2(780,180,480,500),"clip":Vector2(800,1230)},
	{"id":"GardenNear","texture":preload("res://assets/environments/crimson/rebuild_garden_near.png"),"reference":Rect2(1220,260,280,450),"clip":Vector2(1230,1480)},
	{"id":"HallNear","texture":preload("res://assets/environments/crimson/rebuild_hall_near.png"),"reference":Rect2(1450,300,598,400),"clip":Vector2(1480,2048)}]

func build(host: Node3D) -> void:
	stage = host
	stone = _masonry(Color("b5ad9c"))
	trim = _masonry(Color("d1c0a3"))
	paving = _masonry(Color("d9c7a7"))
	var masonry_image := preload("res://assets/environments/crimson/rebuild_gate_near.png").get_image().get_region(Rect2i(730,320,128,128))
	var masonry_texture := ImageTexture.create_from_image(masonry_image)
	for mat in [stone,trim,paving]:
		mat.albedo_texture = masonry_texture
		mat.set_meta("authored_texture",masonry_texture)
		mat.albedo_color = Color("b4b0a7")
		mat.uv1_triplanar = true
		mat.uv1_world_triplanar = true
		mat.uv1_scale = Vector3.ONE * 1.7
	iron = stage._material(Rect2(), Color("707184"), "iron")
	brass = stage._material(Rect2(), Color("bca26f"), "brass")
	wood = stage._material(Rect2(), Color("8d7867"), "wood")
	roof = stage._material(Rect2(), Color("41475e"), "iron")
	stage.night = NightBackdrop.new()
	stage.night.name = "NightBackdrop"
	stage.scenery.add_child(stage.night)
	stage.night.moon_origin_x = 30.0
	stage.night.moon_camera_anchor_x = 20.48
	stage.night.moon.position.y = 4.3
	stage.night.moon.pixel_size = 0.00463
	stage.night.moon.modulate = Color(0.74,0.78,0.86)
	for card in stage.night.get_children():
		if str(card.name).begins_with("CastleSilhouette"): card.position.y = -3.0
	for module in stage.game.environment.modules: _floor(module)
	for flight in stage.game.environment.stairs:
		var first: int = stage.scenery.get_child_count()
		_stair(flight)
		var pieces: Array[Node] = []
		for index in range(first, stage.scenery.get_child_count()):
			pieces.append(stage.scenery.get_child(index))
		stage.platform_visuals[flight] = pieces
	for record in stage.game.environment.structure_records:
		if record.get("kind","") == "roof":
			var points := PackedVector2Array()
			for p in record.polygon: points.append(Vector2(p[0],p[1]))
			_extrude(points,-0.64,0.34,roof,str(record.id)+"SolidRoof")
		else: _facade(record)
	for panel in PANELS: _near_panel(panel)
	_hall_details()
	_garden_details()
	_cargo_details()
	_gatehouse_structure()
	_flow_prop(Rect2(8,275,565,385),Vector2(96,512),96,-0.24,"StationCarriagePainted")
	_box(Rect2(62,484,68,12),-0.47,0.40,wood,"StationCarriageBody")
	_box(Rect2(2288,80,208,508),-1.19,0.18,stone,"BellStairwellRearMasonry")
	var bell_source := Rect2(981, 130, 91, 104)
	_paperboard(_source(bell_source), ARCHITECTURE, bell_source, -0.47, "AuthoredHangingBell")
	for at in [Vector2(216,512),Vector2(848,512),Vector2(1104,584),Vector2(1632,584),Vector2(1936,656),Vector2(2600,588),Vector2(3032,588),Vector2(3504,488),Vector2(3640,488)]:
		_warm_window_light(at - Vector2(0,64), 2.6, 0.55, "CourtyardLamp")
		var lamp := stage.scenery.get_child(stage.scenery.get_child_count()-1) as OmniLight3D
		lamp.position.z = -0.20
	for action in stage.game.environment.action_points:
		if action.id == "lift_repair": _flow_prop(Rect2(1102,166,440,370),action.position,58,-0.12,"FreightRepairConsole")
	stage.foreground = preload("res://scenes/rooms/image_monastery_foreground.tscn").instantiate()
	stage.scenery.add_child(stage.foreground)

func _source(rect: Rect2) -> Rect2:
	return Rect2(ImageMonastery.source_to_world(rect.position), rect.size * 2.0)

func _source_point(point: Vector2) -> Vector2:
	return ImageMonastery.source_to_world(point)

func _facade(record: Dictionary) -> void:
	var a: Array = record.source_bounds
	var source := Rect2(a[0],a[1],a[2],a[3])
	var rect := _record_rect(record)
	var windows: Array = []
	match str(record.id):
		"StationGate": windows = [Rect2(211,149,14,30),Rect2(294,236,18,26),Rect2(291,277,21,28)]
		"CargoCourt": windows = [Rect2(470,279,25,38),Rect2(589,325,14,32),Rect2(624,325,14,32)]
		"BellCourt": windows = [Rect2(812,237,64,52),Rect2(813,348,62,46)]
		"Garden": windows = [Rect2(1304,353,112,46)]
		"GreatHall": windows = [Rect2(1735,156,92,191),Rect2(1648,401,33,60),Rect2(1908,397,32,68)]
	var holes := windows.duplicate()
	if str(record.id) == "CargoCourt": holes.append(Rect2(410,110,300,160))
	for panel in PANELS:
		var overlap: Rect2 = panel.reference.intersection(source)
		if overlap.has_area(): holes.append(overlap)
	if str(record.id) == "BellCourt": holes.append(Rect2(981,130,91,104))
	var wall := _paperboard_cutout(rect, ARCHITECTURE, source, holes, -0.46, str(record.id)+"AuthoredFacade")
	wall.set_meta("reference_source",source)
	wall.set_meta("world_rect",rect)
	wall.set_meta("logical_per_texel",2.0)
	var material := wall.material_override as StandardMaterial3D
	material.albedo_color = Color(0.78,0.82,0.90)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for opening: Rect2 in windows:
		if str(record.id)=="GreatHall" and opening==windows[0]: continue
		if PANELS.any(func(panel): return panel.reference.encloses(opening)): continue
		var pane_rect := _paper_detail_rect(rect,source,opening)
		var pane := _paperboard(pane_rect.grow(4),ARCHITECTURE,opening.grow(2),-0.92,str(record.id)+"RecessedGlass")
		pane.shaded = false
		pane.modulate = Color.WHITE
		pane.set_meta("wall_z",-0.86)
		_layered_window_reveal(pane_rect,-0.9,str(record.id)+"WindowReveal")
	if str(record.id) == "CargoCourt":
		var crop := Rect2(410,110,300,160)
		var crane := _paperboard(_source(crop),ARCHITECTURE,crop,-0.80,"CargoCraneSkyline")
		crane.shaded = false
		crane.modulate = Color.WHITE
		_beam(_source_point(Vector2(526,238)),_source_point(Vector2(526,136)),4,-0.86,0.12,iron,"CargoCraneMast")
		_beam(_source_point(Vector2(526,202)),_source_point(Vector2(675,146)),4,-0.86,0.12,iron,"CargoCraneBoom")

func _near_panel(spec: Dictionary) -> void:
	var texture: Texture2D = spec.texture
	var reference: Rect2 = spec.reference
	var scale := Vector2(texture.get_size()) / reference.size
	var clip := Rect2(spec.clip.x,reference.position.y,spec.clip.y-spec.clip.x,reference.size.y)
	var source := Rect2((clip.position-reference.position)*scale,clip.size*scale)
	var rect := _source(clip)
	var doors: Array = []
	if str(spec.id) == "HallNear": doors.append({"source":Rect2(152,120,185,286),"gate":"gate_departure"})
	if str(spec.id) == "BellNear": doors.append({"source":Rect2(72,640,185,184),"gate":"gate_lift"})
	var holes: Array = []
	if str(spec.id)=="HallNear":
		holes.append_array([Rect2(725,0,245,242),Rect2(795,40,115,267)])
	if str(spec.id)=="GardenNear":
		holes.append_array([Rect2(152,304,380,426),Rect2(125,367,99,340)])
	if str(spec.id)=="CargoNear":
		holes.append_array([Rect2(145,540,106,174),Rect2(405,545,375,165)])
	if str(spec.id)=="BellNear":
		holes.append(Rect2(45,342,230,210))
	for door in doors: holes.append(door.source)
	if str(spec.id) == "BellNear": holes.append(Rect2(520,0,220,128))
	var panes: Array = []
	match str(spec.id):
		"StationNear": panes = [Rect2(711,185,76,114),Rect2(837,182,70,118)]
		"CargoNear": panes = [Rect2(475,345,52,134),Rect2(598,345,55,134),Rect2(726,345,56,134),Rect2(854,345,55,134),Rect2(975,345,54,134)]
		"GardenNear": panes = [Rect2(347,170,480,151),Rect2(535,439,84,249)]
	holes.append_array(panes)
	var pieces := _architectural_parts(str(spec.id))
	for part in pieces: holes.append(part.source)
	var wall := _paperboard_cutout(rect,texture,source,holes,-0.96,str(spec.id)+"RearMasonryFace")
	var mat := wall.material_override as StandardMaterial3D
	mat.albedo_color = Color(0.82,0.84,0.90)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	wall.set_meta("reference_source",clip)
	wall.set_meta("world_rect",rect)
	wall.set_meta("logical_per_texel",rect.size.x/source.size.x)
	_paper_edges(rect,texture,source,str(spec.id),-1.12,-0.96)
	for part in pieces:
		var crop: Rect2 = part.source if part.get("overhang",false) else part.source.intersection(source)
		if not crop.has_area(): continue
		var part_rect := _paper_detail_rect(rect,source,crop)
		if str(spec.id) == "StationNear" and part.id == "PortalFrame":
			_gate_arch(texture)
			continue
		if str(spec.id) == "StationNear" and part.id in ["GalleryRail","UpperPortal"]: continue
		if str(part.id).ends_with("Statue"):
			_saint_niche(part_rect,str(spec.id)+part.id)
			continue
		var detail_holes := panes.duplicate()
		for child in pieces:
			if child.get("parent","") == part.id: detail_holes.append(child.source)
		var face := _paperboard_cutout(part_rect,texture,crop,detail_holes,part.z,str(spec.id)+part.id)
		face.material_override.albedo_color = Color(0.90,0.91,0.96)
		face.material_override.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		face.set_meta("architectural_part",part.id)
		face.set_meta("depth_role",part.z)
		_paper_edges(part_rect,texture,crop,str(spec.id)+part.id,part.z-0.025,part.z)
	for door in doors:
		var crop: Rect2 = door.source.intersection(source)
		if not crop.has_area(): continue
		var door_rect := _paper_detail_rect(rect,source,crop)
		var leaf := _paperboard(door_rect,texture,crop,-0.38,str(spec.id)+"MovingDoor")
		leaf.shaded = false
		leaf.modulate = Color.WHITE
		var platform = stage.game.environment.gates[door.gate]
		stage.platform_visuals[platform].append(leaf)
		_box(door_rect.grow(4),-1.58,0.03,roof,str(spec.id)+"DoorwayInterior")
		for x in [door_rect.position.x,door_rect.end.x]:
			_box(Rect2(x-1,door_rect.position.y,2,door_rect.size.y),-1.04,1.10,stone,str(spec.id)+"DoorwaySideReveal")
	for pane in panes:
		var within: Rect2 = pane.intersection(source)
		if not within.has_area(): continue
		var opening := _paper_detail_rect(rect,source,within)
		if str(spec.id) == "GardenNear" and pane.size.x > 100:
			_greenhouse_roof(opening,texture,within)
			continue
		_box(opening.grow(2),-1.40,0.025,roof,str(spec.id)+"WindowInterior")
		var pane_card := _paperboard(opening,texture,within,-1.25,str(spec.id)+"RecessedGlass")
		pane_card.shaded = false
		pane_card.modulate = Color.WHITE
		pane_card.set_meta("depth_role",-1.25)
		pane_card.set_meta("wall_z",-0.96)
		# Jambs bridge the hollow wall; painted glass cannot sit on its face.
		for x in [opening.position.x,opening.end.x]:
			_box(Rect2(x-1,opening.position.y,2,opening.size.y),-1.08,0.34,trim,str(spec.id)+"WindowJamb")
		_box(Rect2(opening.position.x-2,opening.end.y,opening.size.x+4,3),-0.85,0.52,trim,str(spec.id)+"ProjectingSill")
		if str(spec.id) != "GardenNear":
			_box(Rect2(opening.get_center().x-0.7,opening.position.y,1.4,opening.size.y),-0.78,0.05,iron,str(spec.id)+"WindowMullion")

func _architectural_parts(id: String) -> Array:
	# Crops are semantic building parts, each removed from the rear face once.
	match id:
		"StationNear": return [
			{"id":"ShelterRoof","source":Rect2(0,260,690,154),"z":-0.23},
			{"id":"ShelterBeam","source":Rect2(0,414,575,68),"z":-0.36},
			{"id":"ShelterWestPost","source":Rect2(47,482,78,298),"z":-0.20},
			{"id":"ShelterMiddlePost","source":Rect2(147,482,70,298),"z":-0.24},
			{"id":"ShelterEastPost","source":Rect2(525,482,62,298),"z":-0.26},
			{"id":"WestButtress","source":Rect2(587,414,91,366),"z":-0.48},
			{"id":"GateButtress","source":Rect2(958,0,146,780),"z":-0.38},
			{"id":"PortalFrame","source":Rect2(1104,414,296,366),"z":-0.32},
			{"id":"UpperPortal","source":Rect2(1104,96,296,180),"z":-0.32},
			{"id":"GalleryRail","source":Rect2(1104,276,296,138),"z":-0.14}]
		"CargoNear": return [
			{"id":"GalleryCornice","source":Rect2(420,285,642,60),"z":-0.45},
			{"id":"GalleryPlinth","source":Rect2(420,490,642,60),"z":-0.42},
			{"id":"FreightPier","source":Rect2(1065,285,59,509),"z":-0.36}]
		"BellNear": return [
			{"id":"WesternButtress","source":Rect2(286,0,136,820),"z":-0.40},
			{"id":"EasternButtress","source":Rect2(827,0,136,820),"z":-0.40},
			{"id":"WesternBanner","source":Rect2(326,0,60,208),"z":-0.25,"parent":"WesternButtress"},
			{"id":"EasternBanner","source":Rect2(872,0,53,208),"z":-0.25,"parent":"EasternButtress"},
			{"id":"WesternStatue","source":Rect2(336,350,43,126),"z":-0.65,"parent":"WesternButtress"},
			{"id":"EasternStatue","source":Rect2(881,350,44,126),"z":-0.65,"parent":"EasternButtress"}]
		"GardenNear": return [
			{"id":"HangingBanner","source":Rect2(933,35,56,321),"z":-0.32,"overhang":true},
			{"id":"GreenhouseCornice","source":Rect2(275,116,595,54),"z":-0.42},
			{"id":"GreenhouseSill","source":Rect2(275,321,595,46),"z":-0.40}]
		"HallNear": return [
			{"id":"WesternPier","source":Rect2(390,0,100,730),"z":-0.32},
			{"id":"EasternPier","source":Rect2(1160,0,112,730),"z":-0.32},
			{"id":"WesternStatue","source":Rect2(614,91,54,150),"z":-0.62},
			{"id":"EasternStatue","source":Rect2(1026,91,54,150),"z":-0.62},
			{"id":"WestBanner","source":Rect2(97,0,45,142),"z":-0.30}]
	return []

func _gate_arch(interior_texture: Texture2D) -> void:
	_arch_face(Vector2(732,512),160,"GatePassagePixelArch")
	var inside := Rect2(1180,510,130,270)
	var inner_extent := inside.size*(80.0/inside.size.x)
	var interior := _paperboard(Rect2(Vector2(732,512)-Vector2(40,inner_extent.y),inner_extent),interior_texture,inside,-1.44,"GatePassageInteriorArt")
	interior.shaded = false
	interior.modulate = Color.WHITE

func _arch_face(foot: Vector2,width: float,id: String) -> void:
	var texture := preload("res://assets/environments/crimson/rebuild_gate_arch_v1.png")
	var source := Rect2(127,80,871,1233)
	var extent := source.size * (width/source.size.x)
	var rect := Rect2(foot-Vector2(width*0.5,extent.y),extent)
	var face := _paperboard(rect,texture,source,-0.32,id)
	face.shaded = false
	face.modulate = Color.WHITE
	face.alpha_scissor_threshold = 0.5
	face.set_meta("architectural_part","PortalFrame")
	_paper_edges(rect,texture,source,id,-0.40,-0.32)

func _detail(id: String,foot: Vector2,height: float,z: float,label: String) -> Sprite3D:
	var art: Dictionary = DETAIL_ART[id]
	var source: Rect2 = art.source
	var size := source.size*(height/source.size.y)
	var rect := Rect2(foot-Vector2(size.x*0.5,size.y),size)
	var face := _paperboard(rect,art.texture,source,z,label)
	face.shaded = id not in ["glass","lantern"]
	face.modulate = Color(0.80,0.82,0.88)
	face.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if id=="glass" else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	face.alpha_scissor_threshold = 0.5
	face.set_meta("world_rect",rect)
	var edge_material: Material = wood if id in ["reredos","branches","door","crate","books"] else trim
	if id=="lantern": edge_material = iron
	if id in ["crown","ivy","rose"]:
		var foliage_edge := StandardMaterial3D.new()
		foliage_edge.albedo_color = Color(0.16,0.08,0.14) if id=="crown" else Color(0.10,0.14,0.10)
		edge_material = foliage_edge
	_paper_edges(rect,art.texture,source,label,z-0.035,z,edge_material)
	return face

func _saint_niche(rect: Rect2,id: String) -> void:
	_box(rect.grow(1),-1.32,0.04,roof,id+"NicheBack")
	for x in [rect.position.x-2,rect.end.x]:
		_box(Rect2(x,rect.position.y,2,rect.size.y),-0.89,0.64,trim,id+"NicheJamb")
	var apex := Vector2(rect.get_center().x,rect.position.y-9)
	for x in [rect.position.x,rect.end.x]:
		_beam(Vector2(x,rect.position.y+5),apex,2,-0.57,0.12,trim,id+"NicheCanopy")
	_box(Rect2(rect.position.x-3,rect.end.y,rect.size.x+6,6),-0.78,0.60,trim,id+"Plinth")
	var figure := _detail("saint",Vector2(rect.get_center().x,rect.end.y),rect.size.y,-0.54,id+"Figure")
	figure.modulate = Color(0.77,0.75,0.72)

func _hall_details() -> void:
	var opening := Rect2(3464,-36,196,424)
	_box(opening,-1.49,0.04,roof,"HallWindowInterior")
	var glass := _detail("glass",Vector2(3562,386),358,-1.27,"HallRecessedTriptych")
	glass.modulate = Color(0.60,0.64,0.74)
	for x in [opening.position.x,opening.end.x]:
		_box(Rect2(x-2,opening.position.y,4,opening.size.y),-1.04,0.52,trim,"HallWindowRevealJamb")
	for y in [opening.position.y,opening.end.y]:
		_box(Rect2(opening.position.x,y-2,opening.size.x,4),-1.04,0.52,trim,"HallWindowRevealSill")
	_box(Rect2(3452,386,220,102),-1.30,0.08,stone,"HallLowerWindowSpandrel")
	_box(Rect2(3514,285,96,203),-1.34,0.05,wood,"HallReredosBack")
	var shrine := _detail("reredos",Vector2(3562,488),180,-0.57,"HallReredos")
	shrine.modulate = Color(0.72,0.72,0.76)
	_box(Rect2(3525,488,74,5),-0.78,0.64,trim,"HallReredosPlinth")

func _garden_details() -> void:
	var rear_stone := stone.duplicate() as StandardMaterial3D
	rear_stone.albedo_color = Color(0.65,0.60,0.53)
	_box(Rect2(2496,334,284,274),-1.53,0.12,rear_stone,"GardenRearMasonry")
	for x in [2514,2602,2690]:
		_box(Rect2(x,374,64,144),-1.44,0.03,roof,"GardenRearBlindArcade")
		for edge in [x,x+64]:
			_box(Rect2(edge-2,374,4,144),-1.36,0.18,trim,"GardenRearArcadeJamb")
		for edge in [x,x+64]:
			_beam(Vector2(edge,374),Vector2(x+32,354),4,-1.36,0.18,trim,"GardenRearArcadeHead")
	_garden_planter(Vector2(2634,588),88,28,"GardenTreePlanter")
	var branches := _detail("branches",Vector2(2634,560),148,-0.75,"GardenTreeBranches")
	branches.modulate = Color(0.74,0.74,0.80)
	var crown := _detail("crown",Vector2(2634,504),98,-0.38,"GardenTreeCrown")
	crown.modulate = Color(0.78,0.74,0.82)
	for side in ["West","East"]:
		var x := 2496.0 if side=="West" else 2824.0
		_box(Rect2(x-2,376,4,212),-0.91,0.18,iron,"GardenIvyTrellis"+side)
		for y in [396,452,508]:
			_box(Rect2(x-14,y,28,2),-0.90,0.10,iron,"GardenIvyCrossbar"+side)
		var ivy := _detail("ivy",Vector2(x,566),162,-0.61 if side=="West" else -0.48,"GardenIvy"+side)
		ivy.flip_h = side=="East"
		ivy.modulate = Color(0.72,0.75,0.80)
	for at in [Vector2(2558,536),Vector2(2738,536)]:
		var vine := _detail("ivy",at,190 if at.x<2600 else 176,-1.21,"GardenRearIvyLeft" if at.x<2600 else "GardenRearIvyRight")
		vine.modulate = Color(0.58,0.67,0.59)
	var beds := [{"id":"GardenRoseLeft","x":2548.0,"width":64.0,"depth":24.0,"height":60.0,"z":-0.57},{"id":"GardenRoseRight","x":2732.0,"width":68.0,"depth":28.0,"height":70.0,"z":-0.49}]
	for bed in beds:
		_garden_planter(Vector2(bed.x,588),bed.width,bed.depth,bed.id+"Planter")
		var rose := _detail("rose",Vector2(bed.x,588-bed.depth),bed.height,bed.z,bed.id)
		rose.modulate = Color(0.82,0.83,0.78)
		rose.flip_h = bed.x>2600
	_detail("lantern",Vector2(2552,512),34,-0.58,"GardenLantern")
	_strut(Vector3(25.14,-4.65,-1.46),Vector3(25.52,-4.65,-0.60),0.025,iron,"GardenLanternWallBracket")
	_box(Rect2(2551,465,2,14),-0.60,0.04,iron,"GardenLanternHanger")
	_warm_window_light(Vector2(2552,497),1.9,0.75,"GardenLantern")
	var lantern_light := stage.scenery.get_child(stage.scenery.get_child_count()-1) as OmniLight3D
	lantern_light.position.z = -0.20

func _garden_planter(foot: Vector2,width: float,height: float,id: String) -> void:
	_box(Rect2(foot-Vector2(width*.5,height),Vector2(width,height)),-0.77,0.48,stone,id)
	_box(Rect2(foot-Vector2(width*.5+3,height+2),Vector2(width+6,3)),-0.76,0.54,trim,id+"Rim")
	var source := Rect2(277,674,174,56)
	var size := source.size*(width/source.size.x)
	var face := _paperboard(Rect2(foot-Vector2(size.x*.5,size.y),size),PANELS[3].texture,source,-0.515,id+"PaintedFront")
	face.modulate = Color(0.78,0.78,0.84)

func _cargo_details() -> void:
	_box(Rect2(902,448,88,140),-1.36,0.08,roof,"CargoServiceRecess")
	_detail("door",Vector2(944,584),128,-0.65,"CargoServiceDoor")
	for x in [908,978]:
		_box(Rect2(x,452,4,132),-0.91,0.48,stone,"CargoServiceJamb")
	var stair = stage.game.environment.get_node("Gameplay/S05")
	var a: Vector2 = stair.position+Vector2(0,stair.stair_depth)
	var b: Vector2 = stair.position+stair.end_offset+Vector2(0,stair.stair_depth)
	_extrude(PackedVector2Array([a,b,Vector2(b.x,600),Vector2(a.x,600)]),-1.44,-1.28,stone,"CargoStairRearMasonry")
	_box(Rect2(1140,584,112,6),-0.88,1.20,wood,"CargoFreightShelf")
	var crates := [Vector3(1170,584,36),Vector3(1218,584,44),Vector3(1170,548,30)]
	for index in crates.size():
		var at: Vector3 = crates[index]
		var width: float = at.z*DETAIL_ART.crate.source.size.x/DETAIL_ART.crate.source.size.y
		_box(Rect2(at.x-width*.5,at.y-at.z,width,at.z),-0.82,0.58,wood,"CargoCrateBody"+str(index))
		_detail("crate",Vector2(at.x,at.y),at.z,-0.515,"CargoCrateFace"+str(index))
	_box(Rect2(1590,268,196,190),-1.40,0.06,roof,"ArchiveBooksRecess")
	var shelf := _detail("books",Vector2(1712,452),140,-0.69,"ArchiveBooks")
	var bounds: Rect2 = shelf.get_meta("world_rect")
	_box(bounds,-0.85,0.28,wood,"ArchiveBookcaseBody")
	_box(Rect2(bounds.position.x-3,452,bounds.size.x+6,5),-0.74,1.0,wood,"ArchiveBookcaseLedger")

func _greenhouse_roof(rect: Rect2, texture: Texture2D, source: Rect2) -> void:
	var corners := [Vector3(rect.position.x*P,-rect.position.y*P,-1.52),
		Vector3(rect.position.x*P,-rect.end.y*P,-0.56),
		Vector3(rect.end.x*P,-rect.end.y*P,-0.56),
		Vector3(rect.end.x*P,-rect.position.y*P,-1.52)]
	var uv := [source.position,Vector2(source.position.x,source.end.y),source.end,Vector2(source.end.x,source.position.y)]
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in [0,1,2,0,2,3]:
		surface.set_uv(uv[i]/Vector2(texture.get_size()))
		surface.add_vertex(corners[i])
	surface.generate_normals()
	var sheet := MeshInstance3D.new()
	sheet.name = "GreenhouseSlopedFrameFace"
	sheet.mesh = surface.commit()
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	material.alpha_scissor_threshold = 0.15
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	sheet.material_override = material
	stage.scenery.add_child(sheet)
	var glazing := sheet.duplicate() as MeshInstance3D
	glazing.name = "GreenhouseSlopedGlass"
	var glass_mat := StandardMaterial3D.new()
	glass_mat.albedo_color = Color(0.18,0.32,0.48,0.30)
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	glass_mat.roughness = 0.18
	glazing.material_override = glass_mat
	glazing.position.z = -0.015
	stage.scenery.add_child(glazing)
	for i in [0,1,2,3]: _strut(corners[i],corners[(i+1)%4],0.035,iron,"GreenhouseRoofRim")
	for t in [0.2,0.4,0.6,0.8]:
		_strut(corners[0].lerp(corners[3],t),corners[1].lerp(corners[2],t),0.025,iron,"GreenhouseRoofRafter")
	for corner in [corners[1],corners[2]]:
		_strut(Vector3(corner.x,-588*P,corner.z),corner,0.065,iron,"GreenhouseSupportColumn")

func _strut(a: Vector3,b: Vector3,width: float,material: Material,id: String) -> MeshInstance3D:
	var node: MeshInstance3D = stage._box((a+b)*0.5,Vector3(width,a.distance_to(b),width),material,id)
	node.quaternion = Quaternion(Vector3.UP,(b-a).normalized())
	return node

func _gatehouse_structure() -> void:
	# Cutaway volumes sit behind the continuous walking plane, never over it.
	_box(Rect2(668,300,128,212),-1.58,0.05,stone,"GatePassageInterior")
	for x in [668,784]:
		_box(Rect2(x,300,12,212),-0.93,1.22,stone,"GatePassageSideWall")
	_box(Rect2(668,300,128,12),-0.93,1.22,trim,"GatePassageCeiling")
	var gallery: PaperPlatform = stage.game.environment.get_node("Gameplay/F06")
	var floor_y := gallery.position.y
	_box(Rect2(652,108,176,floor_y-108),-1.58,0.05,stone,"GateGalleryInterior")
	_box(Rect2(716,floor_y-96,56,96),-1.42,0.08,wood,"GateGalleryDoor")
	_arch_face(Vector2(744,floor_y),96,"GateGalleryPixelArch")
	for x in [gallery.position.x+8,gallery.position.x+gallery.width-8]:
		_box(Rect2(x-2,floor_y-32,4,32),-0.42,0.12,stone,"GalleryBalusterEnd")
	for x in range(int(gallery.position.x+16),int(gallery.position.x+gallery.width-16),12):
		_box(Rect2(x,floor_y-24,2,24),-0.42,0.05,iron,"GalleryBaluster")
	_box(Rect2(gallery.position.x,floor_y-27,gallery.width,3),-0.42,0.13,brass,"GalleryHandrail")
	for x in [34,98,326]:
		_box(Rect2(x,302,8,210),-1.58,0.18,wood,"StationShelterRearPost")
	for x in [34,326]:
		_box(Rect2(x,302,8,210),0.22,0.18,wood,"StationShelterNearPost")
	_box(Rect2(24,298,320,10),-0.66,2.08,wood,"StationShelterBeam")
	for x in [34,326]:
		_beam(Vector2(x,342),Vector2(x+30 if x<100 else x-30,308),5,-0.48,0.30,wood,"StationShelterBrace")

func _paper_edges(rect: Rect2, texture: Texture2D, source: Rect2, id: String, back: float, front: float, side_material: Material=null) -> void:
	var pixels := texture.get_image().get_region(Rect2i(source))
	var mask := BitMap.new()
	mask.create_from_image_alpha(pixels,0.5)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var vertices := 0
	for polygon in mask.opaque_to_polygons(Rect2i(Vector2i.ZERO,pixels.get_size()),3.0):
		if polygon.size() < 3: continue
		for index in polygon.size():
			var a: Vector2 = rect.position + polygon[index] / Vector2(pixels.get_size()) * rect.size
			var b: Vector2 = rect.position + polygon[(index+1)%polygon.size()] / Vector2(pixels.get_size()) * rect.size
			for v in [Vector3(a.x*P,-a.y*P,back),Vector3(b.x*P,-b.y*P,back),Vector3(b.x*P,-b.y*P,front),Vector3(a.x*P,-a.y*P,back),Vector3(b.x*P,-b.y*P,front),Vector3(a.x*P,-a.y*P,front)]:
				surface.set_uv(Vector2(v.x,v.y))
				surface.add_vertex(v)
				vertices += 1
	if vertices == 0: return
	surface.generate_normals()
	var edges := MeshInstance3D.new()
	edges.name = id+"PaperThickness"
	edges.mesh = surface.commit()
	edges.material_override = side_material if side_material!=null else trim
	edges.set_meta("paper_depth",front-back)
	stage.scenery.add_child(edges)

func _floor(module: PaperPlatform) -> void:
	var first: int = stage.scenery.get_child_count()
	var at: Vector2 = module.position
	var rect := Rect2(at,Vector2(module.width,module.collision_depth))
	var id := str(module.get_meta("structural_id",module.name))
	if module.get_meta("edge_barrier",false):
		_box(rect,-0.44,0.88,iron,id+"EndPost")
		_box(Rect2(at-Vector2(2,0),Vector2(module.width+4,4)),-0.48,0.96,brass,id+"EndCap")
	elif module.has_meta("freight_plate"):
		_box(Rect2(at-Vector2(0,24),Vector2(12,24)),-0.10,0.10,brass,id+"FreightPlate")
	elif id.begins_with("Luggage"):
		_box(rect,0.0,0.52,wood,id+"WoodenCase")
	elif module.has_meta("gate_id"):
		var leaf_x := at.x+module.width*0.5
		_box(Rect2(leaf_x-2,at.y,4,module.collision_depth),-0.66,2.08,iron,id+"GateLeaf")
		for z in [-1.64,0.32]:
			_box(Rect2(leaf_x-3,at.y,6,module.collision_depth),z,0.12,trim,id+"GateJamb")
		for y in range(0,ceili(module.collision_depth),32):
			_box(Rect2(leaf_x-3,at.y+y,6,3),-0.66,2.08,brass,id+"GateBrace")
	elif module.collision_depth > 80 and not module.get_meta("route_surface",false):
		_box(rect,-0.03,0.50,stone,id+"SolidPier")
	elif module.one_way:
		if id=="F04_Hatch": _box(Rect2(at,Vector2(module.width,8)),-0.96,1.36,iron,"GardenRearTieBeam")
		for x in range(0,ceili(module.width),8):
			_box(Rect2(at+Vector2(x,0),Vector2(4,4)),0.0,0.64,iron,id+"GrateSlat")
		for z in [-0.28,0.28]: _box(Rect2(at,Vector2(module.width,6)),z,0.045,iron,id+"EdgeGirder")
		if id.begins_with("F20_TowerLanding"):
			for x in [at.x+6,at.x+module.width-6]:
				_box(Rect2(x-1,at.y-28,2,28),-0.28,0.045,iron,id+"RearRailPost")
				_box(Rect2(x-2,at.y+3,4,5),-0.67,0.90,iron,id+"WallCorbel")
			_box(Rect2(at.x,at.y-28,module.width,2),-0.28,0.06,brass,id+"RearRailCap")
	else:
		_box(rect,-0.66,2.08,stone,id+"MasonryBody")
		_box(Rect2(at-Vector2(0,0.1),Vector2(module.width,2)),-0.66,2.10,paving,id+"Paving")
		_box(Rect2(at+Vector2(0,module.collision_depth-3),Vector2(module.width,3)),-0.66,2.10,trim,id+"Cornice")
		if id == "F06":
			for x in [at.x+8,at.x+module.width-16]:
				_box(Rect2(x,at.y+module.collision_depth,8,512-at.y-module.collision_depth),-0.48,0.12,stone,id+"SupportedPier")
	var pieces: Array[Node] = []
	for index in range(first,stage.scenery.get_child_count()):
		var piece: Node = stage.scenery.get_child(index)
		piece.visible = module.active
		pieces.append(piece)
	stage.platform_visuals[module] = pieces

func _stair(flight: Node2D) -> void:
	var a: Vector2 = flight.position
	var b: Vector2 = a + flight.end_offset
	var id := str(flight.name)
	var timber := id.begins_with("Luggage")
	var material := wood if timber else stone
	var back := -0.28 if timber else -1.70
	var front := 0.24 if timber else 0.38
	for step in stair_samples(a,flight.end_offset,flight.visual_tread):
		var width: float = step.right-step.left
		if flight.one_way:
			_box(Rect2(step.left,step.y,width*0.58,2),0.0,0.64,iron,id+"OpenTread")
		else:
			_box(Rect2(step.left,step.y,width+0.05,flight.stair_depth),(back+front)*0.5,front-back,material,id+"TreadRiser")
			_box(Rect2(step.left,step.y-0.1,width+0.05,2),(back+front)*0.5,front-back+0.02,wood if timber else paving,id+"TreadCap")
	if flight.one_way:
		for z in [-0.28,0.28]: _beam(a+Vector2(0,4),b+Vector2(0,4),4,z,0.04,iron,id+"OpenSideBeam")
	else:
		_extrude(PackedVector2Array([a+Vector2(0,4),b+Vector2(0,4),b+Vector2(0,flight.stair_depth),a+Vector2(0,flight.stair_depth)]),back,front,material,id+"ClosedStringer")
		if not timber:
			for at in [a,b]:
				var base := 1072.0
				for module in stage.game.environment.modules:
					if module.one_way or module.has_meta("gate_id") or module.collision_depth>80 or str(module.name).begins_with("Luggage"): continue
					if at.x>=module.position.x and at.x<=module.position.x+module.width and module.position.y>=at.y+flight.stair_depth:
						base = minf(base,module.position.y)
				_box(Rect2(at.x-3,at.y+flight.stair_depth,6,maxf(1,base-at.y-flight.stair_depth)),-1.58,0.18,stone,id+"RearSupportLeg")
	if not timber:
		for z in [-0.31]:
			for t in [0.0,0.5,1.0]:
				var foot := a.lerp(b,t)
				_box(Rect2(foot-Vector2(1,28),Vector2(2,32)),z,0.04,iron,id+"RearRailPost")
			_beam(a-Vector2(0,28),b-Vector2(0,28),2,z,0.045,brass,id+"RearRailCap")
