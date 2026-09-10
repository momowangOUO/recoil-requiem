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
var door_material: StandardMaterial3D
var ui_host: Node

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
	_build_room()
	set_greybox(greybox)
	camera_target = to_stage(game.player.position + Vector2(0, -56))
	yaw_offset = 0
	camera_distance = camera_profile().near
	_update_camera(1.0)

func _material(region: Rect2, color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.88
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	if region.has_area():
		var source := PaperStage.ATLAS.get_image().get_region(Rect2i(region))
		material.albedo_texture = ImageTexture.create_from_image(source)
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
	scenery.add_child(node)
	return node

func _build_room() -> void:
	# Plain masonry for structural faces; the arch motif belongs to architecture only.
	var stone := _material(Rect2(668, 42, 526, 62), Color("8e829f"))
	var paving := _material(PaperPlatform.TOP_REGION, Color("a39aa9"))
	var dark := _material(Rect2(), Color("282531"))
	var edge := _material(Rect2(), Color("a59aaa"))
	var gold := _material(Rect2(), Color("84705a"))
	for module in game.environment.modules:
		var width: float = module.width * PIXEL
		# A thick fake slab would hide a 38px actor under a 48px-high platform.
		var height: float = module.collision_depth * PIXEL if module.one_way else 0.64
		var depth := 1.18 if module.one_way else 1.85
		var center := to_stage(module.position + Vector2(module.width * 0.5, 0), -0.25)
		var face_material: StandardMaterial3D = stone.duplicate()
		face_material.uv1_scale = Vector3(maxf(1, width / 0.96), 1, 1)
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
		if module.one_way:
			for end in [-1, 1]:
				_box(center + Vector3(end * (width * 0.5 - 0.08), -0.35, -0.58), Vector3(0.13, 0.65, 0.18), dark, "BridgeBracket")
	# Rear architecture and real front columns occupy separate depth planes.
	for x in [0.25, 3.25, 6.25, 9.4]:
		_box(Vector3(x, -1.52, -1.5), Vector3(0.24, 4, 0.35), dark, "RearPillar")
		_box(Vector3(x, -3.36, -1.5), Vector3(0.4, 0.32, 0.5), dark, "PillarFoot")
		_prop(PaperStage.COLUMN_REGION, Vector3(x, -3.5, -1.27), 0.004, Color("a59aaa"))
	for x in [-0.45, 10.05]:
		_box(Vector3(x, -1.5, 1.0), Vector3(0.38, 4.2, 0.5), dark, "ForegroundPillar")
	# Rear railing is behind the actors and does not cover their hands or targets.
	for x in range(0, 49):
		_box(Vector3(x * 0.2, -3.3, -0.85), Vector3(0.025, 0.4, 0.025), dark, "RearRailing")
	_box(Vector3(4.8, -3.09, -0.85), Vector3(9.6, 0.035, 0.05), gold, "RailingCap")
	var background := Sprite3D.new()
	background.name = "DistantWindows"
	background.texture = preload("res://assets/environments/crimson/skyline_v2.png")
	background.pixel_size = 0.008
	background.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	background.position = Vector3(4.8, -4.7, -4)
	background.modulate = Color("9c9aad")
	background.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	scenery.add_child(background)
	for x in [0.6, 3.35, 6.0, 8.6]:
		_prop(PaperStage.CANDLE_REGION, Vector3(x, -3.52, -0.38), 0.0013, Color.WHITE)
		var light := OmniLight3D.new()
		light.name = "CandleLight"
		light.position = Vector3(x, -2.92, -0.15)
		light.light_color = Color("ffb573")
		light.light_energy = 1.45
		light.omni_range = 1.55
		light.shadow_enabled = true
		scenery.add_child(light)
	door_material = _material(Rect2(), Color("211a25"))
	door_material.emission_enabled = true
	door_material.emission = Color("080308")
	door_material.emission_energy_multiplier = 0.3
	_box(to_stage(game.environment.exit_position, -0.63) + Vector3(0, 0.33, 0), Vector3(0.4, 0.66, 0.09), door_material, "ExitDoor")
	var door_origin := to_stage(game.environment.exit_position, -0.56)
	for side in [-1, 1]:
		_box(door_origin + Vector3(side * 0.235, 0.35, 0), Vector3(0.065, 0.7, 0.12), dark, "DoorFrame")
	_box(door_origin + Vector3(0, 0.72, 0), Vector3(0.54, 0.075, 0.14), gold, "DoorLintel")
	_box(door_origin + Vector3(0.12, 0.3, 0.08), Vector3(0.03, 0.08, 0.025), gold, "DoorHandle")
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

func _prop(region: Rect2, foot: Vector3, pixel_size: float, tint: Color) -> void:
	var sprite := Sprite3D.new()
	sprite.texture = PaperStage.ATLAS
	sprite.region_enabled = true
	sprite.region_rect = region
	sprite.pixel_size = pixel_size
	sprite.position = foot + Vector3(0, region.size.y * pixel_size * 0.5, 0)
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
	muzzle_light.visible = game.player.flash_time > 0
	muzzle_light.position = to_stage(game.player.aim_origin() + game.player.aim_direction * 25, 0.15)
	if game.environment.exit_open:
		door_material.albedo_color = Color("69b7ad")
		door_material.emission = Color("245950")
	for i in game.enemies.size() + 1:
		var actor: CharacterBody2D = game.player if i == 0 else game.enemies[i - 1]
		var query := PhysicsRayQueryParameters2D.create(actor.position + Vector2(0, -2), actor.position + Vector2(0, 162), 1 | 1024)
		var hit := actor.get_world_2d().direct_space_state.intersect_ray(query)
		shadow_cards[i].visible = not hit.is_empty()
		if not hit.is_empty():
			var altitude: float = maxf(0, hit.position.y - actor.position.y)
			shadow_cards[i].position = to_stage(hit.position) + Vector3(0, 0.006, 0)
			shadow_cards[i].scale = Vector3.ONE * lerpf(1, 0.4, clampf(altitude / 160, 0, 1))

func _update_camera(delta: float) -> void:
	var target_2d := game.player.position + Vector2(game.player.aim_direction.x * 20, -minf(52, camera_distance * 10))
	target_2d.x = clampf(target_2d.x, 150, 810)
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
