extends Node
## One event store drives dialogue, gates, map and checkpoint reconstruction.
const Data = preload("res://scripts/campaign/monastery_data.gd")
const Store = preload("res://scripts/campaign/campaign_state.gd")
const UI = preload("res://scripts/ui/campaign_ui.gd")
const Enemy = preload("res://scripts/combat/campaign_enemy.gd")
const NPC = preload("res://scripts/campaign/campaign_npc.gd")
const SAVE_PATH := "user://monastery_v2.json"
# Exact consequences of already-authorized deliveries and the boss settlement.
# Also repairs version-1 saves written between the former two separate writes.
const FACT_CONSEQUENCES := {"vira_dead": "gate_return", "tools_ina": "gate_west", "tools_mara": "gate_entry", "records_ruka": "gate_east", "records_mara": "gate_east"}
signal save_status_changed(status: Dictionary)
# Reviewed standalone system text: game-text/save-status-review.md.
const SAVE_COPY := {
	"ready": "自动保存已开启。",
	"recovered": "已从备份恢复进度，可以继续保存。",
	"load_failed": "存档无法读取，自动保存已暂停。原文件已保留。",
	"write_failed": "进度尚未保存。请检查存储空间或写入权限后重试。",
	"disabled": "自动保存已关闭。"
}
var save_path := SAVE_PATH
var save_status := {"code": "ready", "error": OK, "message": SAVE_COPY.ready, "preserved_path": ""}
var _save_notice_elapsed := 0.0
var _save_notice_pending := false
var loaded_from_disk := false
var restart_backup_path := ""
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
var _interaction_hint_key := ""
var _vira_departure_pending := false
var _victory_quiet := 0.0
var _tracked_main_quest := ""

func _checkpoint_event(id: String) -> Dictionary:
	var serial: int = state.snapshot().results.size()
	return {"event_id":id,"source_id":"monastery","id":id,"result_id":"%s_%d" % [id,serial],"kind":"checkpoint"}

func commit_progress(flags: Array, checkpoint: String = "") -> Error:
	var events: Array = []
	for id in flags:
		events.append(_fact_event(id))
		if FACT_CONSEQUENCES.has(id): events.append(_fact_event(FACT_CONSEQUENCES[id]))
	if not checkpoint.is_empty(): events.append(_checkpoint_event(checkpoint))
	var error: Error
	if autosave:
		error = state.commit_events(events, save_path)
		_set_save_status("ready" if error == OK else "write_failed", error, save_status.preserved_path)
	elif save_status.code == "load_failed": return save_status.error
	else: error = state.apply_events(events)
	if error == OK: refresh()
	return error

func selected_route() -> String:
	return state.snapshot().get("selected_route", "")

func select_route(id: String) -> void:
	if not id in ["lift", "maintenance"] or has("departed") or save_status.code == "load_failed": return
	var serial: int = state.snapshot().results.size()
	var events := [{"event_id":"route_"+id,"source_id":"monastery","id":id,"result_id":"route_%s_%d" % [id,serial],"kind":"route"}]
	var error: Error = state.commit_events(events, save_path) if autosave else state.apply_events(events)
	if error != OK: _set_save_status("write_failed", error)
	elif autosave and save_status.code != "recovered": _set_save_status("ready")
	refresh()

func current_main_title_id() -> String:
	var title := Data.main_title_id(state.snapshot().facts)
	if title != "mon.main03.title": return title
	if selected_route() == "lift": return "mon.flow.route.upper" if has("lift_repaired") else "mon.flow.route.lift"
	if selected_route() == "maintenance": return "mon.flow.route.service"
	return title

func pending_departure_tasks() -> Array[String]:
	var pending: Array[String] = []
	for id in ["tools", "records", "luggage"]:
		if (has(id) if id != "luggage" else has("luggage_request")) and not side_done(id):
			pending.append(text("mon.flow.departure." + id))
	return pending

func chapter_summary() -> Array[String]:
	var summary: Array[String] = []
	for flag in ["records", "lift_repaired", "maintenance_open"]:
		if has(flag): summary.append(text({"records":"mon.flow.chapter.records", "lift_repaired":"mon.flow.chapter.lift", "maintenance_open":"mon.flow.chapter.service"}[flag]))
	if has("tools_ina"): summary.append(text("mon.ina.after.return"))
	elif has("tools_mara"): summary.append(text("mon.ina.after.keep"))
	if has("records_ruka") or has("records_mara"): summary.append(text("mon.ruka.after.records"))
	summary.append(text("mon.flow.chapter.celine"))
	return summary

func setup(owner_lab: Node) -> void:
	lab = owner_lab
	if "--campaign-test" in OS.get_cmdline_user_args(): autosave = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	state.configure(Data.catalog(), Data.quests())
	if autosave: load_save()
	else: _set_save_status("disabled")
	var layer := CanvasLayer.new()
	layer.layer = 25
	(lab.presentation_host if lab.presentation_host != null else lab).add_child(layer)
	ui = UI.new()
	layer.add_child(ui)
	ui.close_requested.connect(close)
	ui.choice_selected.connect(choose)
	ui.side_selected.connect(select_side)
	initialized = true

func has(id: String) -> bool:
	return state.has_flag(id)

func event(id: String, kind: String = "fact") -> Error:
	if kind in ["fact","evidence"] and has(id): return OK
	if save_status.code == "load_failed": return save_status.error
	var serial: int = state.snapshot().results.size()
	var result := "%s_%d" % [id, serial] if kind in ["visit", "checkpoint"] else id
	var events := [{"event_id":id,"source_id":"monastery","id":id,"result_id":result,"kind":kind}]
	if kind == "fact" and FACT_CONSEQUENCES.has(id):
		events.append(_fact_event(FACT_CONSEQUENCES[id]))
	var error: Error = state.commit_events(events, save_path) if autosave else state.apply_events(events)
	if error != OK:
		_set_save_status("write_failed", error, save_status.preserved_path)
		return error
	if autosave and save_status.code != "recovered": _set_save_status("ready")
	refresh()
	return OK

func _fact_event(id: String) -> Dictionary:
	return {"event_id":id,"source_id":"monastery","id":id,"result_id":id,"kind":"fact"}

## Call before binding the world, or rebuild the world after a successful retry.
## Unlike a write retry, this deliberately reloads progress from disk.
func load_save() -> Error:
	var result: Dictionary = state.load_or_recover(save_path)
	var empty_slot := not FileAccess.file_exists(save_path) and not FileAccess.file_exists(save_path + ".bak") and not DirAccess.dir_exists_absolute(save_path) and not DirAccess.dir_exists_absolute(save_path + ".bak")
	if result.error == ERR_FILE_NOT_FOUND and empty_slot:
		autosave = true
		_set_save_status("ready")
		return OK
	if result.error != OK:
		autosave = false
		_set_save_status("load_failed", result.error, result.preserved_path)
		return result.error
	autosave = true
	loaded_from_disk = true
	observed_people.clear()
	selected_side = ""
	for flag in state.snapshot().facts:
		if str(flag).begins_with("heard_"):
			var id: String = str(flag).trim_prefix("heard_")
			observed_people[id.split(".")[1]] = text(id)
	if has("celine_observed") and not observed_people.has("celine"):
		observed_people.celine = text("mon.flow.celine.job")
	_set_save_status("recovered" if result.recovered else "ready", OK, result.preserved_path)
	var repairs: Array = []
	for trigger in FACT_CONSEQUENCES:
		if has(trigger) and not has(FACT_CONSEQUENCES[trigger]):
			repairs.append(_fact_event(FACT_CONSEQUENCES[trigger]))
	if not repairs.is_empty():
		var error: Error = state.apply_events(repairs)
		assert(error == OK, "Invalid campaign save consequence repair")
		# Reading succeeded: the world can use the coherent state even if the
		# repair write fails. save_now exposes the failure and permits retry.
		save_now()
	return OK

## Explicit confirmed restart. Keep a durable archive outside the rotating .bak
## before replacing progress. A rejected save can only be recovered, not erased.
func restart_chapter() -> Error:
	if save_status.code == "load_failed": return save_status.error
	var fresh = Store.new()
	fresh.configure(Data.catalog(), Data.quests())
	if autosave:
		var error := save_now()
		if error != OK: return error
		var archive: String = state._unused_path(save_path + ".restart")
		error = DirAccess.copy_absolute(save_path, archive)
		if error == OK:
			var verify = Store.new()
			verify.configure(Data.catalog(), Data.quests())
			error = verify.load_from(archive)
		if error == OK: error = fresh.save_to(save_path)
		if error != OK:
			_set_save_status("write_failed", error)
			return error
		restart_backup_path = archive
	state = fresh
	loaded_from_disk = false
	observed_people.clear()
	selected_side = ""
	_set_save_status("ready" if autosave else "disabled")
	return OK

## Retry a failed write without discarding progress. Rejected disk saves require
## load_save() recovery first, so this cannot overwrite an unreadable original.
func save_now() -> Error:
	if not autosave:
		return save_status.error if save_status.error != OK else ERR_UNAVAILABLE
	var error: Error = state.save_to(save_path)
	if error != OK:
		_set_save_status("write_failed", error, save_status.preserved_path)
	elif save_status.code != "recovered":
		_set_save_status("ready", OK, save_status.preserved_path)
	return error

func _set_save_status(code: String, error: Error = OK, preserved_path: String = "") -> void:
	var next := {"code": code, "error": error, "message": SAVE_COPY[code], "preserved_path": preserved_path}
	if next == save_status: return
	save_status = next
	_save_notice_elapsed = 0.0
	_save_notice_pending = code in ["recovered", "load_failed", "write_failed"]
	if _save_notice_pending: _show_save_notice()
	save_status_changed.emit(save_status.duplicate(true))

func _show_save_notice() -> void:
	if is_instance_valid(lab) and lab.overlay != null:
		lab.overlay.show_notice(save_status.message)

func _process(delta: float) -> void:
	# The overlay notice expires. Re-show unresolved failures even while paused;
	# menus can always query save_status for the full persistent state.
	_save_notice_elapsed += delta
	if _save_notice_pending or (save_status.code in ["load_failed", "write_failed"] and _save_notice_elapsed >= 8.0):
		_show_save_notice()
		_save_notice_pending = false
		_save_notice_elapsed = 0.0

func bind_world() -> void:
	groups.clear()
	points.clear()
	npc_actors.clear()
	modal_actions.clear()
	_interaction_hint_key = ""
	ally_cooldown = 0
	_vira_departure_pending = false
	last_region = ""
	ui.close_panel()
	for p in lab.environment.npc_points:
		points.append({"id":p.id,"position":p.position,"npc":true})
		var actor := NPC.new()
		actor.npc_id = p.id
		actor.z_index = -1
		actor.position = p.position
		if p.id in ["vira", "celine"]:
			actor.art_path = "res://assets/characters/campaign/%s.png" % ("boss_actions_v2" if p.id == "vira" else "elite_actions_v2")
		lab.world.add_child(actor)
		npc_actors[p.id] = actor
		if p.id == "vira": actor.path_finished.connect(func(): event("vira_relocated"))
		if p.id == "vira" and has("met_vira"):
			actor.position = story_position("vira_after")
			points.back().position = actor.position
	for p in lab.environment.action_points:
		points.append({"id":p.id,"position":p.position,"npc":false})
	var checkpoint: String = state.snapshot().checkpoint
	for p in lab.environment.checkpoints:
		if p.id == checkpoint: lab.player.position = p.position
	if checkpoint.is_empty(): event("cp_mon_01", "checkpoint")
	for marker in lab.environment.enemy_spawns:
		if has("vira_dead"): break
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
		guard.set_meta("wake_radius", marker.get_meta("wake_radius", 600.0))
		guard.set_meta("patrol_bounds", marker.get_meta("patrol_bounds", Rect2()))
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
	var at := story_position(archetype)
	var guard := Enemy.new()
	guard.archetype = archetype
	add_enemy(guard, at, archetype)

func story_position(id: String) -> Vector2:
	# Saves retain event IDs; spatial story points belong to each authored map.
	var authored = lab.environment.get("story_positions")
	if authored is Dictionary and authored.has(id): return authored[id]
	var legacy := {
		"elite": Vector2(10350,1120), "boss": Vector2(11500,400),
		"celine_after": Vector2(10300,1120), "celine_return": Vector2(3400,1120)
	}
	if legacy.has(id): return legacy[id]
	for point in points:
		if point.id == "vira": return point.position
	return Vector2.ZERO

func enemy_down(group_id: String) -> void:
	if not groups.has(group_id): return
	for guard in groups[group_id]:
		if is_instance_valid(guard) and guard.state != ShieldEnemy.State.DEAD: return
	if group_id == "elite":
		if has("celine_defeated"): return
		if commit_progress(["celine_defeated"], "cp_mon_16") != OK: return
		for guard in groups[group_id]: guard.hide()
		spawn_special("boss")
		dialogue("celine", ["mon.celine.defeated"])
	elif group_id == "boss":
		if has("vira_dead"): return
		_victory_quiet = 3.0
		if commit_progress(["vira_dead"], "cp_mon_16") != OK:
			_victory_quiet = 0.0
			return
		if is_instance_valid(lab) and lab.get("projectiles") != null:
			lab.combat_timer = 0
			for projectile in lab.projectiles.get_children(): projectile.queue_free()
	else: event(group_id)

func step(delta: float) -> void:
	_victory_quiet = maxf(0.0, _victory_quiet - delta)
	for encounter in ["elite", "boss"]:
		if groups.has(encounter) and not has("celine_defeated" if encounter == "elite" else "vira_dead"):
			var defeated := true
			for guard in groups[encounter]:
				if is_instance_valid(guard) and guard.state != ShieldEnemy.State.DEAD: defeated = false
			if defeated and save_status.code == "ready": enemy_down(encounter)
	if npc_actors.has("vira"):
		for point in points:
			if point.id == "vira": point.position = npc_actors.vira.position
	if not has("met_celine") and not has("departed") and npc_actors.has("celine") and lab.player.position.distance_to(npc_actors.celine.position) < 180:
		if event("met_celine") == OK:
			observed_people.celine = text("mon.flow.celine.job")
			lab.overlay.show_notice(text("mon.flow.celine.job"))
	if has("met_celine") and not has("departed") and npc_actors.has("celine") and lab.player.position.distance_to(npc_actors.celine.position) < 220 and not has("celine_observed"):
		event("celine_observed")
	if has("celine_helped") and has("gate_west") and not has("celine_returned") and not has("departed") and npc_actors.has("celine") and lab.player.position.distance_to(npc_actors.celine.position) < 42:
		event("celine_returned")
		dialogue("celine",["mon.player.return","mon.celine.return"])
		return
	if has("celine_defeated") and not has("vira_dead") and not has("boss_met") and lab.player.position.distance_to(story_position("boss")) < 550:
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
		var patrol: Rect2 = guard.get_meta("patrol_bounds", Rect2())
		var awake: bool = not has("vira_dead") and guard.position.distance_to(lab.player.position) < float(guard.get_meta("wake_radius",600.0)) and active < 6
		if patrol.has_area() and not patrol.has_point(lab.player.position + Vector2(0,-2)): awake = false
		guard.target = lab.player if awake else null
		var mode := Node.PROCESS_MODE_PAUSABLE if awake else Node.PROCESS_MODE_DISABLED
		if guard.process_mode != mode: guard.process_mode = mode
		if awake: active += 1
	tick += delta
	if tick < 0.15: return
	tick = 0
	var region: String = lab.environment.space_at(lab.player.position + Vector2(0,-2))
	if not region.is_empty() and region != last_region and save_status.code != "write_failed":
		if event(region, "visit") == OK: last_region = region
	if region == "mon_14" and not has("inner_reached") and save_status.code != "write_failed": event("inner_reached")
	for p in lab.environment.checkpoints:
		if lab.player.is_on_floor() and lab.player.position.distance_to(p.position) < 40 and state.snapshot().checkpoint != p.id and checkpoint_allowed(p.id):
			event(p.id, "checkpoint")
	refresh()

func checkpoint_allowed(id: String) -> bool:
	if has("vira_dead"): return id in ["cp_mon_16", "cp_mon_03"]
	if has("celine_defeated"): return id == "cp_mon_16"
	if has("departed"): return id == "cp_mon_15"
	return not id in ["cp_mon_15", "cp_mon_16"]

func refresh() -> void:
	if not initialized or not is_instance_valid(lab.environment): return
	for gate in ["gate_entry", "gate_west", "gate_east", "gate_return"]:
		lab.environment.set_gate_state(gate, has(gate))
	lab.environment.set_gate_state("gate_lift", has("lift_repaired"))
	lab.environment.set_gate_state("gate_maintenance", has("maintenance_open"))
	if lab.environment.has_method("set_luggage_home"):
		lab.environment.set_luggage_home(has("luggage_home"))
		for action in lab.environment.action_points:
			if action.id != "luggage": continue
			for point in points:
				if point.id == "luggage": point.position = action.position
	lab.environment.set_gate_state("gate_departure", has("celine_defeated"))
	lab.environment.set_gate_state("gate_departure_back", has("celine_defeated"))
	for id in npc_actors:
		var actor: Node2D = npc_actors[id]
		actor.visible = not (id == "vira" and has("departed")) and not (id == "celine" and has("departed") and not has("celine_defeated"))
		if id == "celine" and has("celine_defeated"):
			actor.position = story_position("celine_return" if has("vira_dead") else "celine_after")
			for point in points:
				if point.id == "celine": point.position = actor.position
	var title := current_main_title_id()
	var side: String = tracked_side_text()
	var quest := Data.main_title_id(state.snapshot().facts)
	ui.set_tracker("" if _victory_quiet > 0 else text(title), side, _victory_quiet <= 0 and not _tracked_main_quest.is_empty() and quest != _tracked_main_quest)
	_tracked_main_quest = quest
	_update_interaction_prompt({} if lab.combat_timer > 0 else nearest())

func text(id: String) -> String:
	return copy.get(id, id)

func nearest() -> Dictionary:
	var best: Dictionary = {}
	var distance := 48.0
	for p in points:
		if p.id == "tools" and has("tools"): continue
		if p.id.ends_with("_travel") and not lab.environment.gate_states.get(str(p.id).trim_suffix("_travel"), false): continue
		if p.id == "departure" and has("departed"): continue
		if p.get("npc",false) and p.id == "vira" and has("departed"): continue
		if p.get("npc",false) and p.id == "celine" and has("departed") and not has("celine_defeated"): continue
		var d: float = lab.player.position.distance_to(p.position)
		if d >= distance: continue
		var ray := PhysicsRayQueryParameters2D.create(lab.player.position + Vector2(0,-18), p.position + Vector2(0,-18), 1)
		var obstruction: Dictionary = lab.player.get_world_2d().direct_space_state.intersect_ray(ray)
		if not obstruction.is_empty():
			var target_cover: bool = p.id == "luggage" and str(obstruction.collider.get_parent().name).begins_with("Luggage")
			if not target_cover: continue
		best = p
		distance = d
	return best

func _update_interaction_prompt(interaction: Dictionary) -> void:
	if not is_instance_valid(ui) or not ui.has_method("set_interaction_prompt"):
		return
	var key := ""
	var target := ""
	var action := ""
	if not interaction.is_empty():
		var id := str(interaction.get("id", ""))
		var hint: Dictionary = Data.interaction_prompt(id, interaction.get("npc", false), has("met_" + id))
		target = str(hint.get("target", ""))
		action = str(hint.get("action", ""))
		key = id + "|" + target + "|" + action
	if key == _interaction_hint_key:
		return
	_interaction_hint_key = key
	ui.set_interaction_prompt(target, action)

func handle_input(input: InputEvent) -> bool:
	if not input is InputEventKey or not input.pressed or input.echo: return false
	if ui.is_panel_open():
		if input.physical_keycode in [KEY_ESCAPE, KEY_J, KEY_M]: close()
		elif input.physical_keycode in [KEY_E, KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
			if ui.panel_kind == "dialogue": ui.advance_dialogue()
			elif input.physical_keycode != KEY_E: return false
		return input.physical_keycode not in [KEY_TAB, KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN]
	if lab.paused: return false
	match input.physical_keycode:
		KEY_F9:
			dialogue("",["mon.restart.prompt"],[["restart","mon.restart.confirm"],["later","mon.restart.cancel"]])
			return true
		KEY_E:
			var p := nearest()
			if p.get("npc",false) and lab.combat_timer > 0:
				_update_interaction_prompt({})
				lab.overlay.show_notice(text("mon.combat.busy"))
				return true
			_update_interaction_prompt(p)
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
			ui.show_map(spaces,lab.environment.connections,state.snapshot().visited_regions,lab.environment.gate_states,lab.player.position,lab.environment.checkpoints,lab.environment.shortcut_points,lab.environment.gates)
			return true
	return false

func pause() -> void:
	lab.paused = true
	lab.reading = true
	lab.player.clear_jump_buffer()
	lab.input_adapter.suppress()
	lab.reticle.hide()
	if lab.overlay.combat != null:
		lab.overlay.combat.suspend(true)
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func close() -> void:
	ui.close_panel()
	modal_actions.clear()
	lab.resume_trial()
	if _vira_departure_pending:
		_vira_departure_pending = false
		if npc_actors.has("vira"):
			var path: Array[Vector2] = [story_position("vira_departure_mid"), story_position("vira_departure_end")]
			var authored = lab.environment.get("story_positions")
			for index in range(1,6):
				var key := "vira_path_%02d" % index
				if authored is Dictionary and authored.has(key): path.append(authored[key])
			path.append(story_position("vira_after"))
			npc_actors.vira.walk_path(path)

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
	ui.show_dialogue(Data.NAMES.get(speaker,"") if has_spoken_line else "",lines,options,ids)

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
		# Quest gates only open through their corresponding committed consequence.
		if id not in ["gate_lift", "gate_maintenance", "gate_departure", "gate_departure_back"]: event(id)
		return
	if npc:
		talk(id)
		return
	match id:
		"lift_repair":
			select_route("lift")
			if has("lift_repaired"): return
			if has("tools_ina") or has("tools_mara"):
				lab.overlay.show_notice(text("mon.flow.repair.delivered"))
			elif not has("tools") or not has("repair_explained"):
				lab.overlay.show_notice(text("mon.flow.repair.need"))
			elif commit_progress(["lift_repaired"]) == OK:
				lab.overlay.show_notice(text("mon.flow.repair.done"))
		"maintenance_isolate":
			if commit_progress(["maintenance_open"]) == OK:
				select_route("maintenance")
				lab.overlay.show_notice(text("mon.flow.service.safe"))
		"tools", "records", "luggage":
			if id == "tools" and has("tools"): return
			if event(id,"evidence") != OK: return
			if id == "tools": dialogue("",["mon.tools.inspect"])
			elif id == "records": dialogue("",["mon.records.note"])
			else:
				var options: Array = luggage_choices() if has("luggage_request") else []
				dialogue("vira",["mon.luggage.tag", "mon.flow.luggage.preview"] if not options.is_empty() else ["mon.luggage.tag"],options)
		"departure":
			if has("departed"): return
			if not has("met_vira") or not has("met_mara") or not has("inner_reached"):
				lab.overlay.show_notice(text("mon.main02.title"))
				return
			pause()
			modal_actions = {"depart":true,"later":true}
			var lines: Array = [text("mon.flow.departure.body")]
			lines.append_array(pending_departure_tasks())
			ui.show_departure(lines,[{"id":"depart","text":text("mon.flow.departure.go")},{"id":"later","text":text("mon.flow.departure.wait")}],text("mon.flow.departure.title"))
		"exit":
			if has("vira_dead"): dialogue("mara",["mon.exit.notice"])
			else: lab.overlay.show_notice(text(Data.main_title_id(state.snapshot().facts)))

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
	if id == "depart" and (has("departed") or not has("met_vira") or not has("met_mara") or not has("inner_reached") or here != "departure"): return
	if id == "depart" and commit_progress(["departed"], "cp_mon_15") != OK: return
	close()
	if id == "later": return
	if id == "restart":
		if restart_chapter() == OK: lab.reset_trial.call_deferred(3)
		return
	if id == "depart":
		spawn_special("elite")
		dialogue("celine",["mon.celine.stop","mon.player.stop","mon.celine.worked" if has("celine_helped") else "mon.celine.strangers","mon.player.continue"])
		return
	if has("departed"): return
	var conflicts := {"tools_ina":"tools_mara","tools_mara":"tools_ina","records_ruka":"records_mara","records_mara":"records_ruka","luggage_home":"luggage_cart","luggage_cart":"luggage_home"}
	if not conflicts.has(id) or has(conflicts[id]) or has(id): return
	if commit_progress([id]) != OK: return
	var results := {"tools_ina":["ina","mon.ina.returned"],"tools_mara":["mara","mon.mara.tools"],"records_ruka":["ruka","mon.ruka.records"],"records_mara":["mara","mon.mara.records"],"luggage_home":["vira","mon.vira.returned"],"luggage_cart":["vira","mon.vira.left"]}
	# Moving a box is a local action; Vira comments when approached again.
	if not id.begins_with("luggage_"):
		dialogue(results[id][0],[results[id][1]])

func talk(id: String) -> void:
	if id == "vira" and has("departed"): return
	if has("vira_dead"):
		match id:
			"mara":
				if event("met_mara") != OK: return
				if commit_progress(["returned"], "cp_mon_03") != OK: return
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
				if event("met_mara") != OK: return
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
				if event("met_vira") != OK: return
				_vira_departure_pending = true
				dialogue(id,["mon.vira.hello","mon.player.hunt","mon.vira.recognize","mon.player.confirm","mon.vira.reply","mon.player.luggage","mon.vira.luggage"])
			else:
				if has("luggage_home"): dialogue(id,["mon.vira.returned"])
				elif has("luggage_cart"): dialogue(id,["mon.vira.left"])
				else:
					if event("luggage_request") != OK: return
					dialogue(id,["mon.vira.request"])
		"ina":
			var first := not has("met_ina")
			if commit_progress(["met_ina", "repair_explained"]) != OK: return
			if has("tools_mara"): dialogue(id,["mon.ina.withheld"])
			elif has("tools_ina"): dialogue(id,["mon.ina.returned"])
			elif has("departed"): dialogue("",["mon.closed.side.notice"])
			elif has("tools"):
				var lines := ["mon.ina.hello","mon.player.tools","mon.ina.tools","mon.tools.inspect"] if first else ["mon.tools.inspect"]
				dialogue(id,lines,[["tools_ina","mon.tools.return.choice"],["later","mon.tools.later.choice"]])
			else: dialogue(id,["mon.ina.hello","mon.player.tools","mon.ina.tools"] if first else ["mon.ina.repeat"])
		"ruka":
			var first := not has("met_ruka")
			if event("met_ruka") != OK: return
			var lines := ["mon.ruka.hello","mon.player.route","mon.ruka.route"] if first else ["mon.ruka.route"]
			if has("departed") and not has("records_ruka") and not has("records_mara"): lines.append("mon.closed.side.notice")
			elif has("records"): lines.append("mon.records.note")
			dialogue(id,lines,[["records_ruka","mon.records.ruka.choice"],["later","mon.records.keep.choice"]] if not record_choices().is_empty() else [])
		"celine":
			if has("celine_defeated"):
				dialogue(id,["mon.celine.defeated"])
				return
			if has("departed"): return
			if event("met_celine") != OK: return
			dialogue(id,["mon.celine.hello","mon.flow.celine.job","mon.celine.cover"])

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
	if id in ["route_lift", "route_maintenance"]:
		select_route(id.trim_prefix("route_"))
		ui.show_journal(journal_entries())
		return
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
		# Cover interrupts and creates space; it cannot clear the encounter alone.
		shot.damage = minf(16.0, maxf(0.0, guard.health - 1.0))
		shot.knockback = 80
		guard.receive_hit(shot,end)
		ally.play_cover(end)
		ally_cooldown = 0.85
		var tracer := Line2D.new()
		tracer.points = PackedVector2Array([origin,end])
		tracer.width = 0.7
		tracer.default_color = Color("eed3a2")
		lab.world.add_child(tracer)
		tracer.create_tween().tween_callback(tracer.queue_free).set_delay(0.08)
		lab.audio.play("revolver")
		event("celine_helped")
		return

func journal_entries() -> Array:
	var entries: Array = []
	if has("met_vira") and not has("departed"):
		for route in ["lift", "maintenance"]:
			entries.append({"title":text("mon.flow.route.lift.choice" if route == "lift" else "mon.flow.route.service.choice"),"body":text("mon.flow.route.other"),"category":"tasks","track_id":"route_"+route,"tracked":selected_route() == route})
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
