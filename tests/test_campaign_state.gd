extends SceneTree
var checks := 0
var failures := 0
const State = preload("res://scripts/campaign/campaign_state.gd")
const Quest = preload("res://scripts/campaign/quest_definition.gd")
const PATH := "user://campaign_state_test_fixture/save.json"
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func quest(id: String, prerequisites: Array, objectives: Array, completed: String = "") -> Resource:
	var q = Quest.new()
	q.quest_id = id
	q.prerequisite_flags = PackedStringArray(prerequisites)
	q.objective_flags = PackedStringArray(objectives)
	q.completed_flag = completed
	return q
func setup_state():
	var s = State.new()
	check(s.configure({"facts": ["accepted", "gate_open", "other_done"], "evidence": ["proof"], "regions": ["room_a", "room_b"], "checkpoints": {"entry": "room_a"}}, [quest("investigate", ["accepted"], ["proof"], "gate_open"), quest("followup", ["gate_open"], ["other_done"])]) == OK, "Valid references configure")
	return s
func event(kind: String, id: String, result: String = "") -> Dictionary:
	return {"event_id": "fixture_event", "source_id": "fixture_source", "kind": kind, "id": id, "result_id": result if result else kind + "." + id}
func _initialize() -> void:
	var s = setup_state()
	check(s.apply_event(event("evidence", "proof")) == OK, "Collect before accepting")
	check(s.quest_status("investigate") == "locked", "Prerequisites still lock quest")
	check(s.apply_event(event("fact", "accepted")) == OK, "Accept after collecting")
	check(s.quest_status("investigate") == "completed", "Early evidence completes on acceptance")
	run_storage_and_order(s)
	run_atomic_events()
	print("CAMPAIGN STATE STAGE RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func run_atomic_events() -> void:
	var s = setup_state()
	var changes: Array = []
	var completions: Array = []
	var on_changed := func(): changes.append(s.snapshot())
	var on_completed := func(id): completions.append(id)
	s.changed.connect(on_changed)
	s.quest_completed.connect(on_completed)
	var before: Dictionary = s.snapshot()
	check(s.apply_events([event("fact", "accepted"), event("fact", "unknown")]) == ERR_INVALID_DATA and s.snapshot() == before, "Invalid second event rejects entire batch")
	check(changes.is_empty() and completions.is_empty(), "Rejected batch sends no partial notifications")
	var events := [event("fact", "accepted"), event("evidence", "proof"), event("fact", "other_done")]
	check(s.apply_events(events) == OK and s.quest_status("followup") == "completed", "Batch recalculates dependent outcomes after all facts")
	check(changes.size() == 1 and changes[0] == s.snapshot() and completions == ["investigate", "followup"], "Observers receive exactly one complete state and each completed quest once")
	check(s.apply_events(events) == OK and changes.size() == 1 and completions.size() == 2, "Repeated batch is idempotent without duplicate signals")
	s.changed.disconnect(on_changed)
	s.quest_completed.disconnect(on_completed)

func run_storage_and_order(s) -> void:
	var detached: Dictionary = s.snapshot()
	detached.facts.clear()
	check(s.quest_status("investigate") == "completed" and "accepted" in s.snapshot().facts, "Snapshot cannot mutate authoritative state")
	var before: Dictionary = s.snapshot()
	check(s.apply_event(event("fact", "accepted")) == OK and s.snapshot() == before, "Repeated result is idempotent")
	check(s.apply_event(event("fact", "unknown")) == ERR_INVALID_DATA and s.snapshot() == before, "Unknown reference rejected without mutation")
	var reversed = setup_state()
	reversed.apply_event(event("fact", "other_done"))
	reversed.apply_event(event("evidence", "proof"))
	reversed.apply_event(event("fact", "accepted"))
	check(reversed.quest_status("followup") == "completed", "Branches can finish before prerequisite and converge")
	var invalid = State.new()
	check(invalid.configure({"facts": ["ok"], "evidence": [], "regions": [], "checkpoints": {}}, [quest("bad", [], ["missing"])]) == ERR_INVALID_DATA, "Definition unknown flag rejected")
	s.apply_event(event("checkpoint", "entry"))
	s.set_encounter_state({"enemy_hp": 2, "projectile_ids": ["p"]})
	s.apply_event(event("visit", "room_b"))
	check(s.restore_checkpoint() == "entry" and s.encounter_state().is_empty(), "Death clears encounter and restores checkpoint")
	check(s.quest_status("investigate") == "completed" and "proof" in s.snapshot().evidence and s.snapshot().current_region == "room_a", "Death keeps evidence/outcomes and restores region")
	DirAccess.make_dir_recursive_absolute(PATH.get_base_dir())
	for suffix in ["", ".tmp", ".bak"]:
		if FileAccess.file_exists(PATH + suffix): DirAccess.remove_absolute(PATH + suffix)
	check(s.load_from(PATH) == ERR_FILE_NOT_FOUND, "Missing save returns explicit error")
	check(s.save_to(PATH) == OK, "Save validated temporary snapshot")
	if not FileAccess.file_exists(PATH): return
	var first := FileAccess.get_file_as_string(PATH)
	s.apply_event(event("fact", "other_done"))
	check(s.save_to(PATH) == OK and FileAccess.get_file_as_string(PATH + ".bak") == first, "Second save keeps previous validated backup")
	var loaded = setup_state()
	check(loaded.load_from(PATH) == OK and loaded.snapshot() == s.snapshot(), "Real disk round trip rebuilds equivalent progress")
	var loaded_before: Dictionary = loaded.snapshot()
	var invalid_type: Dictionary = s.snapshot()
	invalid_type.facts = "accepted"
	var invalid_reference: Dictionary = s.snapshot()
	invalid_reference.evidence.append("unknown")
	var invalid_outcome: Dictionary = s.snapshot()
	invalid_outcome.outcomes.clear()
	for bad in [JSON.stringify(invalid_type), JSON.stringify(invalid_reference), JSON.stringify(invalid_outcome), "", "{", '{"version":999}', JSON.stringify({"version": 1, "facts": "bad"})]:
		var f := FileAccess.open(PATH, FileAccess.WRITE)
		f.store_string(bad)
		f.close()
		check(loaded.load_from(PATH) != OK and loaded.snapshot() == loaded_before, "Malformed save preserves in-memory progress")
		check(loaded.save_to(PATH) != OK and FileAccess.get_file_as_string(PATH) == bad and FileAccess.get_file_as_string(PATH + ".bak") == first, "Malformed destination never silently overwritten; backup retained")
	check(loaded.load_from(PATH + ".bak") == OK and loaded.quest_status("investigate") == "completed" and loaded.quest_status("followup") == "active", "Explicit backup load restores prior valid state")
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	f.store_string(first)
	f.close()
	DirAccess.remove_absolute(PATH + ".bak")
	DirAccess.make_dir_absolute(PATH + ".bak")
	check(s.save_to(PATH) != OK and FileAccess.get_file_as_string(PATH) == first, "Backup replacement failure preserves valid destination")
	DirAccess.remove_absolute(PATH + ".bak")
	for suffix in ["", ".tmp", ".bak"]:
		if FileAccess.file_exists(PATH + suffix): DirAccess.remove_absolute(PATH + suffix)
	DirAccess.remove_absolute(PATH.get_base_dir())

