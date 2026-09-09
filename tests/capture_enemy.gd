extends SceneTree
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var lab = load("res://scenes/lab.tscn").instantiate()
	root.add_child(lab)
	lab.reset_trial(2)
	lab.player.manual_control = true
	lab.player.position.x = 300
	lab.enemy.set_physics_process(false)
	lab.enemy.visual.set_physics_process(false)
	lab.camera_center = Vector2(350, 270)
	lab.camera.position = lab.camera_center
	lab.set_physics_process(false)
	lab.overlay.update_hud({"preset": 2, "title": "AEGIS RIG", "inventory": lab.player.weapons.inventory_snapshot()})
	var states_seen: Array = []
	for state in [ShieldEnemy.State.APPROACH, ShieldEnemy.State.WINDUP, ShieldEnemy.State.ATTACK, ShieldEnemy.State.RECOVERY, ShieldEnemy.State.DEAD]:
		lab.enemy.state = state
		lab.enemy.state_time = 0.25
		lab.enemy.visual.death_time = 0.65 if state == ShieldEnemy.State.DEAD else 0
		lab.enemy.visual.previous_state = state
		lab.enemy.visual._physics_process(0.01)
		lab.enemy.visual.queue_redraw()
		lab.enemy.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		var picture := root.get_texture().get_image()
		picture.resize(1280, 720, Image.INTERPOLATE_NEAREST)
		picture.save_png("res://artifacts/enemy_%d.png" % state)
		var selection := "%s:%d" % [lab.enemy.visual.animation, lab.enemy.visual.frame]
		if selection in states_seen:
			failures += 1
		states_seen.append(selection)
	lab.enemy.state = ShieldEnemy.State.APPROACH
	lab.enemy.velocity.x = 48
	var frames_seen: Array = []
	for phase in [0.5, 2.5]:
		lab.enemy.visual.stride = phase
		lab.enemy.visual._physics_process(0.01)
		await process_frame
		await RenderingServer.frame_post_draw
		frames_seen.append(lab.enemy.visual.frame)
		var picture := root.get_texture().get_image()
		picture.resize(1280, 720, Image.INTERPOLATE_NEAREST)
		picture.save_png("res://artifacts/enemy_walk_%d.png" % frames_seen.size())
	if frames_seen[0] == frames_seen[1]:
		failures += 1
	print("ENEMY VISUAL: distinct combat/death poses and walking frames, %d failures" % failures)
	lab.free()
	quit(1 if failures else 0)
