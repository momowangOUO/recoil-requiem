extends "res://tests/test_background_clarity.gd"
## File-based compatibility fixture, never a substitute for continuous playthrough.
func run() -> void:
	if "--campaign-test" not in OS.get_cmdline_user_args(): quit(2); return
	var game = load("res://scenes/crimson_slice.tscn").instantiate()
	game.campaign_enabled = true
	root.add_child(game)
	game.set_physics_process(false)
	var session = game.campaign_session
	var path := "user://rebuild_checkpoint_%s.json" % Time.get_ticks_usec()
	session.save_path = path
	for version in [1,2]:
		for index in range(1,17):
			var store = session.Store.new()
			store.configure(session.Data.catalog(),session.Data.quests())
			var events: Array = []
			for flag in ["met_mara","met_vira","lift_repaired","maintenance_open"]:
				events.append({"kind":"fact","id":flag,"event_id":flag,"source_id":"fixture","result_id":flag})
			for id in ["tools","records"]:
				events.append({"kind":"evidence","id":id,"event_id":id,"source_id":"fixture","result_id":id})
			var cp := "cp_mon_%02d" % index
			events.append({"kind":"checkpoint","id":cp,"event_id":cp,"source_id":"fixture","result_id":cp})
			check(store.apply_events(events)==OK,"Valid checkpoint fixture: "+cp)
			var original: Dictionary = store.snapshot()
			var old := original.duplicate(true)
			old.version = version
			if version==1: old.erase("selected_route")
			var f := FileAccess.open(path,FileAccess.WRITE)
			f.store_string(JSON.stringify(old))
			f.close()
			check(session.load_save()==OK,"Load v%d checkpoint %s" % [version,cp])
			game.reset_trial(3)
			game.player.manual_control = true
			for enemy in game.enemies: enemy.set_physics_process(false)
			for field in ["facts","evidence","outcomes","results","checkpoint"]:
				check(session.state.snapshot()[field]==original[field],"Map rebuild preserves "+field)
			var target := Vector2.INF
			for marker in game.environment.checkpoints:
				if marker.id==cp: target=marker.position
			check(game.player.position==target,"Saved ID resolves new authored checkpoint")
			for tick in 15:
				await physics_frame
				game.player.step(InputFrame.new(),1.0/60)
			check(game.player.is_on_floor() and game.player.position.distance_to(target)<8,"Reloaded player settles safely")
	session.autosave = false
	for shortcut in game.environment.shortcut_points:
		check(session.event(shortcut.gate_id)==OK,"Shortcut unlock fact remains valid")
		for ends in [[shortcut.from,shortcut.to],[shortcut.to,shortcut.from]]:
			for home in [false,true]:
				game.environment.set_luggage_home(home)
				session.close()
				game.player.position = ends[0]
				game.player.velocity = Vector2.ZERO
				for tick in 15:
					await physics_frame
					game.player.step(InputFrame.new(),1.0/60)
				check(game.player.is_on_floor() and game.player.position.distance_to(ends[0])<8,"Shortcut end is safe under either luggage outcome")
				check(session.nearest().get("id","")==shortcut.gate_id+"_travel","Shortcut prompt is not shadowed by another interaction")
				var before: Dictionary = session.state.snapshot()
				var e := InputEventKey.new()
				e.physical_keycode = KEY_E
				e.pressed = true
				session.handle_input(e)
				check(game.player.position==ends[1],"Actual E handler travels to paired authored end")
				check(session.state.snapshot()==before,"Shortcut travel cannot manufacture quest progress")
	game.free()
	for suffix in ["",".bak"]:
		if FileAccess.file_exists(path+suffix): DirAccess.remove_absolute(path+suffix)
	print("MONASTERY SAVE REBUILD STAGE RESULT: %d checks, %d failures; 16 IDs across v1/v2 files" % [checks,failures])
	quit(1 if failures else 0)
