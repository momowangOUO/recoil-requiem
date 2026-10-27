extends SceneTree
## Controlled render comparison. Continuous playthrough evidence is separate.
var evidence_dir := "res://artifacts"
func _initialize() -> void: run.call_deferred()
func run() -> void:
	if "--campaign-test" not in OS.get_cmdline_user_args(): quit(2); return
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence-dir="): evidence_dir=arg.trim_prefix("--evidence-dir=")
	DirAccess.make_dir_recursive_absolute(evidence_dir)
	root.size = Vector2i(1280,720)
	var app = load("res://scenes/game.tscn").instantiate()
	root.add_child(app)
	var stage: CrimsonStage3D = app.stage
	var game = stage.game
	game.campaign_session.autosave = false
	app.chapter_staging.enabled = false
	app.chapter_staging.cancel()
	app.set_process_input(false)
	app.mouse_screen = Vector2(160,90)
	game.player.weapons.select_weapon(0)
	game.player.manual_control = true
	game.player.set_physics_process(false)
	game.set_physics_process(false)
	stage.frozen_camera = true
	stage.residency_enabled = false
	stage.residency.clear()
	game.overlay.hide()
	game.campaign_session.ui.hide()
	for enemy in game.enemies: enemy.set_physics_process(false)
	var views := {"station":Vector2(176,512),"gatehouse":Vector2(704,512),"cargo":Vector2(1056,584),"bell":Vector2(2024,656),"garden":Vector2(2648,588),"hall":Vector2(3560,488),"pump":Vector2(1840,890),"archive":Vector2(1688,452)}
	var manifest := {}
	for id in views:
		stage.camera_distance = stage.camera_profile().near
		stage.yaw_offset = 0
		game.player.position = views[id]
		game.player.update_aim(views[id]+Vector2(120,-20))
		stage.camera_target = CrimsonStage3D.to_stage(views[id]+Vector2(0,-48))
		stage._update_camera(1)
		stage._update_actor_window()
		stage.night.follow_camera(stage.camera.position,stage.camera)
		stage.foreground.call("follow_camera",stage.camera)
		for i in 8: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(evidence_dir.path_join("rebuild_"+id+".png"))
		var a := stage.screen_to_world(Vector2.ZERO)
		var b := stage.screen_to_world(Vector2(640,360))
		manifest[id] = {"world_rect":[a.x,a.y,b.x-a.x,b.y-a.y],"player":[views[id].x,views[id].y],"weapon":str(game.player.weapons.current().data.id),"camera_distance":stage.camera_distance}
	if "--six-camera-views" in OS.get_cmdline_user_args():
		for id in ["gatehouse","cargo","bell","garden","hall"]:
			game.player.position = views[id]
			for slot in 3:
				game.player.weapons.select_weapon(slot)
				game.player.update_aim(views[id]+Vector2(120,-20))
				for far_view in [false,true]:
					app.mouse_screen = Vector2(319 if far_view else 160,90)
					stage.camera_target = CrimsonStage3D.to_stage(views[id]+Vector2(0,-48))
					stage._update_camera(1)
					stage._update_actor_window()
					stage.night.follow_camera(stage.camera.position,stage.camera)
					stage.foreground.call("follow_camera",stage.camera)
					for i in 4: await process_frame
					await RenderingServer.frame_post_draw
					var key := "%s_%s_%s" % [id,game.player.weapons.current().data.id,"far" if far_view else "near"]
					root.get_texture().get_image().save_png(evidence_dir.path_join(key+".png"))
	app.stage_viewport.size = Vector2i(1024,384)
	stage.camera.far = 100
	stage.camera_target = Vector3(20.48,-4.2,-0.4)
	stage.camera.position = stage.camera_target+Vector3(0,1.4,38)
	stage.camera.look_at(stage.camera_target)
	stage.night.follow_camera(stage.camera.position,stage.camera)
	stage.foreground.hide()
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
	app.stage_viewport.get_texture().get_image().save_png(evidence_dir.path_join("rebuild_overview.png"))
	var f := FileAccess.open(evidence_dir.path_join("rebuild_views.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify(manifest,"\t"))
	var details := {}
	for face: Sprite3D in stage.scenery.find_children("*","Sprite3D",false,false):
		if not face.region_enabled: continue
		var size := face.region_rect.size*face.pixel_size/CrimsonStage3D.PIXEL
		var center := Vector2(face.position.x,-face.position.y)/CrimsonStage3D.PIXEL
		var rect := Rect2(center-size*.5,size)
		var crop := face.region_rect
		details[str(face.name)] = {"texture":face.texture.resource_path,"source":[crop.position.x,crop.position.y,crop.size.x,crop.size.y],"world_rect":[rect.position.x,rect.position.y,rect.size.x,rect.size.y],"z":face.position.z,"lit":face.shaded,"cast_shadow":face.cast_shadow}
	var detail_file := FileAccess.open(evidence_dir.path_join("rebuild_details.json"),FileAccess.WRITE)
	detail_file.store_string(JSON.stringify(details,"\t"))
	app.free()
	print("REBUILD CAPTURE STAGE RESULT: %d actual rendered views; controlled positions, not a playthrough" % [views.size()+1])
	quit()
