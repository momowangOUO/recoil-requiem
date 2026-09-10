extends SceneTree
var checks := 0
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func run() -> void:
	var game: RecoilLab = load("res://scenes/lab.tscn").instantiate()
	root.add_child(game)
	var player := game.player
	player.manual_control = true
	player.position = Vector2(80, 100)
	player.velocity = Vector2.ZERO
	player.receive_damage(1, Vector2(230, -150))
	check(player.health == 4 and player.hurt_stun == 0.18 and player.hit_flash > 0, "Hurt starts flash, stun and damage")
	var old_stun := player.hurt_stun
	player.receive_damage(1, Vector2(230, -150))
	check(player.health == 4 and player.hurt_stun == old_stun and player.velocity.x == 230, "Invulnerability rejects additional push and stun")
	var input := InputFrame.new()
	input.move = Vector2.LEFT
	input.fire_pressed = true
	input.jump_pressed = true
	input.aim_world = Vector2(300, 100)
	var ammo := player.weapons.current().ammo
	var start_x := player.position.x
	for i in 6:
		player.step(input, 1.0 / 60)
		await physics_frame
	check(player.position.x > start_x + 10 and player.velocity.x > 0, "Hit knockback survives contrary movement input")
	check(player.weapons.current().ammo == ammo and player.jump_buffer_time == 0, "Stun blocks firing and buffered jumping")
	var before := player.hurt_stun
	game.pause_trial()
	for i in 3: await process_frame
	check(player.hurt_stun == before, "Pause freezes stun clock")
	game.resume_trial()
	for i in 8: player.step(InputFrame.new(), 1.0 / 60)
	check(player.hurt_stun == 0, "Stun expires independently of invulnerability")
	var enemy := ShieldEnemy.new()
	enemy.fixed_target = true
	game.world.add_child(enemy)
	enemy.set_physics_process(false)
	enemy.position = Vector2(300, 100)
	enemy.facing_angle = 0
	var shot := ShotContext.new()
	shot.source_position = Vector2(400, 76)
	shot.direction = Vector2.LEFT
	shot.damage = 1
	shot.knockback = 520.0 / 7
	enemy.receive_hit(shot, Vector2(300, 76))
	check(is_equal_approx(enemy.hurt_stun, 0.055), "Shield front gives a short defensive flinch")
	enemy.stun_guard = 0
	enemy.state = ShieldEnemy.State.WINDUP
	shot.source_position = Vector2(200, 76)
	shot.direction = Vector2.RIGHT
	enemy.knockback_velocity = Vector2.ZERO
	for i in 7: enemy.receive_hit(shot, Vector2(300, 76))
	check(enemy.state == ShieldEnemy.State.RECOVERY and enemy.hurt_stun == 0.18, "Rear hit interrupts windup once per blast")
	check(absf(enemy.knockback_velocity.x - 520.0 / 1.5) < 0.01, "Pellet impulse total is preserved")
	for i in 14:
		enemy._physics_process(1.0 / 60)
		if i % 5 == 0: enemy.receive_hit(shot, enemy.position)
	check(enemy.hurt_stun == 0, "Repeated automatic hits cannot extend one stun indefinitely")
	var rifle := RifleEnemy.new()
	game.world.add_child(rifle)
	rifle.set_physics_process(false)
	rifle.state = ShieldEnemy.State.WINDUP
	rifle.receive_hit(shot, Vector2.ZERO)
	check(rifle.hurt_stun > 0 and rifle.state == ShieldEnemy.State.RECOVERY, "Rifle shares interrupted attack and hurt reaction")
	check(game.world.get_children().any(func(n): return n is HurtFX), "Actual player damage spawns world-space authored-palette feedback")
	shot.damage = 1000
	for victim in [enemy, rifle]:
		victim.receive_hit(shot, victim.position)
		var artwork: Node2D = victim.get_node("RifleArtwork") if victim is RifleEnemy else victim.visual
		artwork._physics_process(0)
		check(victim.state == ShieldEnemy.State.DEAD and artwork.material.get_shader_parameter("hit_flash") == 0.0, "Lethal hits retain authored death colors, not a permanent white silhouette")
	game.free()
	print("HIT STAGE RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
