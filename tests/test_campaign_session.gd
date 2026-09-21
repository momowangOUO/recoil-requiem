extends SceneTree
const State = preload("res://scripts/campaign/campaign_state.gd")
var checks := 0
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func at(session, id: String) -> void:
	for point in session.points:
		if point.id == id:
			session.lab.player.position = point.position
			return
	check(false, "Missing interaction point " + id)
func run() -> void:
	var game: RecoilLab = load("res://scenes/crimson_slice.tscn").instantiate()
	game.campaign_enabled = true
	root.add_child(game)
	game.player.manual_control = true
	var session = game.campaign_session
	session.autosave = false
	check(game.environment is MonasteryCampaign, "Main campaign selects the new editable world")
	check(not game.environment.gate_states.gate_departure, "Departure building begins closed")
	session.interact("records")
	check(session.has("records") and session.ui.is_panel_open() and paused, "Early evidence is readable and pauses actual gameplay")
	session.close()
	at(session,"ruka")
	session.talk("ruka")
	session.choose("records_ruka")
	session.close()
	check(session.has("records_ruka") and game.environment.gate_states.gate_east, "Early evidence later delivered opens the matching route")
	var before: int = session.state.snapshot().results.size()
	session.choose("records_mara")
	check(not session.has("records_mara") and before == session.state.snapshot().results.size(), "Stale choice cannot duplicate or reverse delivery")
	session.interact("tools")
	session.close()
	at(session,"ina")
	session.talk("ina")
	session.choose("tools_ina")
	session.close()
	check(session.has("tools_ina") and not session.has("tools_mara"), "Toolbox recipient is exclusive")
	session.talk("vira")
	session.close()
	check(session.state.quest_status("mon_main_02") == "locked", "Meeting target early does not invent an entry conversation")
	session.talk("mara")
	session.close()
	check(session.state.quest_status("mon_main_02") == "completed", "Quest catches up to early meeting when entry is learned")
	session.interact("luggage")
	session.close()
	session.talk("vira")
	session.close()
	at(session,"luggage")
	session.interact("luggage")
	session.choose("luggage_home")
	session.close()
	check(session.has("luggage_home") and session.has("luggage_request"), "Luggage decision requires hearing the actual request")
	session.event("inner_reached")
	at(session,"departure")
	session.interact("departure")
	session.choose("later")
	check(not session.has("departed"), "Departure confirmation can be deferred without time pressure")
	at(session,"departure")
	session.interact("departure")
	session.choose("depart")
	session.close()
	check(session.has("departed") and session.groups.has("elite") and not game.environment.gate_states.gate_departure, "Departure creates Celine encounter while final gate remains locked")
	check(session.tool_choices().is_empty() and session.record_choices().is_empty(), "No late deliveries after irreversible departure")
	if not session.groups.has("elite"):
		session.close()
		game.free()
		quit(1)
		return
	for guard in session.groups.elite: guard.state = ShieldEnemy.State.DEAD
	session.enemy_down("elite")
	session.close()
	check(session.has("celine_defeated") and game.environment.gate_states.gate_departure and session.groups.has("boss"), "Celine defeat opens physical gate and creates Vira once")
	for guard in session.groups.boss: guard.state = ShieldEnemy.State.DEAD
	session.enemy_down("boss")
	check(session.has("vira_dead") and game.environment.gate_states.gate_return, "Fixed Vira death opens return transport")
	session.talk("mara")
	session.close()
	check(session.has("returned") and session.state.quest_status("mon_main_07") == "completed", "Return conversation completes the causal quest chain")
	var snapshot: Dictionary = session.state.snapshot()
	game.reset_trial(3)
	game.player.manual_control = true
	check(session.state.snapshot() == snapshot, "World reset preserves investigations, choices and permanent progress")
	check(not session.groups.has("boss") and not session.groups.has("elite"), "Reconstruction never duplicates resolved special encounters")
	check(game.projectiles.get_child_count() == 0 and game.player.velocity == Vector2.ZERO, "Checkpoint reconstruction clears projectiles and old velocity")
	check(session.npc_actors.size() == 5, "Reset reconstructs exactly five NPCs")
	var active := 0
	session.step(0.2)
	for guard in game.enemies:
		if guard.target != null: active += 1
	check(active <= 6, "Campaign activates at most six nearby enemies")
	var decoded = JSON.parse_string(FileAccess.get_file_as_string("res://data/campaign/monastery_text.json"))
	var reviewed := {}
	for path in ["res://game-text/monastery-v2-review.md", "res://game-text/monastery-opening-onboarding-review.md"]:
		for line in FileAccess.get_file_as_string(path).split("\n"):
			if line.begins_with("|mon.") or line.begins_with("| `mon."):
				var fields := line.split("|")
				var id: String = fields[1].strip_edges().trim_prefix("`").trim_suffix("`")
				reviewed[id] = fields[3].strip_edges().replace("<br>", "\n")
	for id in decoded:
		check(reviewed.get(id) == decoded[id], "Runtime text matches latest reviewed draft: " + id)
	check(reviewed.size() == decoded.size(), "No undocumented runtime story text")
	game.free()
	print("CAMPAIGN SESSION STAGE RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
