extends SceneTree

func _initialize() -> void: run.call_deferred()

func run() -> void:
	for campaign in [true, false]:
		var app = load("res://scenes/game.tscn").instantiate()
		app.campaign_enabled = campaign
		root.add_child(app)
		var stage: CrimsonStage3D = app.stage
		stage.frozen_camera = true
		stage.game.player.manual_control = true
		stage.game.player.set_physics_process(false)
		var points := {"high": Vector2(9600,-1972), "low": Vector2(16300,4054)} if campaign else {"high": Vector2(150,-20), "low": Vector2(4650,350)}
		for label in points:
			for weapon in CrimsonStage3D.WEAPON_CAMERA:
				stage.game.player.weapons.select_weapon(CrimsonStage3D.WEAPON_CAMERA.keys().find(weapon))
				for extent in ["near", "far"]:
					var distance: float = CrimsonStage3D.WEAPON_CAMERA[weapon][extent]
					stage.game.player.position = points[label]
					stage.game.player.update_aim(points[label] + Vector2(100,-26))
					stage.camera_target = CrimsonStage3D.to_stage(points[label])
					stage.camera.position = stage.camera_target + Vector3(0.32,1.18,distance)
					stage.camera.look_at(stage.camera_target)
					if campaign: stage.residency.update_at(points[label])
					for i in 3:
						await physics_frame
						await process_frame
					await RenderingServer.frame_post_draw
					app.stage_viewport.get_texture().get_image().save_png("res://artifacts/sky_%s_%s_%s_%s.png" % ["image" if campaign else "legacy", label, weapon, extent])
		app.free()
		await process_frame
	quit()
