extends SceneTree

var failures := 0
var checks := 0

func _initialize() -> void: run.call_deferred()

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func run() -> void:
	var app = load("res://scenes/game.tscn").instantiate()
	root.add_child(app)
	var stage: CrimsonStage3D = app.stage
	stage.frozen_camera = true
	for reset in 3:
		if reset: stage.game.reset_trial(3)
		stage.game.player.set_physics_process(false)
		for enemy in stage.game.enemies: enemy.set_physics_process(false)
		await process_frame
		var foreground: Node3D = stage.scenery.get_node("NearForeground")
		check(stage.scenery.find_children("NearForeground", "Node3D", true, false).size() == 1, "Reset must leave one foreground layer")
		check(foreground.get_child_count() == 10, "Five sections each have two separated low wall groups")
		var near_cards := foreground.find_children("AuthoredNearSilhouette", "Sprite3D", true, false)
		check(near_cards.size() == 10, "Each foreground group uses a newly authored 2D silhouette")
		for card in near_cards:
			check(card.texture.get_image().detect_alpha() != Image.ALPHA_NONE and not card.shaded and card.material_override == null, "Authored transparent silhouette has no 3D lighting or screen-space blur")
		check(foreground.find_children("*", "CollisionObject3D", true, false).is_empty(), "Foreground must not change gameplay collision")
		for piece in foreground.find_children("*", "MeshInstance3D", true, false):
			var material: StandardMaterial3D = piece.material_override
			check(material != null and material.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED and material.texture_filter == BaseMaterial3D.TEXTURE_FILTER_NEAREST, "Foreground has opaque nearest stone, no blur or screen fade")
		check(stage.scenery.find_children("Moon", "Sprite3D", true, false).size() == 1, "The whole map must share exactly one moon")
		check(stage.scenery.find_children("Sky", "Sprite3D", true, false).size() == 1, "The whole map must share exactly one sky")
		check(stage.scenery.find_children("DistantWindows", "Sprite3D", true, false).is_empty(), "Baked moon/castle backdrop must be retired")
		var castle: Sprite3D = stage.night.get_node("CastleSilhouette1")
		check(stage.night.sky.position.z < stage.night.moon.position.z and stage.night.moon.position.z < castle.position.z, "Sky, moon and castle must have distinct real depths")
		check(stage.night.moon.texture.get_image().get_pixel(0, 0).a == 0, "Moon matte must be transparent")
		check(castle.texture.get_image().get_pixel(0, 0).a == 0, "Castle matte must be transparent")
		var untextured: Array[String] = []
		for piece in stage.scenery.find_children("*", "MeshInstance3D", true, false):
			var mat = piece.material_override
			if not mat is StandardMaterial3D or mat.albedo_texture == null: untextured.append(str(piece.name))
		check(untextured.is_empty(), "Every 3D object needs a texture: %s" % str(untextured))
		stage.set_greybox(true)
		check(stage.materials.all(func(mat): return mat.albedo_texture == null), "Diagnostic greybox must remain available")
		stage.set_greybox(false)
		check(stage.materials.all(func(mat): return mat.albedo_texture != null), "Texture mode must restore every authored material")
		var before := castle.position
		stage.night.follow_camera(Vector3(4.8, 0, 5))
		var moon_before := stage.night.moon.position
		stage.night.follow_camera(Vector3(44.8, 0, 5))
		check(castle.position == before and is_equal_approx(stage.night.moon.position.x - moon_before.x, 39.2), "Castle stays in world space while distant moon has slower relative travel")
	app.free()
	await process_frame
	await process_frame
	print("ENVIRONMENT ART STAGE RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
