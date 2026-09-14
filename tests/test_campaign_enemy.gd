extends SceneTree
const Enemy := preload("res://scripts/combat/campaign_enemy.gd")
var checks := 0
var failures := 0
var world: Node2D
var player: PlayerController
const DT := 1.0 / 60
func _initialize() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func run() -> void:
	world = Node2D.new()
	root.add_child(world)
	var floor_body := StaticBody2D.new()
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(3000, 20)
	collision.shape = shape
	floor_body.position = Vector2(300, 110)
	floor_body.add_child(collision)
	world.add_child(floor_body)
	player = PlayerController.new()
	player.manual_control = true
	player.weapons.configure(WeaponData.baselines())
	player.position = Vector2(240, 100)
	world.add_child(player)
	for kind in ["charger", "grenadier", "flyer", "support", "elite", "boss"]:
		var enemy := Enemy.new()
		enemy.archetype = kind
		enemy.position = Vector2(100, 100)
		enemy.target = player
		world.add_child(enemy)
		enemy.set_physics_process(false)
		await physics_frame
		for i in 150:
			enemy._physics_process(DT)
			await physics_frame
		check(enemy.attack_count > 0, "%s performs its actual attack cycle" % kind)
		enemy.hurt_stun = 0
		enemy._enter(ShieldEnemy.State.WINDUP)
		enemy.artwork._physics_process(DT)
		check(enemy.artwork.frame == 3, "%s warning uses an authored windup pose" % kind)
		enemy._enter(ShieldEnemy.State.ATTACK)
		enemy.artwork._physics_process(DT)
		check(enemy.artwork.frame == 4, "%s attack changes the actual full-body frame" % kind)
		enemy.hurt_stun = 0.1
		enemy.artwork._physics_process(DT)
		check(enemy.artwork.frame == 6, "%s hit uses a distinct authored hurt pose" % kind)
		enemy.hurt_stun = 0
		enemy._enter(ShieldEnemy.State.DEAD)
		enemy.artwork._physics_process(0.3)
		check(enemy.artwork.frame == 7, "%s defeat ends in a stable authored collapsed pose" % kind)
		for frame in 8:
			enemy.artwork.frame = frame
			var layout: Dictionary = enemy.artwork.frame_layout()
			check(layout.region.size.x > 0 and layout.region.size.y > 0 and layout.destination.size.y <= 55, "%s frame %d retains shared pixel scale and complete region" % [kind,frame])
		enemy.free()
	player.health = 5
	player.position = Vector2(190, 100)
	var charger := spawn("charger")
	await frames(charger, 1)
	check(charger.state == ShieldEnemy.State.WINDUP, "Charger commits close-range windup")
	await frames(charger, 25)
	check(player.health == 5 and charger.state == ShieldEnemy.State.WINDUP, "Charger cannot hit during 0.45-second warning")
	await frames(charger, 17, true)
	check(player.health == 4 and charger.attack_count == 1, "Charge deals one contact hit even without player invulnerability")
	check(charger.state == ShieldEnemy.State.RECOVERY, "Charge enters a punishable recovery")
	charger.free()
	player.health = 5
	player.position = Vector2(260, 100)
	var bomber := spawn("grenadier")
	bomber._begin_attack()
	var landing := bomber.locked_target
	await frames(bomber, 41)
	check(bomber.bomb_age >= 0, "Grenadier throws an actual timed projectile")
	player.position.x = 400
	await frames(bomber, 35)
	check(bomber.bomb_to.distance_to(landing + Vector2(0, -3)) < 1, "Grenade landing does not track the moving player")
	check(player.health == 5 and bomber.bomb_age >= 0, "Grenade waits on ground before exploding")
	player.position = landing
	await frames(bomber, 35, true)
	check(player.health == 4 and bomber.bomb_age < 0, "Grenade explosion hits once then clears")
	bomber._throw_bomb()
	bomber.process_mode = Node.PROCESS_MODE_DISABLED
	check(bomber.bomb_age < 0 and bomber.state == ShieldEnemy.State.APPROACH, "Disabling enemy immediately clears hazards and old windup")
	var disabled_at := bomber.position
	await frames(bomber, 100, true)
	check(player.health == 4 and bomber.position == disabled_at, "Disabled enemy cannot move or deal delayed damage")
	bomber.free()
	player.health = 5
	player.position = Vector2(220, 100)
	var flyer := spawn("flyer")
	await frames(flyer, 35)
	check(flyer.position.y < 90, "Flyer rises into an actual airborne orbit")
	await frames(flyer, 7)
	var direction := flyer.locked_direction
	player.position.x = 380
	await frames(flyer, 26)
	check(flyer.locked_direction == direction, "Flyer locks swoop direction during visible warning")
	await frames(flyer, 28)
	check(flyer.state == ShieldEnemy.State.RECOVERY and flyer.weakpoint_open(), "Flyer ends swoop in vulnerable landing recovery")
	flyer.free()
	var ally := spawn("charger", 180)
	ally.health = 20
	var support := spawn("support")
	support._enter(ShieldEnemy.State.ATTACK)
	await frames(support, 35)
	check(ally.health > 20 and is_instance_valid(support.support_target), "Support uses a visible live link and restores damaged ally")
	var shot := ShotContext.new()
	shot.source_position = support.global_position + Vector2(100, -24)
	shot.direction = Vector2.LEFT
	shot.damage = 1
	shot.knockback = 90
	support.receive_hit(shot, support.position)
	check(support.support_target == null and support.state == ShieldEnemy.State.RECOVERY and support.hurt_stun > 0, "Hitting support breaks channel and interrupts the action")
	await frames(support, 1200)
	check(ally.health <= 56 and support.heal_budget >= 0, "Support has at most 36 total healing and never heals indefinitely")
	ally.state = ShieldEnemy.State.DEAD
	ally.health = 0
	await frames(support, 200)
	check(ally.health == 0, "Support cannot revive a dead enemy")
	support.free()
	ally.free()
	player.position = Vector2(280, 100)
	var elite := spawn("elite")
	await frames(elite, 20)
	check(elite.position.x > 120, "Elite actually repositions horizontally before shooting")
	await frames(elite, 6)
	check(elite.state == ShieldEnemy.State.WINDUP and elite.windup_duration() == 0.4, "Elite exposes a 0.4-second shot warning")
	var wall := StaticBody2D.new()
	wall.position = Vector2(220, 40)
	var wall_shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(10, 160)
	wall_shape.shape = rectangle
	wall.add_child(wall_shape)
	world.add_child(wall)
	await physics_frame
	player.health = 5
	await frames(elite, 40, true)
	check(player.health == 5, "World wall occludes an already committed shot")
	elite.free()
	wall.free()
	var boss := spawn("boss")
	check(boss.health == 240 and boss.phase == 1, "Boss starts at 240 HP in first phase")
	shot.source_position = boss.global_position + Vector2(-100, -24)
	shot.damage = 121
	boss.receive_hit(shot, boss.position)
	check(boss.phase == 2 and boss.state == ShieldEnemy.State.RECOVERY, "Half-health boss transition interrupts into a readable recovery")
	boss.attack_count = 2
	boss._begin_attack()
	check(boss.attack_kind == "rush", "Second boss phase adds a committed rush instead of only more health")
	boss.attack_count = 3
	boss._begin_attack()
	check(boss.attack_kind == "shot", "Second boss phase alternates rush with locked shots")
	boss.bomb_age = 0
	player.position.x = 1200
	await frames(boss, 1)
	check(boss.bomb_age < 0 and boss.state == ShieldEnemy.State.APPROACH, "Offscreen distant enemy cannot retain damaging hazards")
	shot.damage = 1000
	var deaths := [0]
	boss.defeated.connect(func(): deaths[0] += 1)
	boss.receive_hit(shot, boss.position)
	boss.receive_hit(shot, boss.position)
	check(deaths[0] == 1 and boss.health == 0 and boss.hurtbox.collision_layer == 0 and boss.weakpoint.collision_layer == 0, "Lethal hit emits defeat once and removes body/weakpoint damage targets")
	boss.free()
	world.free()
	print("CAMPAIGN ENEMY STAGE RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func spawn(kind: String, x := 100.0) -> CampaignEnemy:
	var enemy := Enemy.new()
	enemy.archetype = kind
	enemy.position = Vector2(x, 100)
	enemy.target = player
	world.add_child(enemy)
	enemy.set_physics_process(false)
	return enemy

func frames(enemy: CampaignEnemy, count: int, clear_invulnerability := false) -> void:
	for i in count:
		await physics_frame
		if clear_invulnerability: player.invulnerability = 0
		enemy._physics_process(DT)
