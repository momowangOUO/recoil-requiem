class_name KeyboardInput
extends RefCounted

var blocked_fire := true
var blocked_jump := true
var wheel_switch := false

static func install_actions() -> void:
	var mapping := {"move_left": KEY_A, "move_right": KEY_D, "move_up": KEY_W, "move_down": KEY_S, "reload": KEY_R, "switch_weapon": KEY_Q, "jump": KEY_SPACE}
	for action in mapping:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			var event := InputEventKey.new()
			event.physical_keycode = mapping[action]
			InputMap.action_add_event(action, event)
	if not InputMap.has_action("fire"):
		InputMap.add_action("fire")
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("fire", event)

func suppress() -> void:
	blocked_fire = true
	blocked_jump = true
	wheel_switch = false

func sample(mouse_world: Vector2) -> InputFrame:
	var frame := InputFrame.new()
	frame.move = Vector2(Input.get_axis("move_left", "move_right"), Input.get_axis("move_up", "move_down"))
	frame.aim_world = mouse_world
	if not Input.is_action_pressed("fire"):
		blocked_fire = false
	frame.fire_pressed = Input.is_action_just_pressed("fire") and not blocked_fire
	frame.fire_held = Input.is_action_pressed("fire") and not blocked_fire
	frame.reload_pressed = Input.is_action_just_pressed("reload")
	frame.switch_pressed = Input.is_action_just_pressed("switch_weapon") or wheel_switch
	frame.drop_pressed = Input.is_action_just_pressed("move_down")
	if not Input.is_action_pressed("jump"):
		blocked_jump = false
	frame.jump_pressed = Input.is_action_just_pressed("jump") and not blocked_jump
	wheel_switch = false
	return frame
