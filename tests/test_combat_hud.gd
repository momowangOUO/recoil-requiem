extends SceneTree
var failures := 0
var checks := 0
func check(value: bool) -> void:
	checks += 1
	if not value: failures += 1
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var hud := CombatHud.new()
	root.add_child(hud)
	hud.sync({"active_slot":2,"cycle_order":[0,2,5],"health":5})
	check(hud.others() == [5,0])
	hud.opening = 1.0
	check(hud.visible_slots() == [0,1,3,4,5])
	hud.opening = 0.0
	check(hud.visible_slots() == [5])
	check(hud.icons.size() >= 8)
	check(ReloadFeedback.SEGMENT != null)
	hud.result(2,true,false,"number")
	check(hud.hold == 0)
	hud.result(5,true,true,"wheel")
	check(is_equal_approx(hud.hold,0.8))
	hud.result(4,false,false,"number")
	check(hud.failure > 0)
	hud.suspend(true)
	check(hud.opening == 0 and hud.hold == 0 and not hud.viewing)
	hud.sync({"active_slot":0,"cycle_order":[0]})
	check(hud.others().is_empty())
	hud.metrics = {"ammo":1,"magazine":6,"reload_progress":-1}
	check(not hud.ring_state().visible)
	hud.shot_time = 0.35
	check(hud.ring_state().visible and is_equal_approx(hud.ring_state().ratio,1.0/6))
	hud.metrics.reload_progress = 0.6
	check(is_equal_approx(hud.ring_state().ratio,0.6))
	hud.metrics.reload_progress = -1
	hud.suspend(false)
	hud._process(0.5)
	check(not hud.ring_state().visible)
	for factor in [1.0,1.5,2.0]:
		hud.ui_scale = factor
		hud._process(0)
		check(is_equal_approx((hud.weapon_origin().y + 140) * hud.scale.y,hud.get_viewport_rect().size.y))
	hud.sync({"active_slot":0,"cycle_order":[]})
	check(hud.others().is_empty())
	var notice := "这是用于验证长任务通知完整显示的测试文字，最后的交互地点和操作不能被截断。"
	hud.notify(notice)
	hud._process(0)
	check(hud.notice_label.text == notice)
	check(hud.messages[0].time > CombatHud.TIMING.task)
	check(hud.notice_label.autowrap_mode != TextServer.AUTOWRAP_OFF)
	hud.free()
	var game: RecoilLab = load("res://scenes/lab.tscn").instantiate()
	root.add_child(game)
	game.player.manual_control = true
	var input := InputFrame.new()
	input.fire_pressed = true
	input.aim_world = game.player.aim_origin()+Vector2(200,0)
	game.player.step(input,1.0/60)
	check(game.reticle.shot_time > 0)
	game.reticle.last_weapon = game.player.weapons.current()
	game.reticle._process(0.5)
	check(game.reticle.shot_time == 0)
	game.free()
	print("COMBAT HUD STAGE RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
