extends SceneTree
var checks := 0
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func check_chain(visual: PlayerVisual, shoulder: Vector2, wrist: Vector2, upper: float, lower: float, label: String) -> void:
	var elbow := visual._elbow(shoulder, wrist, upper, lower)
	check(absf(shoulder.distance_to(elbow) - upper) < 0.01 and absf(elbow.distance_to(wrist) - lower) < 0.01, label + ": authored limbs reach wrist without stretching or detaching")
func run() -> void:
	var game: RecoilLab = load("res://scenes/lab.tscn").instantiate()
	root.add_child(game)
	game.player.manual_control = true
	var visual := game.player.visual
	for index in 3:
		for degrees in range(-180, 181, 15):
			var forward := Vector2.from_angle(deg_to_rad(degrees))
			for facing in [-1.0, 1.0]:
				if absf(forward.x) > 0.01 and forward.x * facing < 0: continue
				game.player.facing = facing
				var shoulder := Vector2(-3 * facing, -26)
				var upper: float = PlayerVisual.RIGHT_SHOULDERS[index].distance_to(PlayerVisual.RIGHT_ELBOWS[index]) * PlayerVisual.ARM_SCALE
				var lower: float = PlayerVisual.RIGHT_ELBOWS[index].distance_to(PlayerVisual.RIGHT_WRISTS[index]) * PlayerVisual.ARM_SCALE
				check_chain(visual, shoulder, visual.right_wrist(index, forward), upper, lower, "Right %d/%d" % [index, degrees])
				if index == 0: continue
				upper = PlayerVisual.LEFT_SHOULDERS[index].distance_to(PlayerVisual.LEFT_ELBOWS[index]) * PlayerVisual.ARM_SCALE
				lower = PlayerVisual.LEFT_ELBOWS[index].distance_to(PlayerVisual.LEFT_WRISTS[index]) * PlayerVisual.ARM_SCALE
				for progress in [-1.0, 0.0, 0.25, 0.5, 0.75, 1.0]:
					var pose := visual.left_pose(index, forward, progress)
					check_chain(visual, Vector2(facing, -26), pose.wrist, upper, lower, "Left %d/%d reload %.2f" % [index, degrees, progress])
	game.free()
	print("ARM STAGE RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
