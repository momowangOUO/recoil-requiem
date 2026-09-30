extends SceneTree
const Data = preload("res://scripts/campaign/monastery_data.gd")
const Store = preload("res://scripts/campaign/campaign_state.gd")
var checks := 0
var failures := 0
var path := "user://campaign_flow_%s.json" % Time.get_ticks_usec()

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
	check(false, "Missing authored interaction " + id)

func run() -> void:
	var game: RecoilLab = load("res://scenes/crimson_slice.tscn").instantiate()
	game.campaign_enabled = true
	root.add_child(game)
	game.player.manual_control = true
	var s = game.campaign_session
	s.autosave = false
	game.player.position = Vector2(2600,1120)
	s.step(0.01)
	check(s.groups.clear_01[0].target == game.player, "First guard wakes inside its authored patrol")
	game.player.position = Vector2(3920,1408)
	s.step(0.01)
	check(s.groups.clear_01[0].target == null, "First guard cannot pursue the player into Mara's safe meeting")
	game.player.position = Vector2(8300,1696)
	s.step(0.01)
	check(s.groups.clear_05[0].target == game.player and s.groups.clear_05[1].target == null, "Cooperation guards wake separately along the route")
	s.interact("maintenance_isolate")
	check(s.has("maintenance_open") and not s.has("tools") and s.selected_route() == "maintenance", "Maintenance isolation needs no tools or evidence")
	s.interact("lift_repair")
	check(not s.has("lift_repaired"), "Repair needs instructions and held tools")
	s.event("tools", "evidence")
	s.talk("ina")
	s.close()
	s.interact("lift_repair")
	check(s.has("lift_repaired") and not s.has("tools_ina") and not s.has("tools_mara"), "Onsite repair does not decide ownership")
	check(not s.tool_choices().is_empty(), "Repaired tools remain available for final delivery")
	at(s,"ina")
	s.talk("ina")
	s.choose("tools_ina")
	s.close()
	check(s.has("tools_ina") and s.has("lift_repaired") and s.has("maintenance_open"), "Final owner opens only side route without undoing main routes")
	s.select_route("maintenance")
	s.event("mon_09", "visit")
	check(s.selected_route() == "maintenance", "Walking into another branch does not silently change selection")
	s.talk("mara")
	s.close()
	var vira_start: Vector2 = s.npc_actors.vira.position
	s.talk("vira")
	s.close()
	s.npc_actors.vira._process(0.5)
	check(s.npc_actors.vira.position != vira_start and s.npc_actors.vira.position.distance_to(vira_start) <= 48.1, "Vira starts a bounded continuous walk after dialogue")
	check(s.npc_actors.vira._frame in [1,2], "Vira uses authored walking poses")
	s.npc_actors.celine.play_cover(Vector2.ZERO)
	s.npc_actors.celine._process(0.01)
	check(s.npc_actors.celine._frame == 4, "Celine cover uses authored attack pose")
	s.event("records", "evidence")
	s.event("luggage_request")
	check(s.pending_departure_tasks().size() == 2, "Departure lists only unsubmitted records and accepted luggage request")
	at(s,"luggage")
	s.interact("luggage")
	s.choose("luggage_home")
	s.close()
	check(s.has("luggage_home") and game.environment.get_node("Gameplay/Action_luggage").position == s.story_position("luggage_home") - Vector2(0,36), "Onsite luggage choice moves the real interaction to the crate top")
	at(s,"luggage")
	check(game.player.position == game.environment.get_node("Gameplay/Action_luggage").position, "Session interaction follows the authored action height")
	check(s.nearest().get("id") == "luggage", "Moved luggage remains readable at its actual location")
	game.player.position += Vector2(-44,8)
	check(s.nearest().get("id") == "luggage", "The crate's own cover does not block its interaction from outside")
	s.save_path = path
	s.autosave = true
	check(s.save_now() == OK, "Prepare durable route snapshot")
	s.last_region = ""
	DirAccess.make_dir_absolute(path + ".tmp")
	game.player.position = Vector2(11000,1424)
	s.step(0.2)
	check(s.last_region.is_empty() and not s.has("inner_reached"), "Failed region save cannot cache arrival or unlock departure")
	DirAccess.remove_absolute(path + ".tmp")
	s.save_now()
	s.step(0.2)
	check(s.has("inner_reached") and s.last_region == "mon_14", "Arrival retries after storage recovery without leaving the room")
	var saved: Dictionary = s.state.snapshot()
	DirAccess.make_dir_absolute(path + ".tmp")
	at(s,"departure")
	s.interact("departure")
	s.choose("depart")
	check(not s.has("departed") and not s.groups.has("elite") and s.state.snapshot() == saved, "Failed departure save cannot publish state, battle or checkpoint")
	check(s.ui.is_panel_open(), "Failed confirmation remains available to retry")
	DirAccess.remove_absolute(path + ".tmp")
	s.choose("depart")
	s.close()
	check(s.has("departed") and s.state.snapshot().checkpoint == "cp_mon_15", "Successful confirmation atomically advances to Celine checkpoint")
	var disk = Store.new()
	disk.configure(Data.catalog(),Data.quests())
	check(disk.load_from(path) == OK and disk.has_flag("departed") and disk.snapshot().selected_route == "maintenance", "Departure and selected route survive a fresh load")
	for guard in s.groups.elite: guard.state = ShieldEnemy.State.DEAD
	s.enemy_down("elite")
	s.close()
	check(s.has("celine_defeated") and s.state.snapshot().checkpoint == "cp_mon_16", "Celine victory immediately saves boss checkpoint")
	check(not s.checkpoint_allowed("cp_mon_15"), "Exploration cannot regress boss retry checkpoint")
	for guard in s.groups.boss: guard.state = ShieldEnemy.State.DEAD
	s.enemy_down("boss")
	check(s.has("vira_dead") and s.has("gate_return") and s._victory_quiet > 0, "Victory opens return route and leaves a quiet interval")
	game.reset_trial(3)
	check(game.enemies.is_empty(), "Postboss reconstruction does not repopulate the return path")
	var old: Dictionary = disk.snapshot()
	old.version = 1
	old.erase("selected_route")
	var file := FileAccess.open(path + ".legacy",FileAccess.WRITE)
	file.store_string(JSON.stringify(old))
	file.close()
	check(disk.load_from(path + ".legacy") == OK and disk.has_flag("departed") and disk.snapshot().selected_route == "", "Version1 migration preserves formal facts and permits unselected route")
	game.free()
	for suffix in ["", ".bak", ".tmp", ".legacy"]:
		if FileAccess.file_exists(path + suffix): DirAccess.remove_absolute(path + suffix)
	print("CAMPAIGN FLOW STAGE RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
