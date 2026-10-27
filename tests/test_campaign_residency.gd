extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	assert("--campaign-test" in OS.get_cmdline_user_args())
	var path := "res://scripts/rooms/campaign_residency.gd"
	check(ResourceLoader.exists(path), "Residency implementation exists")
	if failures: quit(1); return
	var app = load("res://scenes/game.tscn").instantiate()
	root.add_child(app)
	var stage = app.stage
	stage.residency_enabled = false
	stage.residency.clear()
	stage.game.set_physics_process(false)
	stage.game.player.manual_control = true
	var original: Array = stage.scenery.get_children()
	var transforms := {}
	for node in original:
		if node is Node3D: transforms[node] = node.transform
	var residency = load(path).new()
	var baseline: Image
	var render_test := "--residency-render" in OS.get_cmdline_user_args()
	if render_test:
		stage.process_mode = Node.PROCESS_MODE_DISABLED
		await process_frame
		await RenderingServer.frame_post_draw
		baseline = app.stage_viewport.get_texture().get_image()
		baseline.save_png("res://artifacts/residency-full.png")
	residency.setup(stage)
	residency.update_at(Vector2(160,512))
	if render_test:
		await process_frame
		await RenderingServer.frame_post_draw
		var streamed: Image = app.stage_viewport.get_texture().get_image()
		streamed.save_png("res://artifacts/residency-mounted.png")
		check(baseline.get_data() == streamed.get_data(), "Native 640x360 rendering matches full scenery")
	var detached := 0
	for node in original:
		if not node.is_inside_tree(): detached += 1
	check(detached > 0 and stage.platform_visuals[stage.game.environment.get_node("Gameplay/F05")].all(func(piece): return not piece.is_inside_tree()), "Far chapel floor really leaves scene tree")
	print("RESIDENCY original=%d detached=%d mounted=%d" % [original.size(), detached, original.size()-detached])
	for shadow in stage.shadow_cards: check(shadow.is_inside_tree(), "Dynamic shadow stays mounted")
	check(stage.muzzle_light.is_inside_tree(), "Muzzle remains mounted")
	for at in [Vector2(3840,588),Vector2(1824,890),Vector2(160,512)]:
		stage.game.player.position = at
		residency.update_at(at)
		stage._physics_process(0.016)
		for module in stage.platform_visuals:
			for node in stage.platform_visuals[module]: check(is_instance_valid(node), "Platform reference survives unload")
	for entry in residency.bins.values():
		for node in entry.nodes: check(node.transform.is_equal_approx(transforms[node]), "Static local transform survives remount")
	residency.clear()
	for node in original: check(node.is_inside_tree(), "Clear returns nodes to scenery ownership")
	stage.game.reset_trial(3)
	for node in original: check(not is_instance_valid(node), "Reset frees old mounted and detached nodes")
	residency.setup(stage)
	residency.update_at(Vector2(160,512))
	residency.clear()
	app.free()
	print("CAMPAIGN RESIDENCY STAGE RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
