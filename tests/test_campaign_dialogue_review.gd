extends SceneTree

class CaptureUI extends Control:
	var last_lines: Array = []
	var last_speaker := ""
	var last_options: Array = []
	func show_dialogue(speaker: String, lines: Array, choices: Array, _ids: Array = []) -> void:
		last_speaker = speaker
		last_lines = lines
		last_options = choices
	func show_journal(_entries: Array) -> void: pass

class ReviewSession extends "res://scripts/campaign/campaign_session.gd":
	var site := ""
	func pause() -> void: pass
	func close() -> void: modal_actions.clear()
	func refresh() -> void: pass
	func spawn_special(_archetype: String) -> void: pass
	func nearest() -> Dictionary: return {"id":site}

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var session := ReviewSession.new()
	session.autosave = false
	session.state.configure(session.Data.catalog(),session.Data.quests())
	session.ui = CaptureUI.new()
	root.add_child(session)
	root.add_child(session.ui)
	session.dialogue("vira",["mon.luggage.tag"])
	assert(session.ui.last_speaker.is_empty())
	assert(not session.ui.last_lines[0].begins_with("维拉："))
	session.event("tools","evidence")
	session.site = "ina"
	session.talk("ina")
	assert(session.ui.last_lines[0].contains(session.text("mon.ina.hello")))
	session.site = "mara"
	session.choose("tools_ina")
	assert(not session.has("tools_ina"))
	session.site = "ina"
	session.choose("tools_ina")
	assert(session.has("tools_ina"))
	session.event("met_ruka")
	session.select_side("records")
	assert(session.tracked_side_text() == session.text("mon.records.title"))
	session.event("luggage","evidence")
	session.talk("vira")
	session.talk("vira")
	assert(session.ui.last_options.is_empty())
	assert(session.has("luggage_request"))
	session.site = "luggage"
	session.dialogue("",["mon.luggage.tag"],session.luggage_choices())
	session.choose("luggage_home")
	assert(session.has("luggage_home"))
	session.talk("vira")
	assert(session.ui.last_lines[0].contains(session.text("mon.vira.returned")))
	session.event("departed")
	assert(session.record_choices().is_empty())
	assert(session.tracked_side_text().is_empty())
	var found_closed := false
	for entry in session.journal_entries():
		if entry.body == session.text("mon.closed.side.notice"): found_closed = true
	assert(found_closed)
	session.event("celine_defeated")
	session.talk("celine")
	assert(session.ui.last_lines[0].contains(session.text("mon.celine.defeated")))
	assert(not session.has("met_celine"))
	session.event("vira_dead")
	session.talk("celine")
	assert(session.ui.last_lines[0].contains(session.text("mon.celine.after.other")))
	session.ui.free()
	session.free()
	print("CAMPAIGN DIALOGUE REVIEW STAGE RESULT: PASS; no false speaker, onsite exclusive delivery, luggage request/site, side selection/freeze, Celine post-defeat knowledge")
	quit()
