extends "res://tests/run_tests.gd"
## Isolated feasibility fixture, not a replacement of campaign geometry.
func run() -> void:
	var world := Node2D.new()
	root.add_child(world)
	make_floor(world, Rect2(-300,0,300,64))
	make_floor(world, Rect2(384,-192,500,256))
	var ramp := StaticBody2D.new()
	var collision := CollisionPolygon2D.new()
	collision.polygon = PackedVector2Array([Vector2(0,0),Vector2(384,-192),Vector2(384,64),Vector2(0,64)])
	ramp.add_child(collision)
	world.add_child(ramp)
	var player := make_player(world,Vector2(-80,0))
	player.tuning = PlayerTuning.responsive()
	for tick in 300:
		await physics_frame
		var frame := frame_for(player)
		frame.move.x = 1
		player.step(frame,1.0/60)
	check(player.position.x > 430 and absf(player.position.y+192)<2,"Walking alone climbs 384x192 ramp and reaches landing")
	print("STAIR UP: ",player.position)
	for tick in 100:
		await physics_frame
		var frame := frame_for(player)
		frame.move.x = -1
		player.step(frame,1.0/60)
	var stopped_at := player.position
	for tick in 60:
		await physics_frame
		player.step(frame_for(player),1.0/60)
	check(player.position.distance_to(stopped_at)<6,"Releasing movement stops on slope without uncontrolled sliding")
	var recoil := frame_for(player,Vector2.DOWN)
	recoil.fire_pressed = true
	await physics_frame
	player.step(recoil,1.0/60)
	check(player.velocity.y<0,"Valid downward gunshot can lift player away from stair surface")
	for tick in 200:
		await physics_frame
		var frame := frame_for(player)
		frame.move.x = -1
		player.step(frame,1.0/60)
	check(player.position.x < 0 and absf(player.position.y)<2,"Walking alone descends and rejoins flat floor")
	print("STAIR DOWN: ",player.position)
	world.free()
	print("STAIR FEASIBILITY: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
