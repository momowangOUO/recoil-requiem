extends "res://tests/run_tests.gd"
## Uses the actual controller, with no jump, recoil or ammunition needed to walk.
const STAIR_SCENE := "res://scenes/rooms/walkable_stair.tscn"

func run() -> void:
	check(ResourceLoader.exists(STAIR_SCENE), "independent walkable stair scene exists")
	if ResourceLoader.exists(STAIR_SCENE):
		for endpoint in [Vector2(384, -192), Vector2(-384, -192), Vector2(384, 192), Vector2(-384, 192)]:
			await test_walk(endpoint)
		await test_walk(Vector2(384, -384 * tan(deg_to_rad(35))), 32.0)
		await test_shell()
		await test_open_stair()
	print("WALKABLE STAIRS STAGE RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func test_walk(endpoint: Vector2, depth := 48.0) -> void:
	var world := Node2D.new()
	root.add_child(world)
	var stair = load(STAIR_SCENE).instantiate()
	stair.end_offset = endpoint
	stair.stair_depth = depth
	world.add_child(stair)
	var left: Vector2 = Vector2.ZERO if endpoint.x > 0 else endpoint
	var right: Vector2 = endpoint if endpoint.x > 0 else Vector2.ZERO
	make_floor(world, Rect2(left + Vector2(-400, 0), Vector2(400, 48)))
	make_floor(world, Rect2(right, Vector2(400, 48)))
	var player := make_player(world, left + Vector2(-60, 0))
	player.tuning = PlayerTuning.responsive()
	for runtime in player.weapons.slots:
		if runtime != null:
			runtime.ammo = 0
	await walk_to_x(player, right.x + 60)
	check(player.position.x > right.x + 30 and absf(player.position.y - right.y) < 2, "A/D alone crosses stair and right landing %s" % endpoint)
	await walk_to_x(player, (left.x + right.x) * 0.5)
	check(player.position.x > left.x + 20 and player.position.x < right.x - 20, "stop fixture reaches slope %s" % endpoint)
	for tick in 20:
		await walk_tick(player, 0)
	var stopped_at := player.position
	for tick in 60:
		await walk_tick(player, 0)
	check(player.position.distance_to(stopped_at) < 1 and player.is_on_floor(), "release holds position on slope %s" % endpoint)
	await walk_to_x(player, left.x - 60)
	check(player.position.x < left.x - 30 and absf(player.position.y - left.y) < 2, "A/D alone crosses stair and left landing %s" % endpoint)
	world.free()

func test_open_stair() -> void:
	var stair = load(STAIR_SCENE).instantiate()
	check("one_way" in stair, "explicit open metal stair option exists")
	if not "one_way" in stair:
		stair.free()
		return
	var world := Node2D.new()
	root.add_child(world)
	stair.one_way = true
	stair.position.y = 48
	stair.stair_depth = 8
	world.add_child(stair)
	check(stair.get_node("RampCollision").collision_layer == 1024 and stair.get_node("RampCollision/SlopeShell").one_way_collision, "open metal stair uses existing drop-through layer")
	make_floor(world, Rect2(-100, 0, 700, 48))
	var player := make_player(world, Vector2(192, 0))
	player.tuning = PlayerTuning.responsive()
	for tick in 5: await walk_tick(player, 0)
	var jump := frame_for(player)
	jump.jump_pressed = true
	await physics_frame
	player.step(jump, 1.0 / 60)
	var highest := player.position.y
	var hit_ceiling := false
	for tick in 60:
		await walk_tick(player, 0)
		highest = minf(highest, player.position.y)
		hit_ceiling = hit_ceiling or player.is_on_ceiling()
	check(highest < -48 and not hit_ceiling, "Space jumps upward through explicitly open metal stair")
	world.free()

func walk_to_x(player: PlayerController, target_x: float) -> void:
	var direction := signf(target_x - player.position.x)
	for tick in 600:
		if (target_x - player.position.x) * direction <= 0:
			return
		await walk_tick(player, direction)

func walk_tick(player: PlayerController, direction: float) -> void:
	await physics_frame
	var frame := frame_for(player)
	frame.move.x = direction
	player.step(frame, 1.0 / 60)

func test_shell() -> void:
	var world := Node2D.new()
	root.add_child(world)
	var stair = load(STAIR_SCENE).instantiate()
	world.add_child(stair)
	make_floor(world, Rect2(-200, 120, 1000, 48))
	var player := make_player(world, Vector2(160, 120))
	player.tuning = PlayerTuning.responsive()
	for tick in 90:
		await walk_tick(player, 1)
	check(player.position.x > 320 and absf(player.position.y - 120) < 2, "open tunnel remains walkable below thin stair shell")
	player.position = Vector2(192, 20)
	player.velocity = Vector2(0, -600)
	var hit_underside := false
	for tick in 15:
		await walk_tick(player, 0)
		hit_underside = hit_underside or player.is_on_ceiling()
	check(hit_underside and player.position.y > stair.surface_y(player.position.x), "solid underside prevents upward passage through stair")
	player.position = Vector2(192, -96)
	player.velocity = Vector2.ZERO
	for tick in 30:
		await walk_tick(player, 0)
	check(player.is_on_floor(), "recoil fixture stands on actual stair surface")
	var shot := frame_for(player, Vector2.DOWN)
	shot.fire_pressed = true
	await physics_frame
	player.step(shot, 1.0 / 60)
	check(player.velocity.y < 0 and not player.is_on_floor(), "downward gunshot detaches from stair instead of being snapped back")
	check(stair.surface_points() == PackedVector2Array([Vector2.ZERO, Vector2(384, -192)]), "surface API preserves exact authored endpoints")
	check(is_equal_approx(stair.surface_y(192), -96), "surface height interpolates endpoint slope")
	var body = stair.get_node("RampCollision")
	var original_id: int = body.get_instance_id()
	for index in 3:
		stair.end_offset = Vector2(-384, -192)
		stair.stair_depth = 32
		stair.end_offset = Vector2(384, -192)
		stair.stair_depth = 48
		stair.request_ready()
		world.remove_child(stair)
		world.add_child(stair)
	check(stair.get_node("RampCollision").get_instance_id() == original_id and body.get_child_count() == 1, "reconfigure and tree reset retain one collision body and shape")
	var colliders := 0
	for child in stair.get_children():
		if child is StaticBody2D:
			colliders += 1
	check(colliders == 1 and body.collision_layer == 1, "stair has exactly one fully solid terrain collider")
	world.remove_child(stair)
	stair.end_offset = Vector2(-240, -144)
	stair.stair_depth = 24
	world.add_child(stair)
	var expected := PackedVector2Array([Vector2(-240, -144), Vector2.ZERO, Vector2(0, 24), Vector2(-240, -120)])
	check(body.get_child(0).polygon == expected, "detached edits update exact collision endpoints and nondefault depth without request_ready")
	check(stair.get_node("RampCollision").get_instance_id() == original_id and body.get_child_count() == 1, "ordinary tree reentry preserves the original single collider")
	world.free()
