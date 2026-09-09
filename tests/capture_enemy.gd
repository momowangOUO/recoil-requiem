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
	var guard_hand := Vector2.ZERO
	for state in [ShieldEnemy.State.APPROACH, ShieldEnemy.State.WINDUP, ShieldEnemy.State.ATTACK, ShieldEnemy.State.RECOVERY, ShieldEnemy.State.DEAD]:
		lab.enemy.state = state
		lab.enemy.state_time = 0.25
		lab.enemy.visual._physics_process(0.01)
		lab.enemy.visual.death_time = 0.65 if state == ShieldEnemy.State.DEAD else 0
		lab.enemy.visual.queue_redraw()
		lab.enemy.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		var picture := root.get_texture().get_image()
		picture.resize(1280, 720, Image.INTERPOLATE_NEAREST)
		picture.save_png("res://artifacts/enemy_%d.png" % state)
		if state == ShieldEnemy.State.APPROACH:
			guard_hand = lab.enemy.visual.shield_hand
		if state == ShieldEnemy.State.ATTACK and lab.enemy.visual.shield_hand.x <= guard_hand.x + 5:
			failures += 1
		if state == ShieldEnemy.State.RECOVERY and lab.enemy.visual.shield_hand.y <= guard_hand.y + 4:
			failures += 1
	lab.enemy.state = ShieldEnemy.State.APPROACH
	lab.enemy.velocity.x = 48
	var knees: Array = []
	for phase in [0.5, 3.6]:
		lab.enemy.visual.stride = phase
		lab.enemy.visual.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		knees.append(lab.enemy.visual.front_knee)
		var picture := root.get_texture().get_image()
		picture.resize(1280, 720, Image.INTERPOLATE_NEAREST)
		picture.save_png("res://artifacts/enemy_walk_%d.png" % knees.size())
	if knees[0].distance_to(knees[1]) < 2:
		failures += 1
	print("ENEMY VISUAL: 3 checks, %d failures" % failures)
	lab.free()
	quit(1 if failures else 0)
