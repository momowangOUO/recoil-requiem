extends SceneTree

var checks := 0
var failures := 0

func _initialize() -> void: run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func _plane_hit(camera: Camera3D, screen: Vector2) -> Vector3:
	var origin := camera.project_ray_origin(screen)
	var ray := camera.project_ray_normal(screen)
	return origin + ray * ((2.35 - origin.z) / ray.z)

func _alpha_at(card: Sprite3D, point: Vector3, pixels: Image) -> float:
	var sample_size := card.texture.get_size() * card.pixel_size * Vector2(card.scale.x, card.scale.y)
	var half := sample_size * 0.5
	var local := point - card.global_position
	var x := int((local.x + half.x) / (card.pixel_size * card.scale.x))
	var y := int((half.y - local.y) / (card.pixel_size * card.scale.y))
	var material := card.material_override as ShaderMaterial
	var extension: float = material.get_shader_parameter("base_extension")
	if y >= pixels.get_height() and local.y >= -half.y - extension:
		y = pixels.get_height() - 1
	if x < 0 or y < 0 or x >= pixels.get_width() or y >= pixels.get_height():
		return 0.0
	return pixels.get_pixel(x, y).a

func _alpha_at_any(cards: Array, point: Vector3) -> float:
	var alpha := 0.0
	for card: Sprite3D in cards:
		alpha = maxf(alpha, _alpha_at(card, point, card.texture.get_image()))
	return alpha

func _base_reaches(cards: Array, point: Vector3) -> bool:
	# A very close view may look above the whole world-anchored contour. That is
	# natural parallax, not a floating strip; its physical bottom must stay out of view.
	for card: Sprite3D in cards:
		var bounds := card.custom_aabb
		var local := point - card.global_position
		if local.x >= bounds.position.x and local.x <= bounds.end.x:
			if bounds.position.y > local.y: continue
			var original_bottom := -card.texture.get_height() * card.pixel_size * 0.5
			return local.y > original_bottom or _alpha_at(card, point, card.texture.get_image()) > 0.5
	return false

func run() -> void:
	var app = load("res://scenes/game.tscn").instantiate()
	root.add_child(app)
	var stage: CrimsonStage3D = app.stage
	stage.frozen_camera = true
	stage.game.player.set_physics_process(false)
	var front: Node3D = stage.foreground
	check(front != null and front.name == "ImageMonasteryForeground", "Main map has one dedicated painted foreground")
	check(front.get_child_count() == 7, "Foreground uses a seven-card world-anchored panorama strip")
	check(front.find_children("*", "CollisionObject3D", true, false).is_empty(), "Foreground cannot affect collision")
	var cards: Array = front.find_children("PaintedNearWall*", "Sprite3D", false, false)
	check(cards.size() == 7, "Foreground has seven reusable authored cards")
	for card: Sprite3D in cards:
		check(card.texture.resource_path.ends_with("foreground_panorama_v4.png") and card.texture.get_image().detect_alpha() != Image.ALPHA_NONE,
			"Foreground uses transparent generated artwork")
		check(card.texture_filter == BaseMaterial3D.TEXTURE_FILTER_LINEAR and not card.shaded,
			"Only the near painted layer has a gently softened contour")
		check(is_equal_approx(card.scale.x, card.scale.y), "Foreground preserves the authored panorama proportions")
		check(card.material_override is ShaderMaterial and card.material_override.get_shader_parameter("silhouette_color").v < 0.15,
			"Foreground uses the authored alpha as a near-black silhouette mask")
		check(card.get_meta("world_anchored", false), "Foreground cards explicitly retain world-space horizontal anchors")
	for i in range(1, cards.size()):
		check(is_equal_approx(cards[i].position.x - cards[i - 1].position.x, cards[i].get_meta("tile_width", 0.0)),
			"Foreground card spacing matches its fixed authored width")
	stage.camera.position.x = 40.2
	front.call("follow_camera", stage.camera)
	var stable_x := PackedFloat32Array()
	for card: Sprite3D in cards: stable_x.append(card.position.x)
	stage.camera.position.x = 40.4
	front.call("follow_camera", stage.camera)
	for i in cards.size():
		check(is_equal_approx(cards[i].position.x, stable_x[i]), "Foreground does not drift with sub-tile camera motion")
	var stable_y := PackedFloat32Array()
	for card: Sprite3D in cards: stable_y.append(card.position.y)
	stage.camera.position.y += 0.5
	front.call("follow_camera", stage.camera)
	for i in cards.size():
		check(is_equal_approx(cards[i].position.y, stable_y[i]), "Foreground vertical anchor ignores camera-only jump motion")
	stage.camera.position.y -= 0.5
	check(not front.call("should_reanchor", false, 0.42), "Ordinary airborne motion cannot re-anchor the foreground")
	check(front.call("should_reanchor", true, 0.05), "Ground contact may update the terrain anchor")
	check(front.call("should_reanchor", false, 1.3), "Only a single-frame teleport may update an airborne anchor")
	var landing_start := 2.0
	var landing_target := 2.7
	var landing_first: float = front.call("advance_ground_anchor", landing_start, landing_target, true, false)
	check(landing_first > landing_start and landing_first < landing_target and landing_first - landing_start <= 0.031,
		"Landing on a different-height platform begins a bounded terrain-anchor transition")
	check(is_equal_approx(front.call("advance_ground_anchor", landing_first, landing_target, false, false), landing_first),
		"Airborne frames hold the foreground at the last resolved terrain anchor")
	var landing_resolved := landing_first
	for step in 30:
		landing_resolved = front.call("advance_ground_anchor", landing_resolved, landing_target, true, false)
	check(is_equal_approx(landing_resolved, landing_target),
		"Sustained ground contact smoothly resolves a different-height landing")
	check(is_equal_approx(front.call("advance_ground_anchor", landing_start, landing_target, false, true), landing_target),
		"A genuine teleport snaps the terrain anchor instead of visibly chasing it")
	for location in [Vector2(700, 1120), Vector2(5200, 688), Vector2(9592, 932),
		Vector2(10500, 1424), Vector2(13800, 1424), Vector2(13000, 2720)]:
		for profile in CrimsonStage3D.WEAPON_CAMERA.values():
			for distance in [profile.near, profile.far]:
				stage.game.player.position = location
				var target := CrimsonStage3D.to_stage(location + Vector2(0, -minf(52, distance * 10)))
				stage.camera.position = target + Vector3(0.12, CrimsonStage3D.CAMERA_RISE, distance)
				stage.camera.look_at(target)
				front.call("reset_ground_anchor")
				front.call("follow_camera", stage.camera)
				var width := stage.camera.get_viewport().get_visible_rect().size.x
				var height := stage.camera.get_viewport().get_visible_rect().size.y
				for fraction in [0.0, 0.25, 0.5, 0.75, 1.0]:
					var bottom_sample := _plane_hit(stage.camera, Vector2(width * fraction, height * 0.995))
					check(_base_reaches(cards, bottom_sample),
						"Foreground covers bottom edge at %s / %s / %s" % [location, distance, fraction])
				var action_center := _plane_hit(stage.camera, Vector2(width * 0.5, height * 0.54))
				check(_alpha_at_any(cards, action_center) < 0.1,
					"Foreground leaves the central action readable at %s / %s" % [location, distance])
	# Preserve the near-view anchor through zoom: resetting at every pose hid the floating base.
	stage.game.player.position = Vector2(700, 1120)
	for weapon in CrimsonStage3D.WEAPON_CAMERA:
		var profile: Dictionary = CrimsonStage3D.WEAPON_CAMERA[weapon]
		front.call("reset_ground_anchor")
		var anchor_y := 0.0
		for step in 61:
			var distance: float = lerpf(profile.near, profile.far, float(step if step <= 30 else 60 - step) / 30.0)
			var target := CrimsonStage3D.to_stage(stage.game.player.position + Vector2(0, -minf(52, distance * 10)))
			stage.camera.position = target + Vector3(0.12, CrimsonStage3D.CAMERA_RISE, distance)
			stage.camera.look_at(target)
			front.call("follow_camera", stage.camera)
			if step == 0: anchor_y = cards[3].position.y
			check(is_equal_approx(cards[3].position.y, anchor_y), "Continuous zoom preserves the authored contour anchor")
			var viewport_size := stage.camera.get_viewport().get_visible_rect().size
			# The visible contour must not cover the player's feet/landing line.
			var feet_screen := stage.camera.unproject_position(CrimsonStage3D.to_stage(stage.game.player.position))
			for foot_x in [-12.0, 0.0, 12.0]:
				check(_alpha_at_any(cards, _plane_hit(stage.camera, feet_screen + Vector2(foot_x, 0))) < 0.1,
					"Continuous zoom keeps the landing line visible: %s step %d" % [weapon, step])
			for fraction in [0.0, 0.25, 0.5, 0.75, 1.0]:
				check(_base_reaches(cards, _plane_hit(stage.camera, viewport_size * Vector2(fraction, 0.995))),
					"Continuous zoom must not expose foreground bottom: %s step %d x %s" % [weapon, step, fraction])
			if step in [0, 30, 60] and DisplayServer.get_name() != "headless":
				await process_frame
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://artifacts/foreground_zoom_%s_%d.png" % [weapon, step])
	var landmarks := {"B01PaintedGatehouse": Vector2(2200, 1120),
		"B02PaintedCargoHouse": Vector2(3900, 1408),
		"B04PaintedTowerPier": Vector2(7300, 1120),
		"B05PaintedTowerPier": Vector2(9200, 1120),
		"B12PaintedGreatHall": Vector2(14300, 1424),
		"B12PaintedLowerWing": Vector2(14300, 1424),
		"ArchivePaintedSideHouse": Vector2(6700, 1120),
		"BellStairwellPaintedFacade": Vector2(9500, 1120),
		"GalleryPaintedFrontage": Vector2(5200, 688),
		"F08PaintedServiceFrontage": Vector2(4200, 2280),
		"F11PaintedServiceFrontage": Vector2(13800, 2720)}
	for name in landmarks:
		stage.camera_target = CrimsonStage3D.to_stage(landmarks[name])
		stage.residency.update_at(landmarks[name])
		var landmark_cards: Array = stage.scenery.find_children(name, "GeometryInstance3D", true, false)
		check(landmark_cards.size() == 1, name + " needs exactly one authored elevation")
		if landmark_cards.size() == 1:
			var landmark: GeometryInstance3D = landmark_cards[0]
			var crisp: bool = landmark.texture_filter == BaseMaterial3D.TEXTURE_FILTER_NEAREST if landmark is Sprite3D else landmark.material_override.texture_filter == BaseMaterial3D.TEXTURE_FILTER_NEAREST
			check(crisp and landmark.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
				name + " retains crisp art without fake structural shadows")
		var layer_prefix: String = {
			"B01PaintedGatehouse": "B01LayeredWindow",
			"B02PaintedCargoHouse": "B02LayeredWindow",
			"B12PaintedGreatHall": "B12LayeredWindow",
			"GalleryPaintedFrontage": "GalleryLayeredWindow",
			"F11PaintedServiceFrontage": "F11LayeredWindow",
		}.get(name, "")
		if not layer_prefix.is_empty():
			var glass_cards := stage.scenery.find_children(layer_prefix + "*Glass", "Sprite3D", true, false)
			var recesses := stage.scenery.find_children(layer_prefix + "*Recess", "MeshInstance3D", true, false)
			var frames := stage.scenery.find_children(layer_prefix + "*Frame*", "MeshInstance3D", true, false)
			check(glass_cards.size() >= 2, name + " separates at least two authored windows from the wall card")
			check(recesses.size() == glass_cards.size(), name + " gives every detached window a dark inner recess")
			check(frames.size() >= glass_cards.size() * 2, name + " gives detached windows projecting frame geometry")
			check(landmark_cards[0] is MeshInstance3D, name + " wall elevation has real openings rather than covered painted windows")
			for glass_card: Sprite3D in glass_cards:
				check(glass_card.position.z < glass_card.get_meta("wall_z", glass_card.position.z),
					name + " glass sits behind the wall plane and its projecting sill")
			if name == "F11PaintedServiceFrontage" and not glass_cards.is_empty():
				var backing: MeshInstance3D = stage.scenery.find_child("F11InteriorBackwall", true, false)
				var backing_front: float = backing.position.z + backing.mesh.get_aabb().end.z
				check(backing_front < glass_cards[0].position.z,
					"Lower-room structural backing stays behind the recessed glass")
	for old_name in ["B02WindowFrame*", "GalleryOpenGothicBay*", "HallLowerBlindArcade*", "S10TunnelBackwall*"]:
		check(stage.scenery.find_children(old_name, "MeshInstance3D", true, false).is_empty(), old_name + " should not cover painted architecture")
	stage.camera_target = CrimsonStage3D.to_stage(Vector2(9200, 1120))
	stage.residency.update_at(Vector2(9200, 1120))
	check(not stage.scenery.find_children("B05TowerPier", "MeshInstance3D", true, false).is_empty(), "Tower landing keeps a physical support")
	stage.camera_target = CrimsonStage3D.to_stage(Vector2(14300, 1424))
	stage.residency.update_at(Vector2(14300, 1424))
	check(not stage.scenery.find_children("B12ContinuedFoundation", "MeshInstance3D", true, false).is_empty(), "Hall drawing keeps a closed lower foundation")
	stage.camera_target = CrimsonStage3D.to_stage(Vector2(900, 1120))
	stage.residency.update_at(Vector2(900, 1120))
	check(stage.scenery.find_children("StationRearWall", "MeshInstance3D", true, false).is_empty(),
		"Arrival station does not restore the giant flat timber backwall")
	check(stage.scenery.find_children("StationPaintedDepot", "MeshInstance3D", true, false).size() == 1,
		"Arrival station uses one authored cut-paper depot elevation")
	check(stage.scenery.find_children("StationPaintedDepotGlass", "Sprite3D", true, false).size() == 1,
		"Arrival depot separates its authored narrow glass from wall and projecting sill")
	stage.game.reset_trial(3)
	await process_frame
	check(stage.scenery.find_children("ImageMonasteryForeground", "Node3D", true, false).size() == 1,
		"Reset does not duplicate the continuous foreground")
	app.free()
	print("IMAGE PAPER LAYERS STAGE RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
