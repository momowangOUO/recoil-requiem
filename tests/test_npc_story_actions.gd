extends SceneTree
const NPC = preload("res://scripts/campaign/campaign_npc.gd")
var checks := 0
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func run() -> void:
	for id in ["mara","vira"]:
		var npc := NPC.new()
		npc.npc_id = id
		if id == "vira": npc.art_path = "res://assets/characters/campaign/boss_actions_v2.png"
		root.add_child(npc)
		check(npc._story_frames.size() == 3,"Three authored story frames load for " + id)
		if npc._story_frames.size() != 3:
			npc.free()
			continue
		for i in 3:
			var image: Image = npc._story_frames[i].get_image()
			var opaque := Rect2i()
			var clean_alpha := true
			var clean_transparent_rgb := true
			for y in 128:
				for x in 128:
					var pixel := image.get_pixel(x,y)
					clean_alpha = clean_alpha and (pixel.a == 0.0 or pixel.a == 1.0)
					if pixel.a == 0.0: clean_transparent_rgb = clean_transparent_rgb and pixel == Color(0,0,0,0)
					if pixel.a > 0.5:
						opaque = opaque.merge(Rect2i(x,y,1,1)) if opaque.has_area() else Rect2i(x,y,1,1)
			check(clean_alpha,"No translucent background noise survives in any pose pixel")
			check(clean_transparent_rgb,"Transparent pose pixels contain no colored matte")
			check(opaque.end.y == 120,"Each complete character remains planted on foot baseline")
			check(opaque.position.x > 0 and opaque.end.x < 128,"Body and held prop fit without cropping")
			if i > 0: check(image.get_data() != npc._story_frames[i-1].get_image().get_data(),"Action changes authored anatomy and prop pixels")
		var origin := npc.position
		var path: Array[Vector2] = [Vector2(100,0)]
		npc.walk_path(path)
		check(npc.play_story_action(),"Known character starts its action")
		npc._process(1.05)
		check(npc._story_frame == 1 and npc.position == origin,"Natural update advances drawing, without translating whole body")
		npc.step_story_action(1.0)
		check(npc._story_frame == 2 and npc.position == origin,"Paused story clock reaches authored look-up frame")
		npc.step_story_action(1.0)
		check(npc._story_frame == -1 and npc._motion_path == path,"Action completes and retains planned movement")
		npc._process(0.1)
		check(npc.position.x > origin.x,"Existing walk resumes after authored action")
		check(not npc.play_story_action("unknown"),"Unknown action cannot substitute another pose")
		npc.play_story_action()
		npc.reload_art()
		check(npc._story_frame == -1,"Reload resets the presentation clock")
		npc.free()
	if "--capture-npc-story" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless": await capture_world_poses()
	print("NPC STORY ACTION STAGE RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)

func capture_world_poses() -> void:
	# Controlled actual-world render evidence; no traversal claim.
	var app = load("res://scenes/game.tscn").instantiate()
	root.add_child(app)
	var stage = app.stage
	var session = stage.game.campaign_session
	stage.frozen_camera = true
	stage.game.player.set_physics_process(false)
	for enemy in stage.game.enemies: enemy.set_physics_process(false)
	for id in ["mara","vira"]:
		var actor = session.npc_actors[id]
		actor.set_process(false)
		var at: Vector2 = actor.position
		stage.game.player.position = at + Vector2(-52,0)
		stage.camera_target = CrimsonStage3D.to_stage(at + Vector2(0,-35))
		stage.camera.position = stage.camera_target + Vector3(0.12,1.18,4.2)
		stage.camera.look_at(stage.camera_target)
		stage._update_actor_window()
		stage.residency.update_at(at)
		stage.foreground.call("follow_camera",stage.camera)
		session.pause()
		actor.play_story_action()
		for frame in 3:
			if frame > 0: actor.step_story_action(1.05)
			for draw_frame in 6: await process_frame
			await RenderingServer.frame_post_draw
			app.stage_viewport.get_texture().get_image().save_png("res://artifacts/npc_story_%s_%d.png" % [id,frame])
	app.free()
	paused = false
