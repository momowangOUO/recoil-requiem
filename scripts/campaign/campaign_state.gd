extends RefCounted
## Pure persistent state. No scene, UI, reward spawning or automatic disk writes.
signal changed
signal quest_completed(quest_id: String)
const Quest = preload("res://scripts/campaign/quest_definition.gd")
const SAVE_VERSION := 1
var _catalog: Dictionary = {}
var _quests: Array = []
var _data: Dictionary = {}
var _encounter: Dictionary = {}

func configure(catalog: Dictionary, quests: Array) -> Error:
	if not _catalog.is_empty(): return ERR_ALREADY_IN_USE
	for key in ["facts", "evidence", "regions"]:
		if not catalog.get(key) is Array or not _valid_ids(catalog[key]): return ERR_INVALID_DATA
	if not catalog.get("checkpoints") is Dictionary: return ERR_INVALID_DATA
	for id in catalog.checkpoints:
		if not _valid_id(id) or not catalog.checkpoints[id] in catalog.regions: return ERR_INVALID_DATA
	var ids: Array = []
	var known: Array = catalog.facts + catalog.evidence
	if not _valid_ids(known): return ERR_INVALID_DATA
	for q in quests:
		if not q is Quest or not _valid_id(q.quest_id) or q.quest_id in ids: return ERR_INVALID_DATA
		ids.append(q.quest_id)
		if q.objective_flags.is_empty(): return ERR_INVALID_DATA
		for flag in q.prerequisite_flags + q.objective_flags:
			if not flag in known: return ERR_INVALID_DATA
		if q.completed_flag != "" and not q.completed_flag in catalog.facts: return ERR_INVALID_DATA
	_catalog = catalog.duplicate(true)
	for q in quests: _quests.append(q.duplicate(true))
	_data = {"version": SAVE_VERSION, "facts": [], "evidence": [], "outcomes": [], "visited_regions": [], "results": [], "current_region": "", "checkpoint": ""}
	return OK

func _valid_id(value: Variant) -> bool:
	if not value is String or value.is_empty(): return false
	for ch in value:
		if not ch in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_.-": return false
	return true

func has_flag(id: String) -> bool:
	return id in _data.get("facts", []) or id in _data.get("evidence", [])

func _valid_ids(values: Array) -> bool:
	var seen: Dictionary = {}
	for value in values:
		if not _valid_id(value) or seen.has(value): return false
		seen[value] = true
	return true

func apply_event(event: Dictionary) -> Error:
	if _catalog.is_empty(): return ERR_UNCONFIGURED
	for key in ["event_id", "source_id", "id", "result_id"]:
		if not _valid_id(event.get(key)): return ERR_INVALID_DATA
	var kind: Variant = event.get("kind")
	var registry := {"fact": "facts", "evidence": "evidence", "visit": "regions", "checkpoint": "checkpoints"}
	if not kind is String or not registry.has(kind): return ERR_INVALID_DATA
	if not event.id in _catalog[registry[kind]]: return ERR_INVALID_DATA
	if event.result_id in _data.results: return OK
	_data.results.append(event.result_id)
	match kind:
		"fact", "evidence":
			var key: String = registry[kind]
			if not event.id in _data[key]: _data[key].append(event.id)
		"visit":
			_data.current_region = event.id
			if not event.id in _data.visited_regions: _data.visited_regions.append(event.id)
		"checkpoint":
			_data.checkpoint = event.id
			_data.current_region = _catalog.checkpoints[event.id]
			if not _data.current_region in _data.visited_regions: _data.visited_regions.append(_data.current_region)
	var completed := _recalculate(_data)
	changed.emit()
	for id in completed: quest_completed.emit(id)
	return OK

func _has_all(data: Dictionary, flags: PackedStringArray) -> bool:
	for flag in flags:
		if not flag in data.facts and not flag in data.evidence: return false
	return true

func _recalculate(data: Dictionary) -> Array:
	var completed: Array = []
	# Monotonic facts converge in at most one pass per quest, regardless of order.
	for _pass in _quests.size():
		var advanced := false
		for q in _quests:
			if q.quest_id in data.outcomes: continue
			if _has_all(data, q.prerequisite_flags) and _has_all(data, q.objective_flags):
				data.outcomes.append(q.quest_id)
				if q.completed_flag != "" and not q.completed_flag in data.facts: data.facts.append(q.completed_flag)
				completed.append(q.quest_id)
				advanced = true
		if not advanced: break
	return completed

func quest_status(id: String) -> String:
	if _data.is_empty(): return "unknown"
	for q in _quests:
		if q.quest_id == id:
			if id in _data.outcomes: return "completed"
			return "active" if _has_all(_data, q.prerequisite_flags) else "locked"
	return "unknown"

func snapshot() -> Dictionary:
	return _data.duplicate(true)

func set_encounter_state(state: Dictionary) -> void:
	_encounter = state.duplicate(true)

func encounter_state() -> Dictionary:
	return _encounter.duplicate(true)

func restore_checkpoint() -> String:
	_encounter.clear()
	if _data.get("checkpoint", "") != "":
		_data.current_region = _catalog.checkpoints[_data.checkpoint]
	changed.emit()
	return _data.get("checkpoint", "")


func _valid_path(path: String) -> bool:
	return path.begins_with("user://") and path.length() > 7 and not ".." in path and not "\\" in path and not path.ends_with("/")

func _validate(data: Variant) -> Error:
	if not data is Dictionary: return ERR_INVALID_DATA
	if not data.get("version") is float and not data.get("version") is int: return ERR_INVALID_DATA
	if data.version != SAVE_VERSION: return ERR_FILE_UNRECOGNIZED
	if data.size() != 8: return ERR_INVALID_DATA
	var quest_ids: Array = []
	for q in _quests: quest_ids.append(q.quest_id)
	var registries := {"facts": _catalog.facts, "evidence": _catalog.evidence, "outcomes": quest_ids, "visited_regions": _catalog.regions, "results": null}
	for key in registries:
		if not data.get(key) is Array or not _valid_ids(data[key]): return ERR_INVALID_DATA
		if registries[key] != null:
			for id in data[key]:
				if not id in registries[key]: return ERR_INVALID_DATA
	if not data.get("current_region") is String or not data.get("checkpoint") is String: return ERR_INVALID_DATA
	if data.current_region != "" and not data.current_region in data.visited_regions: return ERR_INVALID_DATA
	if data.checkpoint != "":
		if not data.checkpoint in _catalog.checkpoints or not _catalog.checkpoints[data.checkpoint] in data.visited_regions: return ERR_INVALID_DATA
	for q in _quests:
		var complete: bool = _has_all(data, q.prerequisite_flags) and _has_all(data, q.objective_flags)
		if (q.quest_id in data.outcomes) != complete: return ERR_INVALID_DATA
		if complete and q.completed_flag != "" and not q.completed_flag in data.facts: return ERR_INVALID_DATA
	return OK

func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {"error": ERR_FILE_NOT_FOUND}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null: return {"error": FileAccess.get_open_error()}
	var json := JSON.new()
	var error := json.parse(file.get_as_text())
	file.close()
	if error != OK: return {"error": ERR_PARSE_ERROR}
	error = _validate(json.data)
	return {"error": error, "data": json.data}

func save_to(path: String) -> Error:
	if _catalog.is_empty(): return ERR_UNCONFIGURED
	if not _valid_path(path) or path.ends_with(".tmp") or path.ends_with(".bak"): return ERR_INVALID_PARAMETER
	var error := _validate(_data)
	if error != OK: return error
	var existed := FileAccess.file_exists(path)
	if existed:
		error = _read(path).error
		if error != OK: return error
	elif FileAccess.file_exists(path + ".bak"):
		# An interrupted replacement requires explicit recovery, not a new-game overwrite.
		return ERR_ALREADY_EXISTS
	error = DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if error != OK: return error
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null: return FileAccess.get_open_error()
	file.store_string(JSON.stringify(_data))
	file.flush()
	error = file.get_error()
	file.close()
	if error == OK: error = _read(temporary).error
	if error != OK:
		DirAccess.remove_absolute(temporary)
		return error
	var backup := path + ".bak"
	if existed:
		if FileAccess.file_exists(backup):
			error = DirAccess.remove_absolute(backup)
			if error != OK: return error
		error = DirAccess.rename_absolute(path, backup)
		if error != OK: return error
	error = DirAccess.rename_absolute(temporary, path)
	if error != OK and existed:
		var rollback := DirAccess.rename_absolute(backup, path)
		if rollback != OK: return rollback
	return error

func load_from(path: String) -> Error:
	if _catalog.is_empty(): return ERR_UNCONFIGURED
	if not _valid_path(path): return ERR_INVALID_PARAMETER
	var result := _read(path)
	if result.error != OK: return result.error
	_data = result.data.duplicate(true)
	_data.version = SAVE_VERSION
	_recalculate(_data)
	_encounter.clear()
	changed.emit()
	return OK
