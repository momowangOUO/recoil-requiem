class_name CrimsonStage3D
extends Node3D
## 2026-09-10 user-approved 3D presentation. Simulation remains the existing 2D game.
## One transparent full-room texture preserves all authored limbs, gun aim and FX.

const PIXEL := 0.01
const RENDER_SCALE := 2.0
const VIEW_SIZE := Vector2i(1920, 1088)
const VIEW_CENTER := Vector2(480, 144)
const CAMERA_DISTANCE := 4.8
const CAMERA_RISE := 1.18
const CAMERA_FOV := 23.0
@export var campaign_enabled := false
# z-distance in metres; cursor reach is in logical screen pixels.
const WEAPON_CAMERA := {
	&"revolver": {"near": 4.8, "far": 7.2, "outside": 32.0},
	&"shotgun": {"near": 3.8, "far": 5.2, "outside": 8.0},
	&"smg": {"near": 4.4, "far": 6.3, "outside": 20.0}
}
var camera_distance := CAMERA_DISTANCE
var simulation := SubViewport.new()
var game: RecoilLab
var camera := Camera3D.new()
var scenery: Node3D
var actors := Sprite3D.new()
var muzzle_light := OmniLight3D.new()
var camera_target := Vector3.ZERO
var yaw_offset := 0.0
var frozen_camera := false
var materials: Array[StandardMaterial3D] = []
var greybox := false
var shadow_cards: Array[MeshInstance3D] = []
var residency = preload("res://scripts/rooms/campaign_residency.gd").new()
var residency_enabled := true
var door_material: StandardMaterial3D
var ui_host: Node
var platform_visuals: Dictionary = {}
var action_visuals: Dictionary = {}
var flow_visuals: Array = []
var alarm_light: OmniLight3D
var bell_clapper: MeshInstance3D
var night: NightBackdrop
var foreground: Node3D

static func to_stage(point: Vector2, depth: float = 0.0) -> Vector3:
	return Vector3(point.x * PIXEL, -point.y * PIXEL, depth)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	camera.name = "PerspectiveCamera"
	camera.fov = CAMERA_FOV
	camera.near = 0.05
	camera.far = 60
	add_child(camera)
	camera.make_current()
	_build_lighting()
	simulation.name = "Gameplay2D"
	simulation.size = VIEW_SIZE
	simulation.transparent_bg = true
	simulation.disable_3d = true
	simulation.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	simulation.handle_input_locally = false
	simulation.world_2d = World2D.new()
	add_child(simulation)
	actors.name = "PixelActorsAndProjectiles"
	actors.texture = simulation.get_texture()
	actors.pixel_size = PIXEL / RENDER_SCALE
	actors.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	actors.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	actors.alpha_scissor_threshold = 0.12
	actors.position = to_stage(VIEW_CENTER)
	actors.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(actors)
	game = load("res://scenes/crimson_slice.tscn").instantiate()
	if campaign_enabled: game.campaign_enabled = true
	game.presentation_host = ui_host if ui_host != null else self
	game.projected_aim = mouse_world
	game.trial_reset.connect(_room_reset)
	simulation.add_child(game)

func _build_lighting() -> void:
	var environment := WorldEnvironment.new()
	environment.name = "MoonlitAtmosphere"
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("151724")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("8c92b2")
	settings.ambient_light_energy = 0.65
	environment.environment = settings
	add_child(environment)
	var moon := DirectionalLight3D.new()
	moon.name = "Moonlight"
	moon.rotation_degrees = Vector3(-40, -24, 0)
	moon.light_color = Color("9caddb")
	moon.light_energy = 0.85
	moon.shadow_enabled = true
	moon.directional_shadow_max_distance = 24
	add_child(moon)
	muzzle_light.name = "GunFlashLight"
	muzzle_light.light_color = Color("ffd392")
	muzzle_light.omni_range = 1.4
	muzzle_light.light_energy = 1.3
	add_child(muzzle_light)

func _room_reset() -> void:
	residency.clear()
	# Hide only the 2D scenery. Players, enemies, bullets and hit FX still render.
	game.environment.hide()
	game.camera.enabled = false
	game.reticle.screen_position_source = reticle_screen
	simulation.canvas_transform = Transform2D(Vector2(RENDER_SCALE, 0), Vector2(0, RENDER_SCALE), Vector2(0, 128 * RENDER_SCALE))
	if is_instance_valid(scenery):
		scenery.free()
	scenery = Node3D.new()
	scenery.name = "CrimsonMonasteryGeometry"
	scenery.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(scenery)
	materials.clear()
	shadow_cards.clear()
	platform_visuals.clear()
	action_visuals.clear()
	flow_visuals.clear()
	alarm_light = null
	bell_clapper = null
	foreground = null
	_build_room()
	set_greybox(greybox)
	camera_target = to_stage(game.player.position + Vector2(0, -56))
	yaw_offset = 0
	camera_distance = camera_profile().near
	_update_camera(1.0)
	if is_instance_valid(foreground): foreground.call("follow_camera", camera)
	_update_actor_window()
	if campaign_enabled and residency_enabled:
		residency.setup(self)
		residency.update_at(game.player.position)

func _exit_tree() -> void:
	residency.clear()

func _material(region: Rect2, color: Color, surface: String = "iron") -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.88
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	if region.has_area():
		var source := PaperStage.ATLAS.get_image().get_region(Rect2i(region))
		material.albedo_texture = ImageTexture.create_from_image(source)
	else:
		material.albedo_texture = load("res://assets/environments/crimson/%s_v1.png" % surface)
		if surface in ["iron", "brass", "wood"]:
			material.uv1_triplanar = true
			material.uv1_world_triplanar = true
			material.uv1_scale = Vector3.ONE * 0.8
		if surface in ["iron", "brass"]:
			material.metallic = 0.45
			material.roughness = 0.65
	material.set_meta("authored_texture", material.albedo_texture)
	materials.append(material)
	return material

func _box(at: Vector3, size: Vector3, material: Material, label: String) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = material
	node.position = at
	scenery.add_child(node, true)
	return node

func _support_height(x: float, half_width: float, z: float, half_depth: float) -> float:
	# Query the same solid platform data that produces the visible floors.
	var world_x := x + scenery.global_position.x
	var best := -INF
	for module in game.environment.modules:
		if module.one_way or not module.active or not module.unlock_action.is_empty(): continue
		var left: float = module.position.x * PIXEL
		var right: float = left + module.width * PIXEL
		if world_x - half_width < left or world_x + half_width > right: continue
		if z - half_depth < -1.175 or z + half_depth > 0.675: continue
		var floor_y: float = -module.position.y * PIXEL - scenery.global_position.y
		if floor_y <= -3.0 and (not game.environment.get("campaign") or floor_y >= -4.0): best = maxf(best, floor_y)
	return best

func _build_platform_railing(module: PaperPlatform, dark: Material, gold: Material) -> void:
	# Each span belongs to one actual platform; gaps and elevation changes stay open.
	if module.one_way or module.position.y < 320 or module.width < 192: return
	var left: float = module.position.x * PIXEL + 0.04
	var width: float = module.width * PIXEL - 0.08
	var floor_y: float = -module.position.y * PIXEL
	var count := maxi(2, ceili(width / 0.2))
	for index in count + 1:
		_box(Vector3(left + width * index / count, floor_y + 0.20, -0.96), Vector3(0.025, 0.40, 0.025), dark, "RearRailing")
	_box(Vector3(left + width * 0.5, floor_y + 0.40, -0.96), Vector3(width + 0.025, 0.035, 0.05), gold, "RailingCap")

func _rose_support_height(x: float) -> float:
	# A planter needs a whole display space, not merely contact beneath its base.
	var world_x := x + scenery.global_position.x
	var best := -INF
	for support in game.environment.modules:
		if not support.active or support.one_way or not support.unlock_action.is_empty(): continue
		var left: float = support.position.x * PIXEL
		var right: float = left + support.width * PIXEL
		if world_x - 0.32 < left - 0.0001 or world_x + 0.32 > right + 0.0001: continue
		var floor_y: float = -support.position.y * PIXEL
		if game.environment.get("campaign") and (floor_y - scenery.global_position.y < -4.0 or floor_y - scenery.global_position.y > -3.0): continue
		var clear := true
		for obstacle in game.environment.modules:
			var obstacle_left: float = obstacle.position.x * PIXEL
			var obstacle_right: float = obstacle_left + obstacle.width * PIXEL
			if obstacle_right <= world_x - 0.32 + 0.0001 or obstacle_left >= world_x + 0.32 - 0.0001: continue
			var top: float = -obstacle.position.y * PIXEL
			var bottom: float = top - obstacle.collision_depth * PIXEL
			# Include currently hidden bridges so activation cannot bury the flowers.
			if top > floor_y + 0.001 and bottom < floor_y + 0.90:
				clear = false
				break
		if clear: best = maxf(best, floor_y - scenery.global_position.y)
	return best

func _build_room() -> void:
	if game.environment.get("image_led"):
		preload("res://scripts/rooms/image_monastery_visual.gd").new().build(self)
		_build_room_finish(_material(Rect2(), Color("706977")), _material(Rect2(), Color("b8a58b"), "brass"))
		return
	# Plain masonry for structural faces; the arch motif belongs to architecture only.
	var stone := _material(Rect2(668, 42, 526, 62), Color("8e829f"))
	var paving := _material(PaperPlatform.TOP_REGION, Color("a39aa9"))
	var dark := _material(Rect2(), Color("706977"))
	var edge := _material(Rect2(), Color("a59aaa"))
	var gold := _material(Rect2(), Color("b8a58b"), "brass")
	night = NightBackdrop.new()
	night.name = "NightBackdrop"
	scenery.add_child(night)
	if game.environment.get("campaign"):
		for index in range(5, 8):
			night.layer("CastleSilhouette%d" % (index + 1), preload("res://assets/environments/crimson/castle_v3.png"), Vector3(index * 20.0 + 10, -5.1, -9), 20.0 / 1536.0)
	for module in game.environment.modules:
		var first_child := scenery.get_child_count()
		var width: float = module.width * PIXEL
		# A thick fake slab would hide a 38px actor under a 48px-high platform.
		var height: float = maxf(module.collision_depth * PIXEL, 12.0) if module.grounded else module.collision_depth * PIXEL
		var depth := 1.18 if module.one_way else 1.85
		var center := to_stage(module.position + Vector2(module.width * 0.5, 0), -0.25)
		if module.one_way:
			var grating := _material(Rect2(), Color("6d9095"))
			for rail_z in [-0.76, 0.26]:
				_box(Vector3(center.x, center.y - 0.035, rail_z), Vector3(width, 0.04, 0.045), dark, "GrateRail")
			for slat in range(0, ceili(module.width), 12):
				_box(Vector3((module.position.x + slat + 2) * PIXEL, center.y - 0.02, -0.25), Vector3(0.04, 0.04, 1.06), grating, "OpenGrateSlat")
			var grating_pieces: Array[Node] = []
			for child_index in range(first_child, scenery.get_child_count()):
				var piece := scenery.get_child(child_index)
				piece.visible = module.active
				grating_pieces.append(piece)
			platform_visuals[module] = grating_pieces
			continue
		var face_material: StandardMaterial3D = stone.duplicate()
		face_material.uv1_scale = Vector3(maxf(1, width / 0.96), maxf(1, height / 0.48) if module.grounded else 1.0, 1)
		materials.append(face_material)
		_box(center + Vector3(0, -height * 0.5, 0), Vector3(width, height, depth), dark, module.name + "Body")
		var front := MeshInstance3D.new()
		var front_mesh := QuadMesh.new()
		front_mesh.size = Vector2(width, height)
		front.mesh = front_mesh
		front.position = center + Vector3(0, -height * 0.5, depth * 0.5 + 0.001)
		front.material_override = face_material
		front.name = module.name + "FrontMasonry"
		scenery.add_child(front)
		var top_material: StandardMaterial3D = paving.duplicate()
		top_material.uv1_scale = Vector3(width / 1.28, depth / 1.28, 1)
		materials.append(top_material)
		var top := MeshInstance3D.new()
		var top_mesh := PlaneMesh.new()
		top_mesh.size = Vector2(width, depth)
		top.mesh = top_mesh
		top.position = center + Vector3(0, 0.001, 0)
		top.material_override = top_material
		top.name = module.name + "Top"
		scenery.add_child(top)
		top.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# Physical standing plane is z=0, visibly marked without expanding collision.
		_box(Vector3(center.x, center.y + 0.003, 0), Vector3(width, 0.008, 0.014), edge, module.name + "StandingEdge")
		_build_platform_railing(module, dark, gold)
		if module.one_way:
			for end in [-1, 1]:
				_box(center + Vector3(end * (width * 0.5 - 0.08), -0.35, -0.58), Vector3(0.13, 0.65, 0.18), dark, "BridgeBracket")
		var pieces: Array[Node] = []
		for child_index in range(first_child, scenery.get_child_count()):
			var piece := scenery.get_child(child_index)
			piece.visible = module.active
			pieces.append(piece)
		platform_visuals[module] = pieces
	var room_root := scenery
	var foreground := preload("res://scenes/rooms/near_foreground.tscn").instantiate()
	foreground.name = "NearForeground"
	if game.environment.get("campaign"):
		foreground.position.y = -15.4
	room_root.add_child(foreground)
	for piece in foreground.find_children("*", "MeshInstance3D", true, false):
		if not materials.has(piece.material_override): materials.append(piece.material_override)
	if game.environment.get("campaign"):
		for index in [1, 2]:
			var extension := foreground.duplicate()
			extension.position.x = index * 48.0
			room_root.add_child(extension)
	for section in game.environment.visual_sections:
		var group := Node3D.new()
		group.name = "SectionArchitecture"
		group.position = to_stage(section.offset)
		room_root.add_child(group)
		scenery = group
		_build_backdrop(dark, gold)
		_build_room_identity(dark, gold, stone, section.architecture)
		scenery = room_root
	_build_room_finish(dark, gold)

func _build_room_finish(dark: Material, gold: Material) -> void:
	door_material = _material(Rect2(), Color("675362"), "wood")
	door_material.emission_enabled = true
	door_material.emission = Color("080308")
	door_material.emission_energy_multiplier = 0.3
	_box(to_stage(game.environment.exit_position, -0.63) + Vector3(0, 0.33, 0), Vector3(0.4, 0.66, 0.09), door_material, "ExitDoor")
	var door_origin := to_stage(game.environment.exit_position, -0.56)
	for side in [-1, 1]:
		_box(door_origin + Vector3(side * 0.235, 0.35, 0), Vector3(0.065, 0.7, 0.12), dark, "DoorFrame")
	_box(door_origin + Vector3(0, 0.72, 0), Vector3(0.54, 0.075, 0.14), gold, "DoorLintel")
	_box(door_origin + Vector3(0.12, 0.3, 0.08), Vector3(0.03, 0.08, 0.025), gold, "DoorHandle")
	for action in game.environment.actions:
		_build_action(action, dark, gold)
	var shadow_image := Image.create(32, 16, false, Image.FORMAT_RGBA8)
	for y in 16:
		for x in 32:
			if Vector2((x - 15.5) / 15.5, (y - 7.5) / 7.5).length_squared() <= 1:
				shadow_image.set_pixel(x, y, Color.WHITE)
	var shadow_texture := ImageTexture.create_from_image(shadow_image)
	for i in game.enemies.size() + 1:
		var shadow := MeshInstance3D.new()
		var plane := PlaneMesh.new()
		plane.size = Vector2(0.23, 0.11)
		shadow.mesh = plane
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = Color(0.035, 0.025, 0.05, 0.5)
		mat.albedo_texture = shadow_texture
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		shadow.material_override = mat
		shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		scenery.add_child(shadow)
		shadow_cards.append(shadow)

func _build_backdrop(dark: Material, gold: Material) -> void:
	# Columns stand on rear masonry corbels, entirely behind the playable slabs.
	for x in [0.25, 3.25, 6.25, 9.4]:
		var floor_y := _support_height(x, 0.22, -0.90, 0.25)
		if not is_finite(floor_y): continue
		_box(Vector3(x, floor_y - 0.10, -1.45), Vector3(0.44, 0.20, 0.55), dark, "PillarCorbel")
		_box(Vector3(x, floor_y + 2, -1.46), Vector3(0.24, 4, 0.35), dark, "RearPillar")
		_box(Vector3(x, floor_y + 0.16, -1.46), Vector3(0.4, 0.32, 0.5), dark, "PillarFoot")
		_prop(PaperStage.COLUMN_REGION, Vector3(x, floor_y, -1.20), 0.004, Color("a59aaa"))
	for x in [0.6, 3.35, 6.0, 8.6]:
		var floor_y := _support_height(x, 0.15, -0.38, 0.05)
		if not is_finite(floor_y): continue
		_prop(PaperStage.CANDLE_REGION, Vector3(x, floor_y, -0.38), 0.0013, Color.WHITE)
		var light := OmniLight3D.new()
		light.name = "CandleLight"
		light.position = Vector3(x, floor_y + 0.60, -0.15)
		light.light_color = Color("ffb573")
		light.light_energy = 1.45
		light.omni_range = 1.55
		light.shadow_enabled = true
		scenery.add_child(light)

func _cylinder(at: Vector3, bottom: float, top: float, height: float, material: Material, label: String) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = bottom
	mesh.top_radius = top
	mesh.height = height
	mesh.radial_segments = 12
	var node := MeshInstance3D.new()
	node.name = label
	node.mesh = mesh
	node.material_override = material
	node.position = at
	scenery.add_child(node)
	return node

func _build_room_identity(dark: Material, gold: Material, stone: Material, section_architecture: int) -> void:
	match section_architecture:
		1:
			# A real bell, beams and ropes create depth without painting fake platforms.
			if game.environment.get("campaign") and (not is_finite(_support_height(5.95, 0.10, -0.88, 0.10)) or not is_finite(_support_height(7.85, 0.10, -0.88, 0.10))): return
			for x in [5.95, 7.85]:
				var floor_y := _support_height(x, 0.10, -0.88, 0.10)
				if is_finite(floor_y):
					_box(Vector3(x, (floor_y + 0.1) * 0.5, -0.88), Vector3(0.20, 0.1 - floor_y, 0.20), dark, "BellPost")
			_box(Vector3(6.9, 0.1, -0.88), Vector3(2.1, 0.18, 0.3), dark, "BellCrossbeam")
			_box(Vector3(6.9, -0.045, -0.88), Vector3(0.06, 0.29, 0.06), gold, "BellHanger")
			_cylinder(Vector3(6.9, -0.45, -0.88), 0.48, 0.22, 0.7, gold, "AlarmBell")
			bell_clapper = _cylinder(Vector3(6.9, -0.92, -0.88), 0.06, 0.04, 0.3, gold, "BellClapper")
			_box(Vector3(7.36, -0.7, -0.88), Vector3(0.018, 1.6, 0.018), _material(Rect2(), Color("b4a18c"), "rope"), "BellRope")
			alarm_light = OmniLight3D.new()
			alarm_light.position = Vector3(6.9, -1.3, -0.3)
			alarm_light.light_color = Color("ff4654")
			alarm_light.omni_range = 3.4
			scenery.add_child(alarm_light)
		2:
			var wood := _material(Rect2(), Color("998690"), "wood")
			var book_colors := ["714852", "62596c", "787058", "3d6366"]
			for bay in 5:
				var x := 1.1 + bay * 1.8
				var floor_y := _support_height(x, 0.75, -0.90, 0.24)
				if not is_finite(floor_y): continue
				_box(Vector3(x, floor_y - 0.10, -1.4875), Vector3(1.5, 0.20, 0.625), stone, "ArchiveCorbel")
				_box(Vector3(x, floor_y + 1.3, -1.58), Vector3(1.35, 2.6, 0.22), wood, "ArchiveBack")
				for row in 4:
					var y := floor_y + 0.035 + row * 0.62
					_box(Vector3(x, y, -1.50), Vector3(1.42, 0.07, 0.48), wood, "Bookshelf")
					for book in 6:
						var mat := _material(Rect2(), Color(book_colors[(book + row + bay) % 4]), "leather")
						var height := 0.36 + (book % 2) * 0.08
						_box(Vector3(x - 0.5 + book * 0.2, y + 0.035 + height * 0.5, -1.43), Vector3(0.12, height, 0.17), mat, "BookSpine")
		3:
			var rose_texture := preload("res://assets/environments/crimson/rose_bush_v1.png")
			var crop := rose_texture.get_image().get_used_rect()
			for x in [1.44, 3.28, 4.72, 7.20, 8.96]:
				var floor_y := _rose_support_height(x)
				if not is_finite(floor_y): continue
				_box(Vector3(x, floor_y + 0.09, -0.65), Vector3(0.64, 0.18, 0.55), stone, "RosePlanter")
				var bush := Sprite3D.new()
				bush.name = "RoseBush"
				bush.texture = rose_texture
				bush.region_enabled = true
				bush.region_rect = crop
				bush.pixel_size = 0.58 / crop.size.x
				bush.position = Vector3(x, floor_y + 0.18 + crop.size.y * bush.pixel_size * 0.5, -0.50)
				bush.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
				bush.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
				bush.shaded = true
				scenery.add_child(bush, true)

func _build_action(action: RoomAction, dark: Material, gold: Material) -> void:
	var at := to_stage(action.position, -0.18)
	var quest_regions := {
		"tools": Rect2(49, 118, 627, 526),
		"records": Rect2(760, 183, 652, 461),
		"luggage": Rect2(1493, 252, 634, 399)
	}
	if campaign_enabled and quest_regions.has(action.action_id):
		var prop := Sprite3D.new()
		prop.name = "QuestProp_" + action.action_id
		prop.texture = preload("res://assets/environments/crimson/quest_props_v1.png")
		prop.region_enabled = true
		prop.region_rect = quest_regions[action.action_id]
		prop.pixel_size = 0.28 / prop.region_rect.size.x
		if action.action_id == "luggage" and game.environment.has_method("set_luggage_home"):
			prop.pixel_size = 0.56 / prop.region_rect.size.x
			at.y -= 0.36
			at.z = -0.02
		prop.position = at + Vector3(0, prop.region_rect.size.y * prop.pixel_size * 0.5, 0)
		prop.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		prop.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		prop.alpha_scissor_threshold = 0.12
		prop.shaded = true
		prop.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		scenery.add_child(prop)
		action_visuals[action] = {"piece": prop, "quest": action.action_id}
		return
	if action.has_meta("shortcut_gate"):
		# Freight mouths are actual framed openings behind the play plane.
		for side in [-1.0, 1.0]:
			_box(at + Vector3(side * 0.42, 0.5, -1.12), Vector3(0.12, 1.0, 0.18), dark, "FreightDoorJamb")
		_box(at + Vector3(0, 1.04, -1.12), Vector3(0.96, 0.12, 0.18), gold, "FreightDoorLintel")
		_box(at + Vector3(0, -0.05, -0.88), Vector3(0.96, 0.10, 0.66), dark, "FreightThreshold")
	var surface := "parchment" if action.kind == RoomAction.Kind.NOTE else ("glass" if action.kind == RoomAction.Kind.SUPPLY else "brass")
	var indicator := _material(Rect2(), Color("d8b96f"), surface)
	indicator.emission_enabled = true
	indicator.emission = Color("715225")
	indicator.emission_energy_multiplier = 0.4
	var piece: MeshInstance3D
	match action.kind:
		RoomAction.Kind.SWITCH:
			_box(at + Vector3(0, 0.12, 0), Vector3(0.19, 0.24, 0.18), dark, "SwitchBase")
			piece = _box(at + Vector3(0, 0.29, 0), Vector3(0.035, 0.25, 0.035), indicator, "SwitchHandle")
			piece.rotation.z = -0.5
		RoomAction.Kind.NOTE:
			_box(at + Vector3(0, 0.15, 0), Vector3(0.24, 0.3, 0.18), dark, "ReadingStand")
			piece = _box(at + Vector3(0, 0.32, 0.03), Vector3(0.22, 0.018, 0.16), indicator, "OpenRecord")
		RoomAction.Kind.SUPPLY:
			piece = _cylinder(at + Vector3(0, 0.09, 0), 0.055, 0.045, 0.18, indicator, "BloodVial")
	var label := Label3D.new()
	label.text = "E"
	label.font_size = 32
	label.pixel_size = 0.002
	label.position = at + Vector3(0, 0.55, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color("ffe5a5")
	scenery.add_child(label)
	action_visuals[action] = {"piece": piece, "material": indicator, "label": label}

func _prop(region: Rect2, foot: Vector3, pixel_size: float, tint: Color) -> void:
	var sprite := Sprite3D.new()
	sprite.texture = PaperStage.ATLAS
	sprite.region_enabled = true
	sprite.region_rect = region
	sprite.pixel_size = pixel_size
	var opaque := PaperStage.ATLAS.get_image().get_region(Rect2i(region)).get_used_rect()
	var bottom_margin := region.size.y - opaque.end.y
	sprite.position = foot + Vector3(0, (region.size.y * 0.5 - bottom_margin) * pixel_size, 0)
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.alpha_scissor_threshold = 0.4
	sprite.modulate = tint
	sprite.shaded = true
	scenery.add_child(sprite)

func screen_to_world(screen: Vector2) -> Vector2:
	var origin := camera.project_ray_origin(screen)
	var direction := camera.project_ray_normal(screen)
	if absf(direction.z) < 0.0001:
		return game.player.aim_origin() + game.player.aim_direction * 100
	var point := origin + direction * (-origin.z / direction.z)
	return Vector2(point.x, -point.y) / PIXEL

func mouse_world() -> Vector2:
	return screen_to_world(reticle_screen() * RENDER_SCALE)

func camera_profile() -> Dictionary:
	return WEAPON_CAMERA.get(game.player.weapons.current().data.id, WEAPON_CAMERA[&"revolver"])

func raw_cursor() -> Vector2:
	return ui_host.get_aim_screen() if ui_host != null else get_viewport().get_mouse_position() / RENDER_SCALE

func reticle_screen() -> Vector2:
	# Full-screen aim for every gun; the outer 10% adds offscreen reach.
	var cursor := raw_cursor().clamp(Vector2.ZERO, Vector2(320, 180))
	var normalized := (cursor - Vector2(160, 90)) / Vector2(160, 90)
	var extension := Vector2(
		signf(normalized.x) * smoothstep(0.9, 1.0, absf(normalized.x)),
		signf(normalized.y) * smoothstep(0.9, 1.0, absf(normalized.y)))
	return cursor + extension * camera_profile().outside

func edge_look_amount() -> float:
	# Zoom uses the raw pointer, independent of offscreen aim extension.
	var normalized := (raw_cursor() - Vector2(160, 90)) / Vector2(160, 90)
	return smoothstep(0.72, 0.98, maxf(absf(normalized.x), absf(normalized.y)))

func _input(event: InputEvent) -> void:
	if not is_instance_valid(game):
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F6:
		set_greybox(not greybox)
		game.overlay.show_notice("3D GREYBOX" if greybox else "CRIMSON MONASTERY / TEXTURES")
		get_viewport().set_input_as_handled()
		return
	game._input(event)

func set_greybox(enabled: bool) -> void:
	greybox = enabled
	for material in materials:
		material.albedo_texture = null if enabled else material.get_meta("authored_texture")

func _physics_process(delta: float) -> void:
	if not is_instance_valid(game) or not is_instance_valid(game.player) or game.paused:
		return
	if not frozen_camera:
		_update_camera(delta)
	_update_actor_window()
	night.follow_camera(camera.position, camera)
	if is_instance_valid(foreground): foreground.call("follow_camera", camera)
	if campaign_enabled and residency_enabled: residency.update_at(game.player.position)
	for module in platform_visuals:
		for piece in platform_visuals[module]: piece.visible = module.active
	for visual in flow_visuals:
		visual.piece.visible = game.campaign_session.has(visual.fact) == visual.show
	for action in action_visuals:
		var visual: Dictionary = action_visuals[action]
		if visual.has("quest"):
			var session = game.campaign_session
			var taken: bool = session.has("tools") if visual.quest == "tools" else false
			visual.piece.visible = not taken
			if visual.quest == "luggage" and game.environment.has_method("set_luggage_home"):
				visual.piece.pixel_size = 0.56 / visual.piece.region_rect.size.x
				visual.piece.position = to_stage(action.position + Vector2(0, 36), -0.02) + Vector3(0, visual.piece.region_rect.size.y * visual.piece.pixel_size * 0.5, 0)
			visual.piece.modulate = Color("aba8a1") if visual.quest == "records" and session.has("records") else Color.WHITE
			continue
		visual.material.albedo_color = Color("5b938a") if action.activated else Color("d8b96f")
		# Campaign prompts are native-resolution and filtered by the session's
		# actual availability. Do not leave a second E over locked freight doors.
		visual.label.visible = not campaign_enabled and game.player.position.distance_to(action.position) < 65 and (not action.activated or action.kind == RoomAction.Kind.NOTE)
		if action.kind == RoomAction.Kind.SWITCH:
			visual.piece.rotation.z = lerpf(visual.piece.rotation.z, 0.6 if action.activated else -0.5, minf(1, delta * 8))
		elif action.kind == RoomAction.Kind.SUPPLY:
			visual.piece.visible = not action.activated
	if is_instance_valid(alarm_light):
		var ringing: bool = game.environment.alarm_active()
		alarm_light.light_energy = (0.8 + sin(game.elapsed * 4) * 0.3) if ringing else 0.0
		bell_clapper.rotation.z = sin(game.elapsed * 4) * 0.12 if ringing else 0.0
	muzzle_light.visible = game.player.flash_time > 0
	muzzle_light.position = to_stage(game.player.aim_origin() + game.player.aim_direction * 25, 0.15)
	if game.environment.exit_open:
		door_material.albedo_color = Color("69b7ad")
		door_material.emission = Color("245950")
	# Quest encounters may spawn after the initial room geometry was built.
	while shadow_cards.size() < game.enemies.size() + 1:
		var extra := shadow_cards[0].duplicate() as MeshInstance3D
		scenery.add_child(extra)
		shadow_cards.append(extra)
	for i in game.enemies.size() + 1:
		var actor: CharacterBody2D = game.player if i == 0 else game.enemies[i - 1]
		var query := PhysicsRayQueryParameters2D.create(actor.position + Vector2(0, -2), actor.position + Vector2(0, 162), 1 | 1024)
		var hit := actor.get_world_2d().direct_space_state.intersect_ray(query)
		shadow_cards[i].visible = not hit.is_empty() and actor.visible
		if not hit.is_empty():
			var altitude: float = maxf(0, hit.position.y - actor.position.y)
			shadow_cards[i].position = to_stage(hit.position) + Vector3(0, 0.006, 0)
			shadow_cards[i].rotation.z = atan2(hit.normal.x, -hit.normal.y)
			shadow_cards[i].scale = Vector3.ONE * lerpf(1, 0.4, clampf(altitude / 160, 0, 1))

func _update_camera(delta: float) -> void:
	var target_2d := game.player.position + Vector2(game.player.aim_direction.x * 20, -minf(52, camera_distance * 10))
	target_2d.x = clampf(target_2d.x, 150, game.environment.bounds.end.x - 150)
	if game.environment.get("campaign"):
		target_2d.y = clampf(target_2d.y, game.environment.bounds.position.y + 108, game.environment.bounds.end.y - 66)
	else:
		target_2d.y = clampf(target_2d.y, -20, 350)
	camera_target = camera_target.lerp(to_stage(target_2d), 1 - exp(-delta / 0.16))
	# A small, bounded dolly angle reveals side faces during movement, without orbit controls.
	var desired_yaw := clampf(game.player.velocity.x / 420, -1, 1) * 0.32
	yaw_offset = lerpf(yaw_offset, desired_yaw, 1 - exp(-delta / 0.3))
	var profile := camera_profile()
	var desired_distance := lerpf(profile.near, profile.far, edge_look_amount())
	camera_distance = lerpf(camera_distance, desired_distance, 1 - exp(-delta / 0.24))
	camera.position = camera_target + Vector3(yaw_offset, CAMERA_RISE, camera_distance)
	camera.look_at(camera_target, Vector3.UP)
	# The normal follow spring trails terminal-speed falls by more than a near
	# viewport. Translate its target with the camera before the feet leave view.
	var feet := camera.unproject_position(to_stage(game.player.position))
	var safe_bottom := camera.get_viewport().get_visible_rect().size.y * 0.86
	if feet.y > safe_bottom:
		var correction := (screen_to_world(Vector2(feet.x, safe_bottom)).y - game.player.position.y) * PIXEL
		camera_target.y += correction
		camera.position.y += correction

func _update_actor_window() -> void:
	# Keep the actor render target fixed-size as the continuous world grows.
	var center_x := roundf(clampf(camera.position.x / PIXEL, 480, game.environment.bounds.end.x - 480))
	var center_y := 144.0
	if game.environment.get("campaign"):
		center_y = roundf(clampf(game.player.position.y - 56, game.environment.bounds.position.y + 272, game.environment.bounds.end.y - 272))
	actors.position = to_stage(Vector2(center_x, center_y))
	simulation.canvas_transform = Transform2D(Vector2(RENDER_SCALE, 0), Vector2(0, RENDER_SCALE), Vector2((480 - center_x) * RENDER_SCALE, (272 - center_y) * RENDER_SCALE))
