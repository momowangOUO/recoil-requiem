extends SceneTree
## Native UI exercised through the main presentation and campaign map input.
var checks := 0
var failures := 0

func _initialize() -> void: run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func run() -> void:
	if not "--campaign-test" in OS.get_cmdline_user_args():
		push_error("Requires --campaign-test; never load or write the user's save")
		quit(1)
		return
	root.content_scale_size = Vector2i(320,180)
	var app = load("res://scenes/game.tscn").instantiate()
	root.add_child(app)
	var game = app.stage.game
	var session = game.campaign_session
	var ui = session.ui
	game.player.manual_control = true
	check(not session.autosave, "Test session cannot access the user save")
	check(game.environment.space_bounds.size() == 16, "All sixteen actual map regions loaded")
	var actual_segments := {}
	for module in game.environment.modules:
		if not module.get_meta("route_surface",false) or str(module.name).begins_with("Luggage"): continue
		actual_segments[str(module.name)] = [module.position, module.position+Vector2(module.width,0)]
	for stair in game.environment.stairs:
		if str(stair.name).begins_with("Luggage"): continue
		actual_segments[str(stair.name)] = [stair.position, stair.position+stair.end_offset]
	check(ui._map_source.segments.size() == actual_segments.size(), "Map includes exactly the authored static walkable modules")
	for segment in ui._map_source.segments:
		check(actual_segments.has(str(segment.id)), "Map segment exists in runtime scene: "+str(segment.id))
		if actual_segments.has(str(segment.id)):
			var expected: Array = actual_segments[str(segment.id)]
			check(expected[0].distance_to(Vector2(segment.start[0],segment.start[1])) < 0.01 and expected[1].distance_to(Vector2(segment.end[0],segment.end[1])) < 0.01, "Map endpoints match runtime collision: "+str(segment.id))

	check(ui._map_art_texture != null, "Generated architectural atlas is loaded into the actual map")
	check(ui._map_art_source.get("layers", []).size() >= 8, "Generated architectural layers include the arrival station")
	var cut: Array = ui._subtract_map_rect(Rect2(0, 0, 100, 100), Rect2(25, 25, 50, 50))
	var cut_area := 0.0
	for piece in cut: cut_area += piece.get_area()
	check(cut.size() == 4 and is_equal_approx(cut_area, 7500), "Exploration union subtracts shared areas without losing known margins")
	root.size = Vector2i(1280,720)
	session.event("mon_01", "visit")
	var first_map_key := InputEventKey.new()
	first_map_key.physical_keycode = KEY_M
	first_map_key.pressed = true
	session.handle_input(first_map_key)
	for frame in 4: await process_frame
	var initial_art: Array = ui._map_art_pieces()
	check(not initial_art.is_empty(), "First map opening renders the discovered station, not a bare line diagram")
	for piece in initial_art:
		check(piece.space_id == "mon_01", "First map opening does not expose other buildings")
		check(piece.source_rect.has_area(), "Station uses an actual crop of the accepted architecture")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/image_map_ui_1280_initial.png")
	session.close()
	# Snapshot authored pressure before simulation moves enemies.
	for npc in game.environment.npc_points:
		var nearest := INF
		var enemy_id := ""
		for marker in game.environment.enemy_spawns:
			var distance: float = npc.position.distance_to(marker.position)
			if distance < nearest:
				nearest = distance
				enemy_id = "%s/group%s/%s" % [marker.name, marker.get_meta("encounter_id", 1), marker.get_meta("enemy_archetype", "shield")]
		print("NPC PRESSURE %s at %s nearest %s %.1fpx" % [npc.id, npc.position, enemy_id, nearest])
	for dimensions in [Vector2i(960,540), Vector2i(1280,720), Vector2i(1920,1080), Vector2i(2560,1080)]:
		root.size = dimensions
		for explored in [3,16]:
			for i in range(1, explored + 1): session.event("mon_%02d" % i, "visit")
			for opened in [false,true]:
				var original_gates: Dictionary = game.environment.gate_states.duplicate()
				for id in game.environment.gate_states: game.environment.gate_states[id] = opened
				var before: Dictionary = session.state.snapshot().duplicate(true)
				var key := InputEventKey.new()
				key.physical_keycode = KEY_M
				key.pressed = true
				session.handle_input(key)
				for frame in 4: await process_frame
				check(ui.is_panel_open(), "Map input opens actual UI")
				check(Rect2(Vector2.ZERO, Vector2(dimensions)).encloses(ui.panel.get_global_rect()), "Panel fits native window")
				check(ui._map_data.spaces.size() == 16, "UI receives actual region geometry")
				check(ui._map_data.visited.size() == explored, "Map respects explored region count")
				check(ui._map.size.x >= 790 and ui._map.size.y >= 400, "Architecture has a large canvas without a redundant toolbar row")
				var art_pieces: Array = ui._map_art_pieces()
				check(not art_pieces.is_empty(), "Explored map draws architectural imagery, not only navigation lines")
				for piece in art_pieces:
					check(piece.space_id in ui._map_data.visited, "Unexplored building is never disclosed")
					check(Rect2(Vector2.ZERO, piece.texture.get_size()).grow(0.01).encloses(piece.source_rect), "Architectural crop stays inside its generated texture")
					var remaining: Array = [piece.world_rect]
					for known in ui._map_data.visited:
						var uncovered: Array = []
						for rect in remaining: uncovered.append_array(ui._subtract_map_rect(rect, ui._map_data.spaces[known].rect))
						remaining = uncovered
					check(remaining.is_empty(), "Every building fragment is inside the explored-region union")
					for other in art_pieces:
						if piece != other and piece.id == other.id:
							check(not piece.world_rect.intersects(other.world_rect), "Overlapping explored regions cannot double-paint a building")
				for layer in ui._map_art_source.get("layers", []):
					var fitted: Rect2 = ui._map_art_rect(layer)
					var raw: Array = layer.world_rect
					var bounds := Rect2(float(raw[0]), float(raw[1]), float(raw[2]), float(raw[3]))
					var cell_size: Vector2 = ui._map_art_source_rect(layer).size
					check(bounds.grow(0.01).encloses(fitted) and absf(fitted.end.y - bounds.end.y) < 0.01, "Generated elevation fits its world footprint and rests on its authored base")
					check(absf(fitted.size.x / fitted.size.y - cell_size.x / cell_size.y) < 0.001, "Generated architecture keeps its original aspect ratio")
				check(ui._map_data.player == game.player.position, "Player marker uses current position")
				check(ui._map_data.checkpoints == game.environment.checkpoints, "Checkpoint coordinates match authored map")
				var after: Dictionary = session.state.snapshot()
				check(session.has("tutorial_map"), "Viewing the map records the completed map lesson")
				if not "tutorial_map" in before.facts:
					after.facts.erase("tutorial_map")
					after.results.erase("tutorial_map")
				check(after == before, "Viewing map leaves narrative campaign state unchanged")
				check(ui._map_source.get("segments", []).size() == actual_segments.size(), "Map retains all authored floor/stair segments")
				check(ui._map_source.get("landmarks", []).size() == 7, "Map uses seven authored imagegen landmarks")
				check(ui._map_source.get("label_anchors", {}).size() == 16, "Every room number has an authored anchor on a real route")
				if dimensions.x == 1280 and explored == 3 and not opened:
					for id in ui._map_source.label_anchors:
						var raw: Array = ui._map_source.label_anchors[id]
						var anchor := Vector2(raw[0],raw[1])
						check(ui._map_data.spaces[id].rect.grow(8).has_point(anchor), "Map number %s is in its actual region" % id)
						var on_deck := false
						for segment in ui._map_source.segments:
							var a := Vector2(segment.start[0],segment.start[1])
							var b := Vector2(segment.end[0],segment.end[1])
							if Geometry2D.get_closest_point_to_segment(anchor,a,b).distance_to(anchor)<1: on_deck = true; break
						check(on_deck, "Map number %s is on an authored walking deck" % id)
				check(ui._map_data.get("shortcuts", []).size() == 4, "Map receives the four real freight shortcut endpoint pairs")
				if ui.has_method("_visible_route_pieces"):
					var deck: Array = actual_segments.F01_east
					var joined: Array = ui.call("_visible_route_pieces", deck[0], deck[1], "F01_east")
					check(joined.size() == 1 and joined[0][0].distance_to(deck[0]) < 1 and joined[0][1].distance_to(deck[1]) < 1, "Visited overlapping regions draw one continuous road, not duplicate strips")
					if explored == 16:
						for segment in ui._map_source.segments:
							var route: Array = ui.call("_visible_route_pieces", Vector2(segment.start[0],segment.start[1]), Vector2(segment.end[0],segment.end[1]), str(segment.id))
							check(route.size() == 1 and route[0][0].distance_to(Vector2(segment.start[0],segment.start[1])) < 1 and route[0][1].distance_to(Vector2(segment.end[0],segment.end[1])) < 1 if not route.is_empty() else false, "Fully explored map shows all of real segment " + str(segment.id))
					else:
						var stair: Array = actual_segments.GateBalconyUp
						var hidden_stair: Array = ui.call("_visible_route_pieces", stair[0], stair[1], "GateBalconyUp")
						check(hidden_stair.is_empty() or hidden_stair[-1][1].distance_to(stair[1]) > 20, "Undiscovered end of the gate stair stays hidden")
				else: check(false, "Map can merge visible route intervals")
				if ui.has_method("_map_gate_world_points"):
					var gate_points: Dictionary = ui.call("_map_gate_world_points")
					for id in ["gate_departure","gate_departure_back"]:
						var gate = game.environment.gates[id]
						var expected := Vector2(gate.position.x+gate.width*0.5,588 if id == "gate_departure" else 912)
						check(gate_points.get(id,Vector2.ZERO).distance_to(expected) < 1,"Lock sits on the road at its physical gate: "+id)
				else: check(false, "Map locates gates from real gate geometry")
				if ui.has_method("_map_shortcut_marks"):
					var marks: Array = ui.call("_map_shortcut_marks")
					check(marks.size() == (2 if explored == 3 else 8), "Shortcut marks reveal only explored physical endpoints")
					var entry_marks := marks.filter(func(mark): return mark.gate_id == "gate_entry")
					check(entry_marks.size() == (1 if explored == 3 else 2), "Unknown freight destination is hidden until visited")
					check(entry_marks[0].position.distance_to(game.environment.shortcut_points[0].from) < 1 if not entry_marks.is_empty() else false, "Freight entrance uses its actual interaction position")
				else: check(false, "Map exposes discovered freight shortcut endpoints")
				check(ui._map_zoom > ui._full_map_zoom(), "Default view is readable and zoomed around player")
				check(ui._world_at_map(ui._map.size * 0.5).distance_to(game.player.position) < 2, "Default center follows player")
				var factor: Vector2 = Vector2.ONE * ui._map_zoom
				var offset: Vector2 = ui._map_offset()
				var labels: Dictionary = ui._map_number_rects(factor,offset)
				var legible: bool = labels.size() <= explored
				for id in labels:
					legible = legible and Rect2(Vector2.ZERO,ui._map.size).encloses(labels[id])
					for other in labels:
						if id != other and labels[id].intersects(labels[other]): legible = false
					for cp in game.environment.checkpoints:
						if ui._known_point(cp.position) and labels[id].intersects(Rect2(cp.position * factor + offset - Vector2(16,16),Vector2(32,32))): legible = false
				check(legible, "Visible region markers avoid each other and checkpoints")
				var anchor: Vector2 = ui._map.size * 0.38
				var anchored_world: Vector2 = ui._world_at_map(anchor)
				ui._zoom_map(1.2, anchor)
				check(ui._world_at_map(anchor).distance_to(anchored_world) < 0.01, "Wheel zoom keeps the anchored world location fixed")
				ui._map_pan += Vector2(38, -12)
				check(ui._world_at_map(ui._map.size * 0.5).distance_to(game.player.position) > 50, "Pan moves the viewed world")
				ui._map_action("full")
				check(is_equal_approx(ui._map_zoom, ui._full_map_zoom()), "Full-map control restores the full world extent")
				check(ui._map_view().grow(1).encloses(Rect2(ui._map_bounds().position * ui._map_zoom + ui._map_offset(), ui._map_bounds().size * ui._map_zoom)), "Full-map artwork remains within canvas")
				ui._map_action("player")
				check(ui._world_at_map(ui._map.size * 0.5).distance_to(game.player.position) < 2, "Return-player control resets the view")
				if dimensions.x == 1280 and explored == 16 and opened:
					if ui.has_method("_select_map_region"):
						ui.call("_select_map_region", "mon_15")
						var chapel_bounds: Rect2 = ui._map_selection_bounds("mon_15")
						check(ui._map_view().grow(-18).encloses(Rect2(chapel_bounds.position * ui._map_zoom + ui._map_offset(), chapel_bounds.size * ui._map_zoom)), "Selecting the chapel frames its complete discovered architecture and routes without cutting off its spire")
						check(chapel_bounds.has_point(game.environment.story_positions.elite), "Region framing keeps the real walking deck in view")
						if DisplayServer.get_name() != "headless":
							await RenderingServer.frame_post_draw
							root.get_texture().get_image().save_png("res://artifacts/image_map_ui_1280_selected_chapel.png")
						ui._map_action("player")
					else: check(false, "Selecting a map region focuses its authored route anchor")
				var known_piece: PackedVector2Array = ui._clip_segment(Vector2(0,1120),Vector2(16384,1120),Rect2(0,1000,1200,400))
				check(known_piece.size() == 2 and is_equal_approx(known_piece[1].x,1200), "Route geometry clips at the visible boundary")
				check(ui._clip_segment(Vector2(5000,0),Vector2(6000,0),Rect2(0,1000,1200,400)).is_empty(), "Geometry wholly outside a visible region cannot leak")
				if DisplayServer.get_name() != "headless":
					await RenderingServer.frame_post_draw
					var picture := root.get_texture().get_image()
					var captured: Vector2i = picture.get_size()
					check(captured == dimensions or (dimensions.x > 1920 and captured == Vector2i(1920,1080)), "Capture is native resolution unless desktop hardware clamps the wide window")
					var suffix := "" if captured == dimensions else "_display_clamped"
					picture.save_png("res://artifacts/image_map_ui_%d_%d_%s%s.png" % [dimensions.x,explored,"open" if opened else "locked",suffix])
					if dimensions.x == 1280 and explored == 3 and not opened:
						ui._map_selected = "mon_02"
						ui._update_map_preview()
						check(ui._map_preview_title.text == "装卸入口" and ui._map_preview.texture != null, "Selecting a place shows its generated architectural emblem and correct name")
						await RenderingServer.frame_post_draw
						root.get_texture().get_image().save_png("res://artifacts/image_map_ui_1280_selected_gatehouse.png")
					if explored == 16 and opened and dimensions.x in [1280,1920]:
						ui._map_action("full")
						await RenderingServer.frame_post_draw
						root.get_texture().get_image().save_png("res://artifacts/image_map_ui_%d_full.png" % dimensions.x)
				session.close()
				game.environment.gate_states.assign(original_gates)
		# Restore only in-memory visits to cover the partial-map case at both sizes.
		session.state = session.Store.new()
		session.state.configure(session.Data.catalog(), session.Data.quests())
	app.free()
	print("IMAGE MAP UI STAGE RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
