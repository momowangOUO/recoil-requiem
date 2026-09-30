extends SceneTree
var checks := 0
var failures := 0
var captures := "--capture-staging" in OS.get_cmdline_user_args()
var presentation
var cue
var session
var callbacks := 0

func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func settle(frames := 3) -> void:
	for i in frames: await process_frame
func safe_floor() -> void:
	var player = session.lab.player
	player.velocity = Vector2.ZERO
	for i in 12: player.step(InputFrame.new(),1.0/60)
	session.lab.combat_timer = 0
func record(id: String) -> Dictionary:
	return {"id":id,"after":Callable(),"generation":cue._generation,"delay":0.0}

func run() -> void:
	presentation = load("res://scenes/game.tscn").instantiate()
	root.add_child(presentation)
	await settle(12)
	session = presentation.stage.game.campaign_session
	cue = presentation.chapter_staging
	session.lab.player.manual_control = true
	session.lab.player.invulnerability = 10000
	cue.enabled = true
	var player = session.lab.player
	player.velocity = Vector2(0,900)
	cue.request("arrival")
	cue._process(0.1)
	check(not cue.active() and cue.pending.size() == 1, "A falling player is never captured by an arrival cue")
	await safe_floor()
	cue._process(0.1)
	check(cue.active() and session.lab.paused, "Arrival begins at a safe standing point and pauses simulation")
	check(cue._music.stream != null and cue._music.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD,"Chapter owns an original looping music bed")
	var ammo: int = player.weapons.current().ammo
	var health: int = player.health
	for i in 12:
		cue._process(1.0/60)
		check(player.weapons.current().ammo == ammo and player.health == health,"Paused card cannot add ammo or enemy damage")
	check(cue._root.modulate.a == 0,"First scene beat stays visible before the portrait and chapter lettering enter")
	var escape := InputEventKey.new()
	escape.physical_keycode = KEY_ESCAPE
	escape.pressed = true
	check(cue.handle_input(escape),"Esc belongs to active staging")
	check(session.has("stage_arrival") and not session.lab.paused,"Skipping marks only the presentation seen and resumes")
	cue.request("arrival",func(): callbacks += 1)
	check(callbacks == 1 and cue.pending.is_empty(),"Seen cue continues once without replay")
	cue._gap = 0
	cue.request("mara",func(): callbacks += 1)
	cue.cancel()
	cue._process(5)
	check(callbacks == 1 and not cue.active(),"World reset cancels stale dialogue continuations")
	cue.request("route_lift")
	cue._process(0.1)
	check(cue.active() and not session.lab.paused,"Route result preserves player control")
	session.dialogue("",["mon.tools.inspect"])
	cue._process(0.1)
	check(not cue._root.visible and session.ui.visible,"A real dialogue takes precedence over a route card")
	session.close()
	cue.finish()
	cue._gap = 0
	cue.request("vira_after",Callable(),3)
	cue._process(2)
	check(not cue.active(),"Vira's death leaves a quiet interval before the card")
	cue.cancel()
	session.loaded_from_disk = true
	session.event("met_mara")
	cue.capture_loaded_progress()
	cue.request("mara",func(): callbacks += 1)
	check(callbacks == 2 and cue.pending.is_empty(),"An old save with an established meeting never replays that introduction")
	session.event("met_vira")
	cue.request("vira")
	check(cue.pending.size() == 1,"New meetings after loading a save still play their first introduction")
	cue.cancel()
	session.loaded_from_disk = false
	cue.capture_loaded_progress()
	cue._begin(record("celine_duel"))
	cue.window_focused = false
	var held_time: float = cue.elapsed
	cue._process(5)
	cue.finish()
	check(cue.active() and cue.elapsed == held_time and session.lab.paused,"Focus loss freezes presentation and cannot release its pause")
	check(cue._music.stream_paused,"Focus loss pauses chapter music as well as the cue")
	cue.window_focused = true
	presentation._show_flow("pause")
	cue._process(5)
	cue.finish()
	check(cue.active() and session.lab.paused,"Visible menu retains pause ownership over an unfinished cue")
	presentation._resume_play()
	check(session.lab.paused and cue.active(),"Returning from menu resumes the cue before gameplay")
	var failure_path := "user://staging_failure_%d.json" % Time.get_ticks_usec()
	session.save_path = failure_path
	session.autosave = true
	DirAccess.make_dir_absolute(failure_path+".tmp")
	cue.finish()
	check(not session.has("stage_celine_duel") and cue._seen("celine_duel"),"Presentation save failure cannot leave the duel permanently dormant")
	check(not cue._unsaved.is_empty(),"Failed presentation persistence retains a retry record")
	DirAccess.remove_absolute(failure_path+".tmp")
	check(session.save_now() == OK and session.has("stage_celine_duel") and cue._unsaved.is_empty(),"A real save retry durably includes the seen presentation")
	session.autosave = false
	session.lab.overlay.show_notice("")
	for suffix in ["", ".bak"]:
		if FileAccess.file_exists(failure_path+suffix): DirAccess.remove_absolute(failure_path+suffix)
	# Layout/asset checks use explicit staging states, not a claimed playthrough.
	for dimensions in [Vector2i(960,540),Vector2i(1280,720),Vector2i(1920,1080),Vector2i(2560,1080)]:
		root.size = dimensions
		await settle()
		for id in cue.cues:
			cue._begin(record(id))
			cue._process(1.0 if cue.cues[id].blocking else 0.3)
			await settle(2)
			check(cue._title.get_minimum_size().x <= cue._title.size.x + 1,"Title fits at %s: %s" % [dimensions,id])
			check(cue._subtitle.get_minimum_size().y <= cue._subtitle.size.y + 1,"Subtitle fits at %s: %s" % [dimensions,id])
			var full: bool = cue.cues[id].blocking
			check(cue._title.size.x <= (770 if full else 528),"Title cannot silently grow beyond authored safe width")
			check(cue._subtitle.size.y <= (80 if full else 72),"Subtitle cannot silently grow beyond authored safe height")
			check(cue._illustration.texture != null,"Cue has the corresponding task image: "+id)
			if cue.cues[id].get("portrait","") != "": check(cue._portrait.texture != null,"Cue has authored pixel portrait: "+id)
			if captures and DisplayServer.get_name() != "headless" and id in ["arrival","mara","route_lift","celine_duel","vira_after"]:
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://artifacts/staging_%s_%dx%d.png" % [id,dimensions.x,dimensions.y])
			cue.finish()
	cue.cancel()
	check(not session.has("departed") and not session.has("vira_dead"),"Rendering or skipping cards never chooses a quest branch or wins combat")
	presentation.free()
	paused = false
	print("CHAPTER STAGING STAGE RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
