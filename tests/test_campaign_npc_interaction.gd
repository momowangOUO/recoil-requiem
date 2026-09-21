extends SceneTree

const State = preload("res://scripts/campaign/campaign_state.gd")
const Data = preload("res://scripts/campaign/monastery_data.gd")
const SAVE_PATH := "user://campaign_npc_interaction_fixture/save.json"

var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func press_e(session) -> void:
	var input := InputEventKey.new()
	input.physical_keycode = KEY_E
	input.pressed = true
	check(session.handle_input(input), "E is consumed by campaign session")

func at(session, id: String) -> void:
	for point in session.points:
		if point.id == id:
			session.lab.player.position = point.position
			return
	check(false, "Missing interaction point " + id)

func last_notice(game) -> String:
	if game.overlay.combat != null and not game.overlay.combat.messages.is_empty():
		return str(game.overlay.combat.messages[-1].text)
	return ""

func run() -> void:
	var game: RecoilLab = load("res://scenes/crimson_slice.tscn").instantiate()
	game.campaign_enabled = true
	root.add_child(game)
	game.player.manual_control = true
	var session = game.campaign_session
	session.autosave = false

	check(session.npc_actors.size() == 5, "Actual image map mounts all five NPC actors")
	for id in ["mara", "ina", "vira", "celine", "ruka"]:
		at(session, id)
		check(session.nearest().get("id", "") == id, "Actual map selects NPC marker with nearest(): " + id)

	at(session, "mara")
	session.refresh()
	check(session.ui.interaction_prompt_visible() and not session.ui._interaction_label.text.contains("玛拉"), "Unmet NPC prompt does not leak the NPC name")
	press_e(session)
	check(session.has("met_mara") and session.ui.is_panel_open(), "Actual E opens the opening NPC conversation")
	session.close()
	session.refresh()
	check(session.ui.interaction_prompt_visible() and session.ui._interaction_label.text.contains("玛拉"), "Known NPC prompt identifies the NPC after meeting")
	game.combat_timer = 2.0
	session.refresh()
	check(not session.ui.interaction_prompt_visible(), "Combat hides the NPC prompt while dialogue is unavailable")
	press_e(session)
	check(not session.ui.is_panel_open(), "Combat blocks long NPC dialogue without changing quest state")
	game.combat_timer = 0.0
	session.refresh()
	check(session.ui.interaction_prompt_visible(), "NPC prompt returns after combat ends")
	at(session, "departure")
	press_e(session)
	check(not session.ui.is_panel_open() and last_notice(game) == session.text("mon.main02.title"), "Premature departure gives the current target instead of silently doing nothing")
	at(session, "exit")
	press_e(session)
	check(not session.ui.is_panel_open() and last_notice(game) == session.text(Data.main_title_id(session.state.snapshot().facts)), "Locked exit gives the current target instead of silently doing nothing")

	at(session, "records")
	session.refresh()
	check(session.ui._interaction_label.text.contains("阅读") and session.ui._interaction_label.text.contains("维修记录"), "Records prompt uses the approved object label")

	at(session, "tools")
	session.refresh()
	check(session.ui._interaction_label.text.contains("调查"), "Evidence point prompt describes investigation")
	press_e(session)
	session.close()
	at(session, "ina")
	press_e(session)
	check(session.has("met_ina") and session.ui.is_panel_open(), "Actual E opens the side NPC conversation")
	session.choose("tools_ina")
	check(session.has("tools_ina") and session.has("gate_west"), "Actual side choice records consequence and opens shortcut")
	session.close()
	at(session, "tools")
	session.refresh()
	check(session.nearest().is_empty() and not session.ui.interaction_prompt_visible(), "Delivered tools leave no stale interaction point")

	var saved: Dictionary = session.state.snapshot()
	check(session.state.save_to(SAVE_PATH) == OK, "NPC progress saves through the persistent state")
	game.reset_trial(3)
	game.player.manual_control = true
	check(session.state.snapshot() == saved, "Scene reconstruction preserves NPC progress")
	at(session, "ina")
	press_e(session)
	check(session.ui.is_panel_open() and session.has("tools_ina"), "NPC can be revisited after scene reconstruction")
	session.close()

	var reloaded := State.new()
	check(reloaded.configure(Data.catalog(), Data.quests()) == OK, "Fresh state accepts the campaign catalog")
	check(reloaded.load_from(SAVE_PATH) == OK and reloaded.snapshot() == saved, "Saved NPC progress reloads into a fresh state")
	session.state = reloaded
	game.reset_trial(3)
	game.player.manual_control = true
	at(session, "mara")
	press_e(session)
	check(session.ui.is_panel_open() and session.has("met_mara"), "Opening NPC remains functional after state reload")
	session.close()

	for suffix in ["", ".tmp", ".bak"]:
		if FileAccess.file_exists(SAVE_PATH + suffix): DirAccess.remove_absolute(SAVE_PATH + suffix)
	DirAccess.remove_absolute(SAVE_PATH.get_base_dir())
	game.free()
	print("CAMPAIGN NPC INTERACTION STAGE RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
