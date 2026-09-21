extends SceneTree
var failures := 0
var checks := 0

func _initialize() -> void: run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func run() -> void:
	var app = load("res://scenes/game.tscn").instantiate()
	root.add_child(app)
	var stage = app.stage
	var game = stage.game
	var session = game.campaign_session
	game.player.manual_control = true
	game.set_physics_process(false)
	for enemy in game.enemies: enemy.set_physics_process(false)
	stage.frozen_camera = true
	for id in ["tools", "records", "luggage"]:
		var action: RoomAction
		for item in game.environment.actions:
			if item.action_id == id: action = item
		check(action != null, "Authored action exists: " + id)
		game.player.position = action.position + Vector2(-34, 0)
		session.refresh()
		stage.residency.update_at(game.player.position)
		var visual: Dictionary = stage.action_visuals[action]
		var prop = visual.piece
		check(prop is Sprite3D and visual.get("quest") == id, "Quest item uses its generated paper prop: " + id)
		check(absf(prop.position.y - prop.region_rect.size.y * prop.pixel_size * 0.5 + action.position.y * 0.01) < 0.001, "Prop bottom meets authored floor: " + id)
		stage.camera_target = CrimsonStage3D.to_stage(action.position + Vector2(-12, -48))
		stage.camera.position = stage.camera_target + Vector3(0.12, 1.18, 4.8)
		stage.camera.look_at(stage.camera_target)
		for tick in 4:
			await physics_frame
			await process_frame
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://artifacts/quest_prop_" + id + ".png")
		session.event(id, "evidence")
		if id == "luggage": session.event("luggage_home")
		stage._physics_process(1.0 / 60.0)
		check(prop.visible == (id == "records"), "Collected prop state matches gameplay; ledger remains readable: " + id)
	app.free()
	print("QUEST PROP VISUALS STAGE RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
