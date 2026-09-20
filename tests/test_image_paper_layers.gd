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
	var half := card.texture.get_size() * card.pixel_size * 0.5
	var local := point - card.global_position
	var x := int((local.x + half.x) / card.pixel_size)
	var y := int((half.y - local.y) / card.pixel_size)
	if x < 0 or y < 0 or x >= pixels.get_width() or y >= pixels.get_height():
		return 0.0
	return pixels.get_pixel(x, y).a

func run() -> void:
	var app = load("res://scenes/game.tscn").instantiate()
	root.add_child(app)
	var stage: CrimsonStage3D = app.stage
	stage.frozen_camera = true
	stage.game.player.set_physics_process(false)
	var front: Node3D = stage.foreground
	check(front != null and front.name == "ImageMonasteryForeground", "Main map has one dedicated painted foreground")
	check(front.get_child_count() == 1 and front.get_child(0) is Sprite3D, "Foreground uses one authored panorama instead of sparse wall fragments")
	check(front.find_children("*", "CollisionObject3D", true, false).is_empty(), "Foreground cannot affect collision")
	var card: Sprite3D = front.get_child(0)
	check(card.texture.resource_path.ends_with("foreground_panorama_v3.png") and card.texture.get_image().detect_alpha() != Image.ALPHA_NONE,
		"Foreground uses transparent generated artwork")
	check(card.texture_filter == BaseMaterial3D.TEXTURE_FILTER_LINEAR and not card.shaded,
		"Only the near painted layer has a gently softened contour")
	var pixels := card.texture.get_image()
	for location in [Vector2(700, 1120), Vector2(5200, 688), Vector2(9592, 932),
		Vector2(10500, 1424), Vector2(13800, 1424), Vector2(13000, 2720)]:
		for profile in CrimsonStage3D.WEAPON_CAMERA.values():
			for distance in [profile.near, profile.far]:
				var target := CrimsonStage3D.to_stage(location + Vector2(0, -minf(52, distance * 10)))
				stage.camera.position = target + Vector3(0.12, CrimsonStage3D.CAMERA_RISE, distance)
				stage.camera.look_at(target)
				front.call("follow_camera", stage.camera)
				var width := stage.camera.get_viewport().get_visible_rect().size.x
				var height := stage.camera.get_viewport().get_visible_rect().size.y
				for fraction in [0.0, 0.25, 0.5, 0.75, 1.0]:
					var bottom_sample := _plane_hit(stage.camera, Vector2(width * fraction, height * 0.995))
					check(_alpha_at(card, bottom_sample, pixels) > 0.5,
						"Foreground covers bottom edge at %s / %s / %s" % [location, distance, fraction])
				var action_center := _plane_hit(stage.camera, Vector2(width * 0.5, height * 0.54))
				check(_alpha_at(card, action_center, pixels) < 0.1,
					"Foreground leaves the central action readable at %s / %s" % [location, distance])
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
		var cards: Array = stage.scenery.find_children(name, "Sprite3D", true, false)
		check(cards.size() == 1, name + " needs exactly one authored elevation")
		if cards.size() == 1:
			check(cards[0].texture_filter == BaseMaterial3D.TEXTURE_FILTER_NEAREST and cards[0].cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
				name + " retains crisp art without fake structural shadows")
	for old_name in ["B02WindowFrame*", "GalleryOpenGothicBay*", "HallLowerBlindArcade*", "S10TunnelBackwall*"]:
		check(stage.scenery.find_children(old_name, "MeshInstance3D", true, false).is_empty(), old_name + " should not cover painted architecture")
	stage.camera_target = CrimsonStage3D.to_stage(Vector2(9200, 1120))
	stage.residency.update_at(Vector2(9200, 1120))
	check(not stage.scenery.find_children("B05TowerPier", "MeshInstance3D", true, false).is_empty(), "Tower landing keeps a physical support")
	stage.camera_target = CrimsonStage3D.to_stage(Vector2(14300, 1424))
	stage.residency.update_at(Vector2(14300, 1424))
	check(not stage.scenery.find_children("B12ContinuedFoundation", "MeshInstance3D", true, false).is_empty(), "Hall drawing keeps a closed lower foundation")
	stage.game.reset_trial(3)
	await process_frame
	check(stage.scenery.find_children("ImageMonasteryForeground", "Node3D", true, false).size() == 1,
		"Reset does not duplicate the continuous foreground")
	app.free()
	print("IMAGE PAPER LAYERS STAGE RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
