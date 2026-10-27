extends SceneTree
## Continuous engine input. Reads progress; never writes transforms, health or quest state.
var app
var game
var session
var route := "lift"
var phase := 0
var frame := 0
var shots := 0
var deaths := 0
var keys := {}
var firing := false
var trace: FileAccess
var last_phase_frame := 0
var plan: Array = []
var evidence_dir := "res://artifacts"
var captured := {}
var resets := -1

func _initialize() -> void: run.call_deferred()

func key(code: Key, down: bool) -> void:
	if bool(keys.get(code,false)) == down: return
	keys[code] = down
	var e := InputEventKey.new()
	e.keycode = code
	e.physical_keycode = code
	e.pressed = down
	Input.parse_input_event(e)

func pulse(code: Key) -> void:
	key(code,frame % 20 == 0)

func fire(down: bool) -> void:
	if down == firing: return
	firing = down
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = down
	e.position = app.mouse_screen
	Input.parse_input_event(e)

func move(direction: float) -> void:
	key(KEY_A,direction < -0.1)
	key(KEY_D,direction > 0.1)

func bind() -> void:
	resets += 1
	game.player.shot_fired.connect(func(_a,_b): shots += 1)
	game.player.died.connect(func(): deaths += 1)

func advance() -> void:
	print("REBUILD REPLAY ",route," phase ",phase," ",plan[phase]," at ",game.player.position," health ",game.player.health)
	phase += 1
	last_phase_frame = frame

func button_for(id: String) -> Button:
	for b in session.ui.find_children("*","Button",true,false):
		if b.is_visible_in_tree() and not b.disabled and b.get_meta("choice_id","") == id: return b
	return null

func modal() -> bool:
	if app.chapter_staging.active() and not session.ui.is_panel_open():
		move(0)
		fire(false)
		pulse(KEY_E)
		return true
	if session.ui.is_panel_open():
		move(0)
		fire(false)
		if session.ui.panel_kind == "departure":
			key(KEY_E,false)
			for b in session.ui._departure_buttons:
				if not b.disabled:
					b.grab_focus()
					pulse(KEY_ENTER)
					break
		else:
			var later := button_for("later")
			if later != null: later.grab_focus()
			pulse(KEY_E)
		return true
	key(KEY_E,false)
	key(KEY_ENTER,false)
	return false

func run() -> void:
	if "--campaign-test" not in OS.get_cmdline_user_args(): quit(2); return
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence-dir="): evidence_dir=arg.trim_prefix("--evidence-dir=")
	DirAccess.make_dir_recursive_absolute(evidence_dir)
	if "--maintenance" in OS.get_cmdline_user_args(): route = "maintenance"
	plan = ["mara","ina","tools","vira","lift_repair","departure","celine","boss","return","mara_after"] if route == "lift" else ["mara","vira","cargo_drop","hatch","drop","maintenance_isolate","departure","celine","boss","return_hatch","return_drop","return_pump","return_west","return_up","mara_after"]
	root.size = Vector2i(1280,720)
	app = load("res://scenes/game.tscn").instantiate()
	root.add_child(app)
	game = app.stage.game
	session = game.campaign_session
	assert(not session.autosave)
	game.trial_reset.connect(bind)
	bind()
	trace = FileAccess.open(evidence_dir.path_join("replay_"+route+".jsonl"),FileAccess.WRITE)
	app.handle_flow_action("begin")
	for tick in 24000:
		frame = tick
		await physics_frame
		await process_frame
		if tick % 6 == 0:
			trace.store_line(JSON.stringify({"frame":tick,"phase":phase,"position":[game.player.position.x,game.player.position.y],"health":game.player.health,"shots":shots,"deaths":deaths,"keys":keys,"checkpoint":session.state.snapshot().checkpoint,"facts":session.state.snapshot().facts,"panel":session.ui.panel_kind,"cue":app.chapter_staging.current,"fall_recoveries":game.fall_recoveries}))
		if phase >= plan.size(): break
		if tick-last_phase_frame > 3600 or deaths > 8:
			print("REBUILD REPLAY BLOCKED ",plan[phase]," at ",game.player.position," nearest ",session.nearest()," combat ",game.combat_timer," modal ",session.ui.panel_kind," cue ",app.chapter_staging.current," pending ",app.chapter_staging.pending," paused ",game.paused," flow ",app.flow.visible)
			break
		if modal():
			var view := "modal_%s_%02d_%s" % [route,phase,session.ui.panel_kind]
			if DisplayServer.get_name() != "headless" and session.ui.is_panel_open() and not captured.has(view):
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(evidence_dir.path_join(view+".png"))
				captured[view] = true
			continue
		if DisplayServer.get_name()!="headless": await capture_route_view()
		var id: String = plan[phase]
		var at: Vector2 = game.player.position
		var target := Vector2.INF
		var interact := false
		var reached := false
		match id:
			"mara","ina","tools","vira","lift_repair","maintenance_isolate","departure","mara_after":
				var flag: String = {"mara":"met_mara","ina":"repair_explained","tools":"tools","vira":"met_vira","lift_repair":"lift_repaired","maintenance_isolate":"maintenance_open","departure":"departed","mara_after":"returned"}[id]
				reached = session.has(flag)
				for p in session.points:
					if p.id == ("mara" if id == "mara_after" else id): target = p.position
				interact = true
			"celine": target = session.story_position("elite"); reached = session.has("celine_defeated")
			"boss": target = session.story_position("boss"); reached = session.has("vira_dead")
			"hatch": target = Vector2(1200,584); reached = absf(at.x-target.x)<10
			"cargo_drop": target = Vector2(1560,656); key(KEY_S,at.x<1595); reached = at.x<1580 and at.y>600
			"drop": target = Vector2(1200,802); key(KEY_S,true); reached = at.y > 740
			"return": target = Vector2(1000,584); reached = absf(at.x-target.x)<10
			"return_hatch": target = Vector2(2590,588); reached = absf(at.x-target.x)<10
			"return_drop": target = Vector2(2590,656); key(KEY_S,true); reached = at.y>638
			"return_pump": target = Vector2(2110,835); reached = at.x<2130
			"return_west": target = Vector2(788,802); reached = at.x<796
			"return_up": target = Vector2(1250,584); reached = at.x>1235 and at.y<600
		if reached:
			key(KEY_S,false)
			advance()
			continue
		var direction := signf(target.x-at.x) if absf(target.x-at.x)>8 else 0.0
		var interaction_ready: bool = interact and session.nearest().get("id","") == ("mara" if id == "mara_after" else id)
		if interaction_ready: direction = 0
		var enemy
		var distance := 260.0
		for e in game.enemies:
			if not is_instance_valid(e) or e.state == ShieldEnemy.State.DEAD or e.target == null: continue
			var d: float = e.position.distance_to(at)
			if d < distance and absf(e.position.y-at.y)<110:
				distance = d
				enemy = e
		var aim := target-Vector2(0,24)
		if enemy != null and not session.has("vira_dead"):
			aim = enemy.position+Vector2(0,-24)
			if game.player.weapons.active_slot != 2: pulse(KEY_3)
			else: key(KEY_3,false)
			if distance < 90 and game.player.is_on_floor() and tick % 50 < 2: key(KEY_SPACE,true)
			else: key(KEY_SPACE,false)
			if distance < 58: pulse(KEY_V)
			else: key(KEY_V,false)
			if id in ["celine","boss"]:
				direction = signf(enemy.position.x-at.x) if distance>160 else (-signf(enemy.position.x-at.x) if distance<85 else 0.0)
			fire(true)
			if game.player.weapons.current().ammo == 0: pulse(KEY_R)
		else:
			fire(false)
			for code in [KEY_SPACE,KEY_V,KEY_R,KEY_3]: key(code,false)
		app.mouse_screen = app.stage.camera.unproject_position(CrimsonStage3D.to_stage(aim))/2
		move(direction)
		if interaction_ready and game.combat_timer<=0: pulse(KEY_E)
	var success: bool = session.has("returned")
	for code in keys.keys(): key(code,false)
	fire(false)
	if success and DisplayServer.get_name() != "headless":
		for spec in [[KEY_M,"map"],[KEY_J,"journal"]]:
			key(spec[0],true)
			for i in 8: await process_frame
			key(spec[0],false)
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(evidence_dir.path_join("play_"+route+"_"+spec[1]+".png"))
			key(KEY_ESCAPE,true)
			for i in 3: await process_frame
			key(KEY_ESCAPE,false)
	trace.close()
	print("REBUILD CONTINUOUS REPLAY STAGE RESULT: route=%s complete=%s frames=%d shots=%d deaths=%d resets=%d phase=%d position=%s" % [route,success,frame,shots,deaths,resets,phase,game.player.position])
	app.free()
	quit(0 if success else 1)

func capture_route_view() -> void:
	var at: Vector2 = game.player.position
	for spec in [["gate",690,730,512],["cargo",1000,1120,584],["bell",1936,2064,656],["garden",2640,2660,588],["hall",3500,3600,488]]:
		if captured.has(spec[0]) or at.x<spec[1] or at.x>spec[2] or absf(at.y-spec[3])>12: continue
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(evidence_dir.path_join("play_"+route+"_"+spec[0]+".png"))
		captured[spec[0]] = true
