extends SceneTree
## Scripted event-order integration, not a traversal or human playthrough.
var checks := 0
var failures := 0
var presentation
var session
var cue
var callbacks := 0
var save_path := "user://chapter_sequence_%s.json" % Time.get_ticks_usec()

func _initialize() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func floor_at(position: Vector2) -> void:
	var player = session.lab.player
	player.position = position
	player.velocity = Vector2.ZERO
	for i in 30: player.step(InputFrame.new(),1.0/60)
	session.lab.combat_timer = 0
func at(id: String) -> void:
	for point in session.points:
		if point.id == id:
			session.lab.player.position = point.position
			session.lab.player.velocity = Vector2.ZERO
			return
	check(false,"Authored interaction exists: " + id)
func drain() -> Array[String]:
	var played: Array[String] = []
	for i in 100:
		if session.ui.is_panel_open(): session.close()
		floor_at(Vector2(1260,1120))
		cue._process(0.5)
		if cue.active():
			played.append(str(cue.current.id))
			cue.finish()
		if not cue.active() and cue.pending.is_empty() and not session.ui.is_panel_open(): break
	check(cue.enabled and not cue.active() and cue.pending.is_empty(),"Enabled cue queue and actual dialogue closures settle")
	return played

func reset_pending_duel(archetype: String, id: String) -> void:
	session.lab.reset_trial(3)
	session.lab.player.manual_control = true
	session.lab.player.invulnerability = 10000
	check(cue.pending.is_empty() and not cue.active(),"Reset cancels old duel continuation: " + id)
	floor_at(Vector2(1260,1120))
	session.step(0.1)
	check(cue.pending.is_empty(),"Restored duel waits until approached: " + id)
	session.lab.player.position = session.story_position(archetype)
	session.lab.player.velocity = Vector2(0,900)
	session.step(0.1)
	check(cue.pending.is_empty(),"Restored duel does not capture a falling player: " + id)
	floor_at(session.story_position(archetype))
	session.step(0.1)
	check(cue.pending.any(func(item): return item.id == id),"Same-run reset restores unfinished duel: " + id)

func run() -> void:
	for maintenance_first in [true,false]:
		presentation = load("res://scenes/game.tscn").instantiate()
		root.add_child(presentation)
		for i in 12: await process_frame
		session = presentation.stage.game.campaign_session
		cue = presentation.chapter_staging
		session.lab.player.manual_control = true
		session.lab.player.invulnerability = 10000
		presentation.handle_flow_action("begin")
		check("arrival" in drain(),"New run plays arrival before control")
		for evidence in ["tools","records"]:
			at(evidence)
			session.interact(evidence)
			check(session.ui.panel_kind == "dialogue" and session.has(evidence),"Early evidence opens real inspection: " + evidence)
			session.close()
		if maintenance_first:
			session.interact("maintenance_isolate")
			check("route_service" in drain(),"Maintenance route presents its committed result")
		at("ina")
		session.talk("ina")
		check(session.has("repair_explained") and not session.tool_choices().is_empty(),"Early tools remain deliverable after meeting Ina")
		session.close()
		session.interact("lift_repair")
		check("route_lift" in drain(),"Lift repair cue plays without deciding tools ownership")
		if not maintenance_first:
			session.interact("maintenance_isolate")
			check("route_service" in drain(),"Reverse route order also opens maintenance")
		check(session.has("lift_repaired") and session.has("maintenance_open") and not session.side_done("tools"),"Both routes coexist before delivery")
		for npc in ["mara","vira"]:
			at(npc)
			session.talk(npc)
			check(not session.ui.is_panel_open(),"First meeting waits for comic introduction: " + npc)
			check(npc in drain() and session.has("heard_mon."+npc+".hello"),"Intro continues into existing NPC dialogue: " + npc)
		var vira_start: Vector2 = session.npc_actors.vira.position
		session.npc_actors.vira._process(0.5)
		check(session.npc_actors.vira.position != vira_start,"Closing Vira dialogue starts her real departure walk")
		var deliveries := [["ruka","records_ruka"],["ina","tools_ina"]] if maintenance_first else [["mara","tools_mara"],["mara","records_mara"]]
		for delivery in deliveries:
			at(delivery[0])
			session.talk(delivery[0])
			session.choose(delivery[1])
			check(session.has(delivery[1]) and session.ui.is_panel_open(),"Committed delivery keeps recipient dialogue before result cue")
			var id: String = delivery[1].split("_")[0]
			check(id in drain(),"Delivery result follows actual dialogue closure: " + id)
		session.talk("vira")
		session.close()
		at("luggage")
		session.interact("luggage")
		session.choose("luggage_home" if maintenance_first else "luggage_cart")
		check("luggage" in drain(),"Luggage result preserves both placement alternatives")
		session.event("inner_reached")
		check("departure" in drain() and not session.has("departed"),"Preparation cue never confirms departure")
		at("departure")
		session.interact("departure")
		session.choose("later")
		check(not session.has("departed"),"Wait option preserves exploration")
		at("departure")
		session.interact("departure")
		session.choose("depart")
		var opening_shot := ShotContext.new()
		opening_shot.damage = 10000
		var elite = session.groups.elite[0]
		var initial_health: float = elite.health
		elite.receive_hit(opening_shot,elite.position)
		check(elite.health == initial_health,"A staged opponent cannot be killed while its introduction is waiting")
		reset_pending_duel("elite","celine_duel")
		check("celine_duel" in drain() and session.has("departed"),"Explicit confirmation stages Celine before combat")
		session.lab.reset_trial(3)
		floor_at(session.story_position("elite"))
		session.step(0.1)
		check(cue.pending.is_empty() and not session.groups.elite[0].staging_locked,"Completed Celine duel never replays or relocks after reset")
		# Inject combat outcomes; this test does not claim to defeat either actor by play.
		for guard in session.groups.elite: guard.state = ShieldEnemy.State.DEAD
		session.enemy_down("elite")
		check(session.ui.is_panel_open() and not cue.active(),"Celine speaks before her postbattle cue")
		check("celine_after" in drain() and session.has("celine_defeated") and not session.has("vira_dead"),"Nonlethal Celine result does not end the hunt")
		check(session.npc_actors.celine.visible,"Surviving Celine remains in the world")
		floor_at(session.story_position("boss"))
		session.step(0.1)
		check(not session.has("boss_met"),"Boss introduction waits for the post-Celine interval")
		session.step(4.1)
		check(session.has("boss_met"),"Approaching Vira after the interval records the confrontation")
		reset_pending_duel("boss","vira_duel")
		check("vira_duel" in drain(),"Approaching Vira after reset restores her dialogue")
		session.lab.reset_trial(3)
		floor_at(session.story_position("boss"))
		session.step(0.1)
		check(cue.pending.is_empty() and not session.groups.boss[0].staging_locked,"Completed Vira duel never replays or relocks after reset")
		for guard in session.groups.boss: guard.state = ShieldEnemy.State.DEAD
		session.enemy_down("boss")
		cue._process(0.5)
		check(not cue.active() and session._victory_quiet > 0,"Victory initially leaves the real scene quiet")
		check("vira_after" in drain() and session.has("gate_return"),"Death result follows quiet interval and opens return")
		at("mara")
		session.talk("mara")
		check(session.has("returned") and session.ui.is_panel_open(),"Mara responds before return completion card")
		check("return" in drain(),"Return card follows final conversation")
		session.save_path = save_path
		session.autosave = true
		check(session.save_now() == OK,"Save the completed staging facts")
		check(session.load_save() == OK,"Reload completed progression")
		cue.request("arrival",func(): callbacks += 1)
		check(callbacks == (1 if maintenance_first else 3) and cue.pending.is_empty(),"Reloaded seen cue continues without replay")
		cue.request("first_guard",func(): callbacks += 1)
		check(callbacks == (2 if maintenance_first else 4),"Legacy progressed facts skip unseen early cue")
		cue.pending.append({"id":"stairs","after":func(): callbacks += 100,"generation":cue._generation,"delay":0.0})
		session.lab.reset_trial(3)
		cue._process(1.0)
		check(cue.pending.is_empty() and not cue.active() and callbacks < 100,"World reset cancels queued old-world continuations")
		paused = false
		presentation.free()
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(save_path+suffix): DirAccess.remove_absolute(save_path+suffix)
	print("CHAPTER SEQUENCE STAGE RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
