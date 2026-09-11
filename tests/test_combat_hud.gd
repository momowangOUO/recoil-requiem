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
	hud.sync({"active_slot":0,"cycle_order":[]})
	check(hud.others().is_empty())
	hud.free()
	print("COMBAT HUD STAGE RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
