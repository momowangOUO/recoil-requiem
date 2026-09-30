extends SceneTree
## Spatial campaign events follow the authored map while saved IDs remain stable.
const Data = preload("res://scripts/campaign/monastery_data.gd")
var checks := 0
var failures := 0

func _initialize() -> void: run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func run() -> void:
	var game: RecoilLab = load("res://scenes/crimson_slice.tscn").instantiate()
	game.campaign_enabled = true
	root.add_child(game)
	game.player.manual_control = true
	var session = game.campaign_session
	session.autosave = false
	var authored := {
		"elite": Vector2(12400,1424), "boss": Vector2(14800,1424),
		"celine_after": Vector2(12320,1424), "celine_return": Vector2(3920,1408)
	}
	check(game.environment.get("image_led") == true, "Main campaign selects image-led authored world")
	for id in authored:
		check(game.environment.story_positions.get(id) == authored[id], "Image map supplies authored story marker " + id)
	var saved_markers: Dictionary = game.environment.story_positions.duplicate()
	game.environment.story_positions.clear()
	check(session.story_position("elite") == Vector2(10350,1120), "Legacy elite marker fallback remains compatible")
	check(session.story_position("boss") == Vector2(11500,400), "Legacy boss marker fallback remains compatible")
	check(session.story_position("celine_after") == Vector2(10300,1120), "Legacy postdefeat fallback remains compatible")
	check(session.story_position("celine_return") == Vector2(3400,1120), "Legacy return fallback remains compatible")
	game.environment.story_positions.merge(saved_markers)
	session.event("departed")
	session.spawn_special("elite")
	check(session.groups.elite[0].position == authored.elite, "Elite spawns at authored story marker")
	for guard in session.groups.elite: guard.state = ShieldEnemy.State.DEAD
	session.enemy_down("elite")
	session.close()
	check(session.groups.boss[0].position == authored.boss, "Boss spawns at authored story marker")
	check(session.npc_actors.celine.position == authored.celine_after, "Surviving Celine uses postdefeat marker")
	game.player.position = Vector2(11500,400)
	session.step(0.01)
	check(not session.has("boss_met"), "Legacy boss location cannot trigger relocated encounter")
	game.player.position = authored.boss + Vector2(-200,0)
	session.step(0.01)
	check(session.has("boss_met"), "Approaching relocated boss triggers existing dialogue")
	session.close()
	for guard in session.groups.boss: guard.state = ShieldEnemy.State.DEAD
	session.enemy_down("boss")
	check(session.npc_actors.celine.position == authored.celine_return, "Celine returns to authored return marker")
	for point in session.points:
		if point.id == "celine": check(point.position == authored.celine_return, "Celine interaction follows actor")
	for i in range(1,17):
		var id := "cp_mon_%02d" % i
		check(Data.catalog().checkpoints.has(id), "Save catalog preserves " + id)
	session.event("cp_mon_14", "checkpoint")
	var saved: Dictionary = session.state.snapshot()
	game.reset_trial(3)
	game.player.manual_control = true
	check(session.state.snapshot() == saved, "World reconstruction preserves checkpoint and permanent flags")
	for point in game.environment.checkpoints:
		if point.id == "cp_mon_14": check(game.player.position == point.position, "Saved checkpoint resolves current scene coordinates")
	check(not session.groups.has("elite") and not session.groups.has("boss"), "Resolved encounters remain resolved after map reconstruction")
	game.free()
	print("IMAGE CAMPAIGN STAGE RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
