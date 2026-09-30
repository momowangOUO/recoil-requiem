extends SceneTree
## Controlled, authored-position render evidence. This is not a playthrough.
func _initialize() -> void: run.call_deferred()
func run() -> void:
	if "--campaign-test" not in OS.get_cmdline_user_args(): quit(2); return
	root.size = Vector2i(1280,720)
	var app = load("res://scenes/game.tscn").instantiate()
	root.add_child(app)
	var stage = app.stage
	var session = stage.game.campaign_session
	var cue = app.chapter_staging
	stage.frozen_camera = true
	stage.game.player.manual_control = true
	stage.game.player.set_physics_process(false)
	for enemy in stage.game.enemies: enemy.set_physics_process(false)
	var views := {"arrival":Vector2(1260,1120),"stairs":Vector2(1638,1024),
		"first_guard":Vector2(2750,1120),"mara":Vector2(3870,1408),"vira":Vector2(6340,1408),
		"cooperation":Vector2(8030,1696),"route_service":Vector2(7190,2632),
		"tools":Vector2(4830,1408),"departure":Vector2(11430,1424),
		"celine_duel":Vector2(12080,1424),"vira_after":Vector2(15360,1424),"return":Vector2(3870,1408)}
	cue.enabled = true
	for id in views:
		cue.cancel()
		if id == "celine_duel":
			session.event("departed")
			session.spawn_special("elite")
		if id == "vira_after":
			session.event("celine_defeated")
			session.spawn_special("boss")
			session.groups.boss[0].state = ShieldEnemy.State.DEAD
			session.groups.boss[0].artwork.frame = 7
			session.groups.boss[0].artwork.queue_redraw()
			session.event("vira_dead")
		var at: Vector2 = views[id]
		stage.game.player.position = at
		stage.game.player.velocity = Vector2.ZERO
		stage.game.player.update_aim(at + Vector2(100,-10))
		stage.camera_target = CrimsonStage3D.to_stage(at+Vector2(0,-58))
		stage.camera.position = stage.camera_target+Vector3(0.12,1.18,5.2)
		stage.camera.look_at(stage.camera_target)
		stage._update_actor_window()
		stage.residency.update_at(at)
		stage.foreground.call("follow_camera",stage.camera)
		session.pause()
		cue._begin({"id":id,"after":Callable(),"generation":cue._generation,"delay":0.0})
		# Minor cue normally yields to pause; this fixture renders its authored layout directly.
		cue.elapsed = 1.1 if cue.locks_input() else 0.3
		cue._root.modulate.a = 1
		cue._root.show()
		if id in ["mara","vira"]: session.npc_actors[id].step_story_action(1.1)
		cue.set_process(false)
		for frame in 6: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/chapter_scene_%s.png" % id)
		cue.finish()
	app.free()
	paused = false
	print("CHAPTER SCENE CAPTURE: 12 controlled views; not a playthrough")
	quit()
