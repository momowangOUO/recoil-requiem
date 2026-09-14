extends Node
## One event store drives dialogue, gates, map and checkpoint reconstruction.
const Data = preload("res://scripts/campaign/monastery_data.gd")
const Store = preload("res://scripts/campaign/campaign_state.gd")
const UI = preload("res://scripts/ui/campaign_ui.gd")
const Enemy = preload("res://scripts/combat/campaign_enemy.gd")
const NPC = preload("res://scripts/campaign/campaign_npc.gd")
const SAVE_PATH := "user://monastery_v2.json"
var lab: Node
var state = Store.new()
var ui: Control
var copy := Data.texts()
var autosave := true
var groups: Dictionary = {}
var points: Array = []
var modal_actions: Dictionary = {}
var initialized := false
var last_region := ""
var tick := 0.0
var current_npc := ""
var selected_side := ""
var observed_people: Dictionary = {}
var npc_actors: Dictionary = {}
var ally_cooldown := 0.0

func setup(owner_lab: Node) -> void:
	lab = owner_lab
	if "--campaign-test" in OS.get_cmdline_user_args(): autosave = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	state.configure(Data.catalog(), Data.quests())
	if autosave and FileAccess.file_exists(SAVE_PATH):
		var error: Error = state.load_from(SAVE_PATH)
		if error != OK:
			push_warning("Campaign save rejected; original retained: %s" % error)
			autosave = false
	var layer := CanvasLayer.new()
	layer.layer = 25
	(lab.presentation_host if lab.presentation_host != null else lab).add_child(layer)
	ui = UI.new()
	layer.add_child(ui)
	ui.close_requested.connect(close)
	ui.choice_selected.connect(choose)
	ui.side_selected.connect(select_side)
	for flag in state.snapshot().facts:
		if str(flag).begins_with("heard_"):
			var id: String = str(flag).trim_prefix("heard_")
			observed_people[id.split(".")[1]] = text(id)
	initialized = true

func has(id: String) -> bool:
	return state.has_flag(id)

func event(id: String, kind: String = "fact") -> void:
	if kind in ["fact","evidence"] and has(id): return
	var serial: int = state.snapshot().results.size()
	var result := "%s_%d" % [id, serial] if kind in ["visit", "checkpoint"] else id
	var error: Error = state.apply_event({"event_id":id,"source_id":"monastery","id":id,"result_id":result,"kind":kind})
	assert(error == OK, "Unregistered campaign event: " + id)
	if autosave:
		var save_error: Error = state.save_to(SAVE_PATH)
		if save_error != OK: push_warning("Campaign save failed: %s" % save_error)
	refresh()

func bind_world() -> void:
	groups.clear()
	points.clear()
	npc_actors.clear()
	modal_actions.clear()
	ally_cooldown = 0
	last_region = ""
	ui.close_panel()
	for p in lab.environment.npc_points:
		points.append({"id":p.id,"position":p.position,"npc":true})
		var actor := NPC.new()
		actor.npc_id = p.id
		actor.z_index = -1
		actor.position = p.position
		if p.id in ["vira", "celine"]:
			actor.art_path = "res://assets/characters/campaign/%s.png" % ("boss_actions_v1" if p.id == "vira" else "elite_actions_v1")
		lab.world.add_child(actor)
		npc_actors[p.id] = actor
	for p in lab.environment.action_points:
		points.append({"id":p.id,"position":p.position,"npc":false})
	var checkpoint: String = state.snapshot().checkpoint
	for p in lab.environment.checkpoints:
		if p.id == checkpoint: lab.player.position = p.position
	if checkpoint.is_empty(): event("cp_mon_01", "checkpoint")
	for marker in lab.environment.enemy_spawns:
		var group_id := "clear_%02d" % int(marker.get_meta("encounter_id", 1))
		if has(group_id): continue
		var archetype: String = marker.get_meta("enemy_archetype", "shield")
		if archetype in ["elite", "boss"]: continue
		var guard: ShieldEnemy
		if archetype == "shield": guard = ShieldEnemy.new()
		elif archetype == "rifle": guard = RifleEnemy.new()
		else:
			guard = Enemy.new()
			guard.archetype = archetype
		add_enemy(guard, marker.position, group_id)
	if has("departed") and not has("celine_defeated"): spawn_special("elite")
	if has("celine_defeated") and not has("vira_dead"): spawn_special("boss")
	refresh()

func add_enemy(guard: ShieldEnemy, at: Vector2, group_id: String) -> void:
	guard.position = at
	guard.hit_received.connect(lab._enemy_hit)
	guard.defeated.connect(func(): enemy_down.call_deferred(group_id))
	lab.world.add_child(guard)
	guard.add_to_group("campaign_enemies")
	lab.enemies.append(guard)
	guard.process_mode = Node.PROCESS_MODE_DISABLED
	if not groups.has(group_id): groups[group_id] = []
	groups[group_id].append(guard)
	lab.environment.stage.add_actor(guard)

func spawn_special(archetype: String) -> void:
	if groups.has(archetype): return
	var at := Vector2(10350, 1120) if archetype == "elite" else Vector2(11500, 400)
	var guard := Enemy.new()
	guard.archetype = archetype
	add_enemy(guard, at, archetype)

func enemy_down(group_id: String) -> void:
	if not groups.has(group_id): return
	for guard in groups[group_id]:
		if is_instance_valid(guard) and guard.state != ShieldEnemy.State.DEAD: return
	if group_id == "elite":
		for guard in groups[group_id]: guard.hide()
		event("celine_defeated")
		spawn_special("boss")
		dialogue("celine", ["mon.celine.defeated"])
	elif group_id == "boss":
		event("vira_dead")
		event("gate_return")
	else: event(group_id)

func step(delta: float) -> void:
	if has("celine_helped") and has("gate_west") and not has("celine_returned") and not has("departed") and npc_actors.has("celine") and lab.player.position.distance_to(npc_actors.celine.position) < 42:
		event("celine_returned")
		dialogue("celine",["mon.player.return","mon.celine.return"])
		return
	if has("celine_defeated") and not has("vira_dead") and not has("boss_met") and lab.player.position.distance_to(Vector2(11500,400)) < 550:
		event("boss_met")
		dialogue("vira",["mon.vira.fight","mon.player.fight","mon.vira.answer"])
		return
	# Scene residency is cheap; only nearby actors simulate and at most six engage.
	ally_cover(delta)
	var active := 0
	var ordered: Array = lab.enemies.duplicate()
	ordered.sort_custom(func(a, b): return a.position.distance_squared_to(lab.player.position) < b.position.distance_squared_to(lab.player.position))
	for guard in ordered:
		if not is_instance_valid(guard) or guard.state == ShieldEnemy.State.DEAD: continue
		if guard.position.y > lab.environment.bounds.end.y + 96:
			var fall := ShotContext.new()
			fall.source_position = guard.position
			fall.damage = 100000
			guard.receive_hit(fall,guard.position)
			continue
		var awake: bool = guard.position.distance_to(lab.player.position) < 600 and active < 6
		guard.target = lab.player if awake else null
		var mode := Node.PROCESS_MODE_PAUSABLE if awake else Node.PROCESS_MODE_DISABLED
		if guard.process_mode != mode: guard.process_mode = mode
		if awake: active += 1
	tick += delta
	if tick < 0.15: return
	tick = 0
	var region: String = lab.environment.space_at(lab.player.position + Vector2(0,-2))
	if not region.is_empty() and region != last_region:
		last_region = region
		event(region, "visit")
		if region == "mon_14" and not has("inner_reached"): event("inner_reached")
	for p in lab.environment.checkpoints:
		if lab.player.is_on_floor() and lab.player.position.distance_to(p.position) < 40 and state.snapshot().checkpoint != p.id:
			event(p.id, "checkpoint")
	refresh()

func refresh() -> void:
	if not initialized or not is_instance_valid(lab.environment): return
	for gate in ["gate_entry", "gate_west", "gate_east", "gate_return"]:
		lab.environment.set_gate_state(gate, has(gate))
	lab.environment.set_gate_state("gate_departure", has("celine_defeated"))
	lab.environment.set_gate_state("gate_departure_back", has("celine_defeated"))
	for id in npc_actors:
		var actor: Node2D = npc_actors[id]
		actor.visible = not (id == "vira" and has("departed")) and not (id == "celine" and has("departed") and not has("celine_defeated"))
		if id == "celine" and has("celine_defeated"):
			actor.position = Vector2(3400,1120) if has("vira_dead") else Vector2(10300,1120)
			for point in points:
				if point.id == "celine": point.position = actor.position
	var title := "mon.main01.title"
	if has("met_mara"): title = "mon.main02.title"
	if has("met_vira"): title = "mon.main03.title"
	if has("inner_reached"): title = "mon.main04.title"
	if has("departed"): title = "mon.main05.title"
	if has("celine_defeated"): title = "mon.main06.title"
	if has("vira_dead"): title = "mon.main07.title"
	if has("returned"): title = "mon.exit.notice"
	var side: String = tracked_side_text()
	ui.set_tracker(text(title), side)

func text(id: String) -> String:
	return copy.get(id, id)

func nearest() -> Dictionary:
	var best: Dictionary = {}
	var distance := 48.0
	for p in points:
		if p.get("npc",false) and p.id == "vira" and has("departed"): continue
		if p.get("npc",false) and p.id == "celine" and has("departed") and not has("celine_defeated"): continue
		var d: float = lab.player.position.distance_to(p.position)
		if d >= distance: continue
		var ray := PhysicsRayQueryParameters2D.create(lab.player.position + Vector2(0,-18), p.position + Vector2(0,-18), 1)
		if not lab.player.get_world_2d().direct_space_state.intersect_ray(ray).is_empty(): continue
		best = p
		distance = d
	return best

func handle_input(input: InputEvent) -> bool:
	if not input is InputEventKey or not input.pressed or input.echo: return false
	if ui.is_panel_open():
		if input.physical_keycode in [KEY_ESCAPE, KEY_J, KEY_M]: close()
		return true
	if lab.paused: return false
	match input.physical_keycode:
		KEY_F9:
			dialogue("",["mon.restart.prompt"],[["restart","mon.restart.confirm"],["later","mon.restart.cancel"]])
			return true
		KEY_E:
			var p := nearest()
			if p.get("npc",false) and lab.combat_timer > 0:
				lab.overlay.show_notice(text("mon.combat.busy"))
				return true
			if not p.is_empty(): interact(p.id, p.get("npc",false))
			return true
		KEY_J:
			pause()
			ui.show_journal(journal_entries())
			return true
		KEY_M:
			pause()
			var spaces: Dictionary = {}
			for id in lab.environment.space_bounds:
				spaces[id] = {"rect":lab.environment.space_bounds[id], "title":Data.SPACE_NAMES[int(id.trim_prefix("mon_"))-1]}
			ui.show_map(spaces,lab.environment.connections,state.snapshot().visited_regions,lab.environment.gate_states,lab.player.position,lab.environment.checkpoints)
			return true
	return false

func pause() -> void:
	lab.paused = true
	lab.reading = true
	lab.player.clear_jump_buffer()
	lab.input_adapter.suppress()
	lab.reticle.hide()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func close() -> void:
	ui.close_panel()
	modal_actions.clear()
	lab.resume_trial()

func dialogue(speaker: String, ids: Array, choices: Array = []) -> void:
	pause()
	current_npc = speaker
	var lines: Array = []
	for id in ids:
		var parts: PackedStringArray = str(id).split(".")
		var who: String = parts[1] if parts.size() > 2 and Data.NAMES.has(parts[1]) else ""
		lines.append((str(Data.NAMES[who]) + "：" if not who.is_empty() else "") + text(id))
		if not who.is_empty() and who != "player":
			observed_people[who] = text(id)
			event("heard_"+str(id))
	modal_actions.clear()
	var options: Array = []
	for choice in choices:
		options.append({"id":choice[0],"text":text(choice[1])})
		modal_actions[choice[0]] = true
	var has_spoken_line := false
	for id in ids:
		if str(id).begins_with("mon." + speaker + ".") and Data.NAMES.has(speaker): has_spoken_line = true
	ui.show_dialogue(Data.NAMES.get(speaker,"") if has_spoken_line else "",lines,options)

func interact(id: String, npc: bool = false) -> void:
	if id.ends_with("_travel"):
		var destination: Vector2 = lab.environment.shortcut_destination(lab.player.position)
		if destination != Vector2.INF:
			lab.player.position = destination
			lab.player.velocity = Vector2.ZERO
			lab.input_adapter.suppress()
		else: lab.overlay.show_notice(text("mon.passage.locked"))
		return
	if id.begins_with("gate_"):
		event(id)
		return
	if npc:
		talk(id)
		return
	match id:
		"tools", "records", "luggage":
			event(id,"evidence")
			if id == "tools": dialogue("",["mon.tools.inspect"])
			elif id == "records": dialogue("",["mon.records.note"])
			else:
				var options: Array = luggage_choices() if has("luggage_request") else []
				dialogue("vira",["mon.luggage.tag"],options)
		"departure":
			if has("departed"): return
			if not has("met_vira"): return
			dialogue("vira",["mon.depart.prompt"],[["depart","mon.depart.confirm"],["later","mon.depart.wait"]])
		"exit":
			if has("vira_dead"): dialogue("mara",["mon.exit.notice"])

func tool_choices() -> Array:
	if not has("tools") or has("departed") or has("tools_ina") or has("tools_mara"): return []
	return [["tools_ina","mon.tools.return.choice"],["tools_mara","mon.tools.keep.choice"],["later","mon.tools.later.choice"]]

func record_choices() -> Array:
	if not has("records") or has("departed") or has("records_ruka") or has("records_mara"): return []
	return [["records_ruka","mon.records.ruka.choice"],["records_mara","mon.records.mara.choice"],["later","mon.records.keep.choice"]]

func luggage_choices() -> Array:
	if not has("luggage") or not has("luggage_request") or has("departed") or has("luggage_home") or has("luggage_cart"): return []
	return [["luggage_home","mon.luggage.return.choice"],["luggage_cart","mon.luggage.leave.choice"],["later","mon.luggage.defer.choice"]]

func choose(id: String) -> void:
	if not modal_actions.has(id): return
	var interaction := nearest()
	var here: String = interaction.get("id", "")
	var delivery_sites := {"tools_ina":"ina", "tools_mara":"mara", "records_ruka":"ruka", "records_mara":"mara"}
	if delivery_sites.has(id) and here != delivery_sites[id]: return
	if id.begins_with("tools_") and tool_choices().is_empty(): return
	if id.begins_with("records_") and record_choices().is_empty(): return
	if id.begins_with("luggage_") and (here != "luggage" or luggage_choices().is_empty()): return
	if id == "depart" and (has("departed") or not has("met_vira") or here != "departure"): return
	close()
	if id == "later": return
	if id == "restart":
		state = Store.new()
		state.configure(Data.catalog(),Data.quests())
		observed_people.clear()
		selected_side = ""
		lab.reset_trial.call_deferred(3)
		return
	if id == "depart":
		event("departed")
		spawn_special("elite")
		dialogue("celine",["mon.celine.stop","mon.player.stop","mon.celine.worked" if has("celine_helped") else "mon.celine.strangers","mon.player.continue"])
		return
	if has("departed"): return
	var conflicts := {"tools_ina":"tools_mara","tools_mara":"tools_ina","records_ruka":"records_mara","records_mara":"records_ruka","luggage_home":"luggage_cart","luggage_cart":"luggage_home"}
	if not conflicts.has(id) or has(conflicts[id]) or has(id): return
	event(id)
	var results := {"tools_ina":["ina","mon.ina.returned"],"tools_mara":["mara","mon.mara.tools"],"records_ruka":["ruka","mon.ruka.records"],"records_mara":["mara","mon.mara.records"],"luggage_home":["vira","mon.vira.returned"],"luggage_cart":["vira","mon.vira.left"]}
	if id == "tools_ina": event("gate_west")
	if id == "tools_mara": event("gate_entry")
	if id.begins_with("records_"): event("gate_east")
	# Moving a box is a local action; Vira comments when approached again.
	if not id.begins_with("luggage_"):
		dialogue(results[id][0],[results[id][1]])

func talk(id: String) -> void:
	if id == "vira" and has("departed"): return
	if has("vira_dead"):
		match id:
			"mara":
				event("met_mara")
				event("returned")
				dialogue(id,["mon.mara.after","mon.exit.notice"])
			"ina":
				event("met_ina")
				if has("tools_ina"): dialogue(id,["mon.ina.after.return"])
				elif has("tools_mara"): dialogue(id,["mon.ina.after.keep"])
				else: dialogue("",["mon.closed.side.notice"])
			"ruka":
				event("met_ruka")
				dialogue(id,["mon.ruka.after.records" if has("records_ruka") or has("records_mara") else "mon.ruka.after.none"])
			"celine": dialogue(id,["mon.celine.after.helped" if has("celine_helped") else "mon.celine.after.other"])
		return
	match id:
		"mara":
			if not has("met_mara"):
				event("met_mara")
				dialogue(id,["mon.mara.hello","mon.player.entry","mon.mara.ask","mon.player.target","mon.mara.target"])
			else:
				var lines := ["mon.mara.repeat"]
				var choices: Array = []
				if not tool_choices().is_empty():
					lines.append("mon.tools.inspect")
					choices.append(["tools_mara","mon.tools.keep.choice"])
				if not record_choices().is_empty():
					lines.append("mon.records.note")
					choices.append(["records_mara","mon.records.mara.choice"])
				if not choices.is_empty():
					choices.append(["later","mon.records.keep.choice" if has("records") else "mon.tools.later.choice"])
				elif has("departed") and ((has("tools") and not side_done("tools")) or (has("records") and not side_done("records"))):
					lines.append("mon.closed.side.notice")
				dialogue(id,lines,choices)
		"vira":
			if not has("met_vira"):
				event("met_vira")
				dialogue(id,["mon.vira.hello","mon.player.hunt","mon.vira.recognize","mon.player.confirm","mon.vira.reply","mon.player.luggage","mon.vira.luggage"])
			else:
				if has("luggage_home"): dialogue(id,["mon.vira.returned"])
				elif has("luggage_cart"): dialogue(id,["mon.vira.left"])
				else:
					event("luggage_request")
					dialogue(id,["mon.vira.request"])
		"ina":
			var first := not has("met_ina")
			event("met_ina")
			if has("tools_mara"): dialogue(id,["mon.ina.withheld"])
			elif has("tools_ina"): dialogue(id,["mon.ina.returned"])
			elif has("departed"): dialogue("",["mon.closed.side.notice"])
			elif has("tools"):
				var lines := ["mon.ina.hello","mon.player.tools","mon.ina.tools","mon.tools.inspect"] if first else ["mon.tools.inspect"]
				dialogue(id,lines,[["tools_ina","mon.tools.return.choice"],["later","mon.tools.later.choice"]])
			else: dialogue(id,["mon.ina.hello","mon.player.tools","mon.ina.tools"] if first else ["mon.ina.repeat"])
		"ruka":
			var first := not has("met_ruka")
			event("met_ruka")
			var lines := ["mon.ruka.hello","mon.player.route","mon.ruka.route"] if first else ["mon.ruka.route"]
			if has("departed") and not has("records_ruka") and not has("records_mara"): lines.append("mon.closed.side.notice")
			elif has("records"): lines.append("mon.records.note")
			dialogue(id,lines,[["records_ruka","mon.records.ruka.choice"],["later","mon.records.keep.choice"]] if not record_choices().is_empty() else [])
		"celine":
			if has("celine_defeated"):
				dialogue(id,["mon.celine.defeated"])
				return
			if has("departed"): return
			event("met_celine")
			dialogue(id,["mon.celine.hello","mon.celine.cover"])

func side_known(id: String) -> bool:
	return has({"tools":"met_ina", "records":"met_ruka", "luggage":"luggage_request"}.get(id,""))

func side_done(id: String) -> bool:
	var outcomes := {"tools":["tools_ina","tools_mara"], "records":["records_ruka","records_mara"], "luggage":["luggage_home","luggage_cart"]}
	if not outcomes.has(id): return false
	return has(outcomes[id][0]) or has(outcomes[id][1])

func tracked_side_text() -> String:
	if selected_side.is_empty() or has("departed") or not side_known(selected_side) or side_done(selected_side): return ""
	return text("mon." + selected_side + ".title")

func select_side(id: String) -> void:
	if id not in ["tools","records","luggage"] or not side_known(id) or side_done(id) or has("departed"): return
	selected_side = id
	refresh()
	ui.show_journal(journal_entries())

func ally_cover(delta: float) -> void:
	ally_cooldown = maxf(0, ally_cooldown-delta)
	if has("departed") or not has("met_celine") or ally_cooldown > 0 or not npc_actors.has("celine"): return
	var ally: Node2D = npc_actors.celine
	if lab.player.position.distance_to(ally.position) > 450: return
	var candidates: Array = lab.enemies.duplicate()
	candidates.sort_custom(func(a,b): return a.position.distance_squared_to(ally.position) < b.position.distance_squared_to(ally.position))
	for guard in candidates:
		if guard.state == ShieldEnemy.State.DEAD or guard.position.distance_to(ally.position) > 360: continue
		var origin := ally.position + Vector2(0,-24)
		var end: Vector2 = guard.position + Vector2(0,-24)
		var ray := PhysicsRayQueryParameters2D.create(origin,end,1)
		if not lab.player.get_world_2d().direct_space_state.intersect_ray(ray).is_empty(): continue
		var shot := ShotContext.new()
		shot.source_position = origin
		shot.direction = (end-origin).normalized()
		shot.damage = 16
		shot.knockback = 80
		guard.receive_hit(shot,end)
		ally_cooldown = 0.85
		var tracer := Line2D.new()
		tracer.points = PackedVector2Array([origin,end])
		tracer.width = 0.7
		tracer.default_color = Color("eed3a2")
		lab.world.add_child(tracer)
		tracer.create_tween().tween_callback(tracer.queue_free).set_delay(0.08)
		lab.audio.play("revolver")
		if lab.combat_timer > 0: event("celine_helped")
		return

func journal_entries() -> Array:
	var entries: Array = []
	for index in range(1,8):
		var id := "mon_main_%02d" % index
		var status: String = state.quest_status(id)
		if status != "locked":
			var titles := ["mon.main01.title","mon.main02.title","mon.main03.title","mon.main04.title","mon.main05.title","mon.main06.title","mon.main07.title"]
			var body: String = UI.STATUS_COPY.complete if status == "completed" else UI.STATUS_COPY.active
			if index in [1,3]: body += "\n" + text("mon.main%02d.hint" % index)
			entries.append({"title":text(titles[index-1]),"body":body, "category":"tasks"})
	for id in ["tools","records","luggage"]:
		if not side_known(id): continue
		var body: String = UI.STATUS_COPY.complete if side_done(id) else (text("mon.closed.side.notice") if has("departed") else UI.STATUS_COPY.active)
		var entry := {"title":text("mon."+id+".title"), "body":body, "category":"tasks"}
		if not side_done(id) and not has("departed"):
			entry["track_id"] = id
			entry["tracked"] = selected_side == id
		entries.append(entry)
	for id in ["mara","ina","ruka","vira","celine"]:
		if has("met_"+id) or (id == "celine" and has("departed")):
			entries.append({"title":Data.NAMES[id],"body":observed_people.get(id,""),"category":"people"})
	for id in ["tools","records","luggage"]:
		if has(id):
			var body := text({"tools":"mon.tools.inspect","records":"mon.records.note","luggage":"mon.luggage.tag"}[id])
			if id == "records": body += "\n" + text("mon.records.read.notice")
			entries.append({"title":text("mon."+id+".title"),"body":body,"category":"clues"})
	if has("tools_ina") or has("tools_mara"):
		entries.append({"title":text("mon.tools.title"), "body":text("mon.tools.returned.notice" if has("tools_ina") else "mon.tools.kept.notice"), "category":"consequences"})
	if has("records_ruka") or has("records_mara"):
		entries.append({"title":text("mon.records.title"), "body":text("mon.ruka.records" if has("records_ruka") else "mon.mara.records"), "category":"consequences"})
	if has("vira_dead") and has("luggage"):
		entries.append({"title":text("mon.luggage.title"),"body":text("mon.evidence.luggage.home" if has("luggage_home") else "mon.evidence.luggage.cart"),"category":"consequences"})
	return entries
