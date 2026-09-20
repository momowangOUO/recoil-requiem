extends "res://tests/run_tests.gd"
const Validator = preload("res://addons/recoil_map_editor/room_validator.gd")

func run() -> void:
	var room := Node2D.new()
	room.set_meta("world_bounds", Rect2(-100, -400, 1000, 800))
	var gameplay := Node2D.new()
	gameplay.name = "Gameplay"
	room.add_child(gameplay)
	var stair := PaperStair.new()
	stair.name = "FixtureStair"
	gameplay.add_child(stair)
	for kind in [RoomMarker.Kind.SPAWN, RoomMarker.Kind.EXIT]:
		var marker := RoomMarker.new()
		marker.kind = kind
		marker.position = Vector2(96 + kind * 96, -48 - kind * 48)
		gameplay.add_child(marker)
	check(Validator.validate(room).is_empty(), "spawn and exit may stand on the interior of a valid stair")
	stair.end_offset = Vector2(384, -300)
	check(has_error(room, "35"), "stairs steeper than 35 degrees are rejected")
	stair.end_offset = Vector2.ZERO
	check(has_error(room, "horizontal"), "zero-run stair is rejected")
	stair.end_offset = Vector2(384, -192)
	stair.position = Vector2(600, 0)
	check(has_error(room, "bounds"), "full stair shell must stay within authored bounds")
	stair.position = Vector2.ZERO
	var spawn := gameplay.get_child(1) as RoomMarker
	spawn.position = Vector2(4, -2)
	check(has_error(room, "feet"), "stair markers must keep the same 12 px edge clearance as platforms")
	spawn.position = Vector2(96, -60)
	check(has_error(room, "feet"), "floating marker above a stair is rejected")
	spawn.position = Vector2(96, -48)
	var floor := PaperPlatform.new()
	floor.position = Vector2(0, 80)
	floor.width = 384
	gameplay.add_child(floor)
	spawn.position = Vector2(192, 80)
	check(Validator.validate(room).is_empty(), "marker below clear stair shell is allowed in open tunnel")
	floor.position.y = -32
	spawn.position.y = -32
	check(has_error(room, "standing space"), "stair underside blocks marker standing headroom")
	spawn.position = Vector2(96, -48)
	floor.position.y = 80
	var flyer := RoomMarker.new()
	flyer.kind = RoomMarker.Kind.RIFLE
	flyer.set_meta("enemy_archetype", "flyer")
	flyer.position = Vector2(600, -100)
	gameplay.add_child(flyer)
	check(Validator.validate(room).is_empty(), "flying enemies may be authored above ground")
	flyer.set_meta("enemy_archetype", "rifle")
	check(has_error(room, "feet"), "ground enemies still require supporting terrain")
	flyer.set_meta("enemy_archetype", "flyer")
	flyer.position = Vector2(96, -25)
	check(has_error(room, "standing space"), "airborne spawns still cannot intersect solid stairs")
	flyer.position = Vector2(950, -100)
	check(has_error(room, "outside world bounds"), "airborne spawns still require valid world bounds")
	room.free()
	print("STAIR EDITOR STAGE RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func has_error(room: Node, fragment: String) -> bool:
	for error in Validator.validate(room):
		if fragment in error:
			return true
	return false
