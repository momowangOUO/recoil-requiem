extends Control
## Monastery-only comic cues. Story facts remain owned by CampaignSession.
const COPY_PATH := "res://data/campaign/chapter_staging.json"
const ART_PATH := "res://data/campaign/dialogue_art.json"
const FONT = preload("res://assets/fonts/unifont-18.0.01.otf")
const LEGACY_FACT := {
	"arrival":"opening_seen", "stairs":"met_mara", "first_guard":"met_mara",
	"mara":"met_mara", "vira":"met_vira", "cooperation":"celine_helped",
	"route_lift":"lift_repaired", "route_service":"maintenance_open",
	"tools":"tools", "records":"records", "luggage":"luggage",
	"departure":"departed", "celine_duel":"departed", "celine_after":"celine_defeated",
	"vira_duel":"boss_met", "vira_after":"vira_dead", "return":"returned"
}
var enabled := false
var window_focused := true
var _legacy_seen: Dictionary = {}
var _completed: Dictionary = {}
var _unsaved: Array[String] = []
var session: Node
var stage: Node3D
var cues: Dictionary = {}
var art: Dictionary = {}
var pending: Array[Dictionary] = []
var current: Dictionary = {}
var elapsed := 0.0
var _gap := 0.0
var _waiting := 0.0
var _generation := 0
var _root := Control.new()
var _plate := TextureRect.new()
var _portrait := TextureRect.new()
var _illustration := TextureRect.new()
var _inset_frame := NinePatchRect.new()
var _title := Label.new()
var _subtitle := Label.new()
var _skip := Label.new()
var _sound := AudioStreamPlayer.new()
var _music := AudioStreamPlayer.new()
var _textures: Dictionary = {}

func setup(owner_session: Node, owner_stage: Node3D) -> void:
	session = owner_session
	stage = owner_stage
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cues = JSON.parse_string(FileAccess.get_file_as_string(COPY_PATH))
	art = JSON.parse_string(FileAccess.get_file_as_string(ART_PATH))
	capture_loaded_progress()
	add_child(_root)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.size = Vector2(1280,720)
	for view in [_plate, _portrait, _illustration]:
		if view == _illustration:
			_inset_frame.texture = load("res://assets/ui/v2/runtime/dialogue_frame.png")
			_inset_frame.patch_margin_left = 38
			_inset_frame.patch_margin_right = 38
			_inset_frame.patch_margin_top = 38
			_inset_frame.patch_margin_bottom = 38
			_inset_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_root.add_child(_inset_frame)
		view.mouse_filter = Control.MOUSE_FILTER_IGNORE
		view.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_root.add_child(view)
	for label in [_title, _subtitle, _skip]:
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_font_override("font", FONT)
		label.add_theme_color_override("font_color", Color("eee4d2"))
		label.add_theme_color_override("font_outline_color", Color("1c111b"))
		label.add_theme_constant_override("outline_size", 2)
		_root.add_child(label)
	_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_skip.text = "Esc 跳过演出"
	add_child(_sound)
	add_child(_music)
	_root.hide()

func request(id: String, after: Callable = Callable(), delay := 0.0) -> void:
	if not enabled or not cues.has(id) or _seen(id):
		if after.is_valid(): after.call()
		return
	if current.get("id", "") == id: return
	for cue in pending:
		if cue.id == id: return
	pending.append({"id":id, "after":after, "generation":_generation, "delay":delay})

func _seen(id: String) -> bool:
	return session.has("stage_"+id) or _legacy_seen.has(id) or _completed.has(id)

func capture_loaded_progress() -> void:
	_legacy_seen.clear()
	_completed.clear()
	_unsaved.clear()
	if not session.loaded_from_disk: return
	for id in LEGACY_FACT:
		var completed: bool = session.has(LEGACY_FACT[id])
		if id == "tools": completed = session.has("tools_ina") or session.has("tools_mara")
		elif id == "records": completed = session.has("records_ruka") or session.has("records_mara")
		elif id == "luggage": completed = session.has("luggage_home") or session.has("luggage_cart")
		if completed: _legacy_seen[id] = true

func flush_seen() -> Error:
	if _unsaved.is_empty(): return OK
	var error: Error = session.commit_progress(_unsaved.duplicate())
	if error == OK: _unsaved.clear()
	return error

func active() -> bool:
	return not current.is_empty()

func locks_input() -> bool:
	return active() and bool(cues[current.id].get("blocking",false))

func cancel() -> void:
	_generation += 1
	pending.clear()
	current.clear()
	_root.hide()
	_sound.stop()
	_gap = 0
	_waiting = 0
	if is_instance_valid(stage):
		stage.story_focus = Vector2.INF
		stage.story_focus_weight = 0

func _safe_to_pause() -> bool:
	var player = session.lab.player
	return player.is_on_floor() and absf(player.velocity.y) < 12 and absf(player.velocity.x) < 150 and session.lab.combat_timer <= 0

func _process(delta: float) -> void:
	if not enabled or not is_instance_valid(session): return
	_fit()
	var menu_open: bool = stage.ui_host != null and stage.ui_host.flow != null and stage.ui_host.flow.visible
	_update_music(delta, menu_open)
	if not window_focused or menu_open:
		_root.hide()
		return
	if active():
		# Modal menus can suspend a nonblocking cue without losing its place.
		if not locks_input() and (session.lab.paused or session.ui.is_panel_open()):
			_root.hide()
			if session.ui.is_panel_open(): session.ui.show()
			return
		_root.show()
		if locks_input() and current.id in ["mara","vira"] and session.npc_actors.has(current.id):
			var actor = session.npc_actors[current.id]
			if actor.has_method("step_story_action"): actor.step_story_action(delta)
		elapsed += delta
		var duration := float(cues[current.id].get("duration",1.0))
		var lead := 0.75 if locks_input() else 0.0
		var blend := minf(clampf((elapsed-lead) / 0.22,0,1),clampf((duration-elapsed)/0.22,0,1))
		_root.modulate.a = blend
		_root.position.x = (get_viewport_rect().size.x-1280*_root.scale.x)*0.5 + (1.0-blend) * -48.0 * _root.scale.x
		if locks_input(): stage.story_focus_weight = minf(clampf(elapsed/0.3,0,1),clampf((duration-elapsed)/0.22,0,1))
		# One message surface at a time, including nonblocking route results.
		session.ui.hide()
		if elapsed >= duration: finish()
		return
	_gap = maxf(0.0,_gap-delta)
	if pending.is_empty() or _gap > 0 or session.lab.paused or session.ui.is_panel_open(): return
	var next: Dictionary = pending[0]
	if next.delay > 0:
		next.delay = maxf(0.0,next.delay-delta)
		return
	if bool(cues[next.id].get("blocking",false)) and not _safe_to_pause():
		_waiting += delta
		return
	pending.pop_front()
	_waiting = 0
	_begin(next)

func _begin(cue: Dictionary) -> void:
	current = cue
	elapsed = 0
	session.ui.hide()
	var data: Dictionary = cues[cue.id]
	var full := bool(data.get("blocking",false))
	if full:
		session.pause()
		session.lab.overlay.hide()
		stage.story_focus = _focus(cue.id)
	_title.text = data.title
	_subtitle.text = data.subtitle
	_portrait.texture = _art_texture("portraits",data.get("portrait",""))
	_illustration.texture = _art_texture("quests",data.get("quest","entry"))
	_illustration.material = null
	if cue.id == "first_guard":
		var shield_closeup := AtlasTexture.new()
		shield_closeup.atlas = load("res://assets/characters/aegis/aegis_bash_v3.png")
		shield_closeup.region = Rect2(810,145,186,280)
		_illustration.texture = shield_closeup
		var keying := ShaderMaterial.new()
		keying.shader = preload("res://assets/characters/requiem/chroma_key.gdshader")
		_illustration.material = keying
	var plate_path := "res://assets/ui/v2/runtime/chapter_comic_plate.png"
	var plate := AtlasTexture.new()
	plate.atlas = load(plate_path)
	plate.region = Rect2(14,125,2145,480)
	_plate.texture = plate
	_plate.position = Vector2(236,348) if full else Vector2(30,30)
	_plate.size = Vector2(1010,340) if full else Vector2(800,220)
	_portrait.position = Vector2(14,170)
	_portrait.size = Vector2(350,520)
	_portrait.visible = full and _portrait.texture != null
	_illustration.position = Vector2(980,236) if full else Vector2(70,64)
	_illustration.size = Vector2(240,146) if full else Vector2(146,132)
	_inset_frame.position = _illustration.position-Vector2(12,12)
	_inset_frame.size = _illustration.size+Vector2(24,24)
	_title.position = Vector2(384,480) if full else Vector2(242,116)
	_title.size = Vector2(770,78) if full else Vector2(528,46)
	_subtitle.position = Vector2(386,564) if full else Vector2(244,164)
	_subtitle.size = Vector2(738,80) if full else Vector2(510,60)
	_skip.position = Vector2(1060,642)
	_skip.size = Vector2(164,32)
	_skip.visible = full
	_root.modulate.a = 0
	_root.show()
	if cue.id in ["mara","vira"] and session.npc_actors.has(cue.id):
		var actor = session.npc_actors[cue.id]
		if actor.has_method("play_story_action"): actor.play_story_action("", 1.2)
	var key: String = {"arrival":"bell","stairs":"step","first_guard":"latch","mara":"paper","vira":"latch","tools":"case","records":"paper","luggage":"case","celine_duel":"bell","vira_duel":"bell","return":"paper"}.get(cue.id,"lever")
	if cue.id != "vira_after" and session.lab.audio.sounds.has(key):
		_sound.stream = session.lab.audio.sounds[key]
		_sound.volume_db = -24
		_sound.play()
	_fit()

func _update_music(delta: float, menu_open: bool) -> void:
	if _music.stream == null:
		_music.stream = session.lab.audio.chapter_bed()
		_music.volume_db = -50
		_music.play()
	_music.stream_paused = not window_focused or menu_open
	if _music.stream_paused: return
	var volume := -39.0
	if session.lab.combat_timer > 0: volume = -29.0
	if session.ui.is_panel_open() or locks_input(): volume = -44.0
	if session.has("vira_dead"): volume = -80.0 # No victory music over the body or return.
	_music.volume_db = move_toward(_music.volume_db, volume, delta * 18.0)

func _focus(id: String) -> Vector2:
	var player: Vector2 = session.lab.player.position
	var focus := player + Vector2(48,-64)
	var npc := str(cues[id].get("portrait",""))
	if session.npc_actors.has(npc): focus = session.npc_actors[npc].position + Vector2(0,-42)
	elif id in ["vira_duel","celine_duel"]: focus = session.story_position("boss" if id == "vira_duel" else "elite") + Vector2(0,-42)
	return player + (focus-player).clamp(Vector2(-80,-110),Vector2(80,-24))

func _fit() -> void:
	var viewport := get_viewport_rect().size
	var factor := minf(viewport.x/1280.0,viewport.y/720.0)
	_root.scale = Vector2.ONE * factor
	_root.position.y = (viewport.y-720.0*factor)*0.5
	var full := locks_input()
	# The project canvas is 320x180 even on a 1280x720 window. Compensate
	# small physical windows only; using canvas factor here quadruples glyphs.
	var window_ratio := minf(get_window().size.x/1280.0,get_window().size.y/720.0)
	var correction := maxf(1.0,1.0/maxf(window_ratio,0.1))
	_title.add_theme_font_size_override("font_size",roundi((50 if full else 30)*correction))
	_subtitle.add_theme_font_size_override("font_size",roundi((28 if full else 24)*correction))
	_skip.add_theme_font_size_override("font_size",roundi(18*correction))

func _art_texture(group: String, id: String) -> Texture2D:
	if not art.get(group,{}).has(id): return null
	var key := group+id
	if _textures.has(key): return _textures[key]
	var spec: Dictionary = art[group][id]
	var tex := AtlasTexture.new()
	tex.atlas = load(spec.texture)
	tex.region = Rect2(spec.rect[0],spec.rect[1],spec.rect[2],spec.rect[3])
	_textures[key] = tex
	return tex

func finish() -> void:
	if not active(): return
	if not window_focused or (stage.ui_host != null and stage.ui_host.flow != null and stage.ui_host.flow.visible): return
	var cue := current
	var was_locked := locks_input()
	if cue.id in ["mara","vira"] and session.npc_actors.has(cue.id):
		session.npc_actors[cue.id].step_story_action(float(cues[cue.id].duration))
	current = {}
	_root.hide()
	stage.story_focus = Vector2.INF
	stage.story_focus_weight = 0
	_completed[cue.id] = true
	if session.event("stage_"+cue.id) != OK and not ("stage_"+cue.id) in _unsaved:
		_unsaved.append("stage_"+cue.id)
	if was_locked:
		session.lab.overlay.show()
		session.lab.resume_trial()
		session.ui._external_pause_hidden = false
	session.ui.show()
	_gap = 0.8
	if cue.generation == _generation and cue.after.is_valid(): cue.after.call()

func handle_input(event: InputEvent) -> bool:
	if not locks_input(): return false
	if not window_focused: return true
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE:
		finish()
	return true
