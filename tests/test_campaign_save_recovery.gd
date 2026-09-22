extends SceneTree

const State = preload("res://scripts/campaign/campaign_state.gd")
const Session = preload("res://scripts/campaign/campaign_session.gd")
const Data = preload("res://scripts/campaign/monastery_data.gd")
var checks := 0
var failures := 0
var fixture := "user://campaign_save_recovery_%s" % Time.get_ticks_usec()

class NoticeSink extends RefCounted:
	var notices: Array[String] = []
	func show_notice(message: String) -> void:
		notices.append(message)

class OwnerStub extends Node:
	var overlay := NoticeSink.new()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func store():
	var result = State.new()
	result.configure(Data.catalog(), Data.quests())
	return result

func fact(s, id: String) -> void:
	s.apply_event({"event_id":id, "source_id":"monastery", "id":id, "result_id":id, "kind":"fact"})

func write(path: String, contents: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	check(file != null, "Fixture opens only beneath its isolated directory")
	if file != null:
		file.store_string(contents)
		file.close()

func make_session(path: String):
	var result = Session.new()
	result.lab = OwnerStub.new()
	result.state.configure(Data.catalog(), Data.quests())
	result.save_path = path
	return result

func free_session(s) -> void:
	s.lab.free()
	s.free()

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(fixture)
	var probe = store()
	check(probe.has_method("load_or_recover"), "State exposes safe primary/backup recovery")
	var session_probe = Session.new()
	var session_api: bool = session_probe.has_method("load_save") and session_probe.has_method("save_now")
	check(session_api, "Session exposes retryable save status instead of warning-only failures")
	session_probe.free()
	if probe.has_method("load_or_recover"):
		run_recovery()
	if session_api:
		run_session()
		run_transaction_recovery()
		run_copy_review()
	# Only this invocation's dedicated fixture tree is removed.
	clean_fixture(fixture)
	print("CAMPAIGN SAVE RECOVERY STAGE RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func run_recovery() -> void:
	var path := fixture + "/recover.json"
	var original = store()
	fact(original, "met_mara")
	check(original.save_to(path) == OK, "Write first valid snapshot")
	var backup_text := FileAccess.get_file_as_string(path)
	fact(original, "met_vira")
	check(original.save_to(path) == OK, "Write newer snapshot with backup")
	write(path, "{broken original")
	var recovered = store()
	var result: Dictionary = recovered.load_or_recover(path)
	check(result.error == OK and result.recovered, "Corrupt main recovers validated backup")
	check(recovered.has_flag("met_mara") and not recovered.has_flag("met_vira"), "Recovered progress is exactly the backup")
	check(not result.preserved_path.is_empty() and FileAccess.get_file_as_string(result.preserved_path) == "{broken original", "Corrupt original is preserved byte-for-byte")
	check(FileAccess.get_file_as_string(path + ".bak") == backup_text, "Recovery leaves backup untouched")
	fact(recovered, "met_ina")
	check(recovered.save_to(path) == OK, "Recovered slot can save subsequent progress")
	var loaded = store()
	check(loaded.load_from(path) == OK and loaded.has_flag("met_ina"), "Subsequent progress survives a fresh load")
	DirAccess.remove_absolute(path)
	result = loaded.load_or_recover(path)
	check(result.error == OK and result.recovered and result.preserved_path.is_empty(), "Missing main restores interrupted replacement from backup")
	check(loaded.save_to(path) == OK, "Missing-main recovery also permits later saves")
	write(path, "second damaged original")
	var repeated: Dictionary = loaded.load_or_recover(path)
	check(repeated.error == OK and repeated.preserved_path != result.preserved_path, "A later recovery chooses a new archive name")
	check(FileAccess.get_file_as_string(path + ".damaged") == "{broken original" and FileAccess.get_file_as_string(repeated.preserved_path) == "second damaged original", "Repeated recovery never overwrites earlier damaged originals")
	var before: Dictionary = loaded.snapshot()
	write(path, "bad main")
	write(path + ".bak", "bad backup")
	result = loaded.load_or_recover(path)
	check(result.error != OK and loaded.snapshot() == before, "Two invalid files do not replace in-memory progress")
	check(FileAccess.get_file_as_string(path) == "bad main" and FileAccess.get_file_as_string(path + ".bak") == "bad backup", "Failed recovery preserves both originals")
	var valid_path := fixture + "/valid.json"
	check(original.save_to(valid_path) == OK, "Prepare valid main")
	write(valid_path + ".bak", "bad old backup")
	result = loaded.load_or_recover(valid_path)
	check(result.error == OK and not result.recovered and loaded.snapshot() == original.snapshot(), "Valid main always wins over backup")
	result = loaded.load_or_recover(fixture + "/new.json")
	check(result.error == ERR_FILE_NOT_FOUND and loaded.snapshot() == original.snapshot(), "Truly empty slot is distinguishable from a damaged save")
	var blocked := fixture + "/blocked.json"
	DirAccess.make_dir_absolute(blocked)
	write(blocked + "/keep.txt", "do not remove")
	write(blocked + ".bak", backup_text)
	before = loaded.snapshot()
	result = loaded.load_or_recover(blocked)
	check(result.error != OK and loaded.snapshot() == before, "Failed promotion never replaces memory with backup progress")
	check(FileAccess.get_file_as_string(blocked + "/keep.txt") == "do not remove" and FileAccess.get_file_as_string(blocked + ".bak") == backup_text, "Failed promotion leaves conflicting path and backup untouched")

func run_session() -> void:
	var path := fixture + "/session.json"
	var session = make_session(path)
	check(session.load_save() == OK and session.save_status.code == "ready", "Fresh game is save-ready without warnings")
	check(session.lab.overlay.notices.is_empty(), "Fresh game shows no error notice")
	fact(session.state, "met_mara")
	check(session.save_now() == OK, "Session can save a fresh game")
	DirAccess.make_dir_absolute(path + ".tmp")
	check(session.save_now() != OK and session.save_status.code == "write_failed", "Real filesystem write failure becomes visible persistent status")
	check(not session.lab.overlay.notices.is_empty(), "Write failure immediately reaches player notice")
	var count: int = session.lab.overlay.notices.size()
	session._process(9.0)
	check(session.lab.overlay.notices.size() > count, "Unresolved failure is rediscoverable after notice timeout")
	DirAccess.remove_absolute(path + ".tmp")
	check(session.save_now() == OK and session.save_status.code == "ready", "Explicit save retry clears failure only after successful write")
	free_session(session)
	session = make_session(path)
	check(session.load_save() == OK and session.state.has_flag("met_mara") and session.lab.overlay.notices.is_empty(), "Normal load is quiet and restores progress")
	write(path, "unreadable")
	check(session.load_save() == OK and session.save_status.code == "recovered" and session.autosave, "Session recovers backup and keeps autosave enabled")
	check(FileAccess.file_exists(session.save_status.preserved_path), "Session exposes preserved original path")
	check(session.save_now() == OK and session.save_status.code == "recovered", "Recovery information remains available after autosave")
	write(path, "unreadable again")
	write(path + ".bak", "also unreadable")
	check(session.load_save() != OK and not session.autosave and session.save_status.code == "load_failed", "Unrecoverable load visibly blocks accidental overwrite")
	check(session.save_now() != OK and FileAccess.get_file_as_string(path) == "unreadable again", "Save retry cannot overwrite rejected originals")
	free_session(session)

func run_transaction_recovery() -> void:
	var consequences := {"vira_dead": "gate_return", "tools_ina": "gate_west", "tools_mara": "gate_entry", "records_ruka": "gate_east", "records_mara": "gate_east"}
	for trigger in consequences:
		var gate: String = consequences[trigger]
		var path: String = fixture + "/transaction_" + trigger + ".json"
		var session = make_session(path)
		check(session.save_now() == OK, "Prepare pre-transaction snapshot: " + trigger)
		if trigger == "vira_dead":
			session.groups["boss"] = []
			session.enemy_down("boss")
		else: session.event(trigger)
		var disk = store()
		check(disk.load_from(path) == OK and disk.has_flag(trigger) and disk.has_flag(gate), "Transaction persists fact and its exact consequence together: " + trigger)
		var backup = store()
		check(backup.load_from(path + ".bak") == OK and not backup.has_flag(trigger) and not backup.has_flag(gate), "Backup never contains an intermediate transaction: " + trigger)
		# Manufacture a version-1 backup from before the atomic transaction fix.
		var legacy = store()
		fact(legacy, trigger)
		write(path + ".bak", JSON.stringify(legacy.snapshot()))
		write(path, "damaged transaction main")
		check(session.load_save() == OK and session.has(trigger) and session.has(gate), "Old intermediate backup restores its already-earned consequence: " + trigger)
		check(disk.load_from(path) == OK and disk.has_flag(gate), "Recovery repair is durable: " + trigger)
		check(FileAccess.get_file_as_string(session.save_status.preserved_path) == "damaged transaction main", "Repair preserves damaged original: " + trigger)
		for other_gate in ["gate_return", "gate_west", "gate_entry", "gate_east"]:
			if other_gate != gate: check(not session.has(other_gate), "Recovery does not unlock unrelated gate: " + other_gate)
		free_session(session)
	var path := fixture + "/repair_write_failure.json"
	var legacy = store()
	fact(legacy, "vira_dead")
	write(path + ".bak", JSON.stringify(legacy.snapshot()))
	write(path, "preserve failed repair original")
	DirAccess.make_dir_absolute(path + ".tmp")
	var session = make_session(path)
	check(session.load_save() == OK and session.has("gate_return"), "Successful read retains coherent playable state when repair write fails")
	check(session.save_status.code == "write_failed" and not session.lab.overlay.notices.is_empty(), "Repair write failure remains visible and retryable")
	check(FileAccess.get_file_as_string(path + ".damaged") == "preserve failed repair original", "Failed repair preserves damaged original")
	DirAccess.remove_absolute(path + ".tmp")
	check(session.save_now() == OK, "Repair write failure can be retried")
	var disk = store()
	check(disk.load_from(path) == OK and disk.has_flag("gate_return"), "Retried repair survives fresh load")
	free_session(session)
	var normal_path := fixture + "/legacy_main.json"
	check(legacy.save_to(normal_path) == OK, "Prepare valid legacy main")
	session = make_session(normal_path)
	check(session.load_save() == OK and session.has("gate_return") and session.lab.overlay.notices.is_empty(), "Valid legacy main receives same repair without warning")
	check(disk.load_from(normal_path) == OK and disk.has_flag("gate_return"), "Normal legacy-main repair is durable")
	free_session(session)

func run_copy_review() -> void:
	var reviewed := {}
	for line in FileAccess.get_file_as_string("res://game-text/save-status-review.md").split("\n"):
		if not line.begins_with("| "): continue
		var cells := line.split("|")
		if cells.size() >= 5 and Session.SAVE_COPY.has(cells[1].strip_edges()):
			reviewed[cells[1].strip_edges()] = cells[3].strip_edges()
	check(reviewed == Session.SAVE_COPY, "Decoded runtime save messages exactly match reviewed standalone draft")

func clean_fixture(path: String) -> void:
	assert(path == fixture or path.begins_with(fixture + "/"))
	for item in DirAccess.get_files_at(path): DirAccess.remove_absolute(path + "/" + item)
	for item in DirAccess.get_directories_at(path): clean_fixture(path + "/" + item)
	DirAccess.remove_absolute(path)
