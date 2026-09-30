extends SceneTree
## Engine mouse/focus events and interruptible pose switching; no gameplay saves.
const Flow = preload("res://scripts/ui/player_flow_ui.gd")
var checks := 0
var failures := 0
var flow: Control

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func _initialize() -> void:
	run.call_deferred()

func settle(count := 3) -> void:
	for i in count: await process_frame

func move_mouse(button: Button) -> void:
	var event := InputEventMouseMotion.new()
	# Input accepts window pixels, then Godot applies the project's 4x transform.
	event.position = root.get_final_transform() * button.get_global_rect().get_center()
	event.global_position = event.position
	Input.parse_input_event(event)
	await settle()

func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await settle()
	var release := event.duplicate()
	release.pressed = false
	Input.parse_input_event(release)

func finish_transition() -> void:
	await create_timer(0.25, true).timeout
	await settle()

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/title_hero_" + label + ".png")

func run() -> void:
	root.size = Vector2i(1280,720)
	flow = Flow.new()
	root.add_child(flow)
	await settle()
	check(flow.has_method("configure_hero"), "Title hero supports an explicit atlas/anchor manifest")
	if not flow.has_method("configure_hero"):
		flow.free()
		finish()
		return
	# Existing UI texture is only a contract fixture while final art is prepared.
	# Production always loads the authored manifest; no placeholder is installed.
	var texture: Texture2D = load("res://assets/ui/v2/runtime/button_normal.png")
	var extent := texture.get_size()
	var manifest := {"reference_height": extent.y, "display_height": 160.0, "foot_position":[0.38,0.91], "regions":[]}
	for id in ["ready","cylinder","cuff","notebook","lookback"]:
		manifest.regions.append({"id":id,"rect":[0,0,extent.x,extent.y],"anchor":[extent.x/2,extent.y]})
	check(flow.configure_hero(manifest, texture) == OK, "Validated regions configure a single anchored hero layer")
	var real_art := FileAccess.file_exists("res://data/campaign/title_hero_poses.json")
	check(real_art, "Production title manifest is required; a contract fixture cannot replace authored art")
	if real_art:
		check(flow.load_hero_manifest() == OK, "Actual generated atlas and metadata load")
	flow.show_page("title", {"has_progress":true,"save_code":"ready"})
	await settle()
	await finish_transition()
	check(flow.hero_pose == "ready", "Default Continue focus shows the ready pose")
	var foot: Vector2 = flow.hero_foot
	var shared_scale: float = flow.hero_scale
	for pair in [["continue","ready"],["restart","cylinder"],["settings","cuff"],["help","notebook"],["quit","lookback"]]:
		await move_mouse(flow.buttons[pair[0]])
		await finish_transition()
		check(flow.hero_pose == pair[1] and flow.hero_target_pose == pair[1], "Real mouse hover selects " + pair[1])
		check(flow.hero_foot.is_equal_approx(foot) and is_equal_approx(flow.hero_scale, shared_scale), "Pose switches retain one foot anchor and scale")
		var pose: Dictionary = flow._hero_regions[pair[1]]
		check((flow.hero.position + pose.anchor * flow.hero_scale).is_equal_approx(foot), "The rendered crop's actual foot remains registered")
		check(flow.hero.get_rect().end.x <= flow.art_rect.position.x + flow.art_rect.size.x * 0.665 + 0.1, "Pose stays outside the menu safe area")
		if real_art: await capture(pair[1])
	flow.buttons["continue"].grab_focus()
	await finish_transition()
	check(flow.hero_pose == "ready", "Focus synchronizes with the same pose mapping as hover")
	await key(KEY_TAB)
	await finish_transition()
	check(flow.buttons.restart.has_focus() and flow.hero_pose == "cylinder", "Real keyboard Tab moves focus and selects the cylinder pose")
	flow.buttons.settings.disabled = true
	await move_mouse(flow.buttons.settings)
	await finish_transition()
	check(flow.hero_pose == "cylinder", "Disabled option cannot trigger a hover pose")
	flow.buttons.settings.disabled = false
	await move_mouse(flow.buttons.help)
	await move_mouse(flow.buttons.quit)
	await move_mouse(flow.buttons.settings)
	await finish_transition()
	check(flow.hero_pose == "cuff" and flow.hero_target_pose == "cuff" and is_equal_approx(flow.hero.modulate.a,1.0), "Rapid hover cancels stale tween callbacks and finishes on the last selection")
	check(flow.find_children("TitleHero", "TextureRect", true, false).size() == 1, "Only one hero image exists, so transitions cannot overlay two faces")
	flow.select_hero_pose("notebook")
	flow._hero_tween.pause()
	flow._hero_tween.custom_step(0.03)
	check(flow.hero_pose == "cuff" and flow.hero.modulate.a > 0 and flow.hero.modulate.a < 1, "Old crop fades before any face switch")
	flow._hero_tween.custom_step(0.040001)
	check(flow.hero_pose == "notebook" and flow.hero.modulate.a < 0.0001, "Crop changes at the zero-opacity boundary")
	flow._hero_tween.custom_step(0.11)
	check(is_equal_approx(flow.hero.modulate.a,1.0), "New crop fades back to full opacity")
	flow.show_page("help", {"save_code":"ready"})
	await finish_transition()
	check(flow.hero_pose == "ready" and flow.buttons.back.has_focus(), "Help page focuses Return and uses its ready pose")
	flow.show_page("title", {"has_progress":false,"save_code":"ready"})
	await finish_transition()
	check(not flow.buttons.has("restart") and flow.hero_pose == "ready", "Fresh title retains the single Start action and ready pose")
	for id in Flow.COPY:
		if id in ["confirm", "cancel", "back", "fullscreen", "shake", "retry_save", "retry_load", "quit_unsaved", "checkpoint", "title_return"]:
			check(Flow.HERO_ACTIONS.has(id), "Secondary option has an intentional action: " + id)
	for pair in [["restart", "confirm", "cylinder"], ["restart", "cancel", "ready"], ["settings", "shake", "cuff"], ["help", "back", "ready"], ["quit_unsaved", "quit_unsaved", "lookback"]]:
		flow.show_page(pair[0], {"save_code":"ready", "settings":{}})
		await settle()
		flow.buttons[pair[1]].grab_focus()
		await finish_transition()
		check(flow.hero_pose == pair[2], "Confirmation/settings/back option uses a related pose: " + pair[1])
	flow.show_page("title", {"has_progress":false,"save_code":"ready"})
	await finish_transition()
	var invalid := manifest.duplicate(true)
	invalid.regions[0].rect[2] = texture.get_width()+1
	check(flow.configure_hero(invalid, texture) == ERR_INVALID_DATA, "Out-of-atlas regions are rejected instead of displaying neighboring art")
	check(flow.hero_pose == "ready" and flow.hero.visible, "Rejected metadata preserves the last usable hero")
	if real_art:
		for dimensions in [Vector2i(960,540),Vector2i(1920,1080),Vector2i(2560,1080)]:
			root.size = dimensions
			await settle(5)
			check(flow.hero_foot.is_equal_approx(foot), "Window scaling does not drift the authored foot anchor")
			await capture("ready_%dx%d" % [dimensions.x, dimensions.y])
	flow.free()
	finish()

func finish() -> void:
	print("TITLE HERO STAGE RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
