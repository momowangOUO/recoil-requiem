class_name KeyboardInput
extends RefCounted

var blocked_fire := true
var blocked_jump := true
var blocked_melee := true
var wheel_switch := false
var wheel_steps: Array[int] = []
var view_active := false
var view_toggle := false
var view_threshold := 0.12
var q_time := 0.0
var blocked_view := false

static func install_actions() -> void:
	var mapping := {"move_left": KEY_A, "move_right": KEY_D, "move_up": KEY_W, "move_down": KEY_S, "reload": KEY_R, "switch_weapon": KEY_Q, "jump": KEY_SPACE, "melee": KEY_V}
	for index in 6:
		mapping["weapon_%d" % (index + 1)] = [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6][index]
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
	blocked_melee = true
	wheel_switch = false
	wheel_steps.clear()
	view_active = false
	q_time = 0.0
	blocked_view = true

func sample(mouse_world: Vector2) -> InputFrame:
	var frame := InputFrame.new()
	frame.move = Vector2(Input.get_axis("move_left", "move_right"), Input.get_axis("move_up", "move_down"))
	frame.aim_world = mouse_world
	if not Input.is_action_pressed("fire"):
		blocked_fire = false
	frame.fire_pressed = Input.is_action_just_pressed("fire") and not blocked_fire
	frame.fire_held = Input.is_action_pressed("fire") and not blocked_fire
	frame.reload_pressed = Input.is_action_just_pressed("reload")
	frame.switch_pressed = wheel_switch
	frame.wheel_steps.assign(wheel_steps)
	wheel_steps.clear()
	if not Input.is_action_pressed("switch_weapon") and not Input.is_action_just_released("switch_weapon"): blocked_view = false
	if not blocked_view:
		if view_toggle:
			if Input.is_action_just_pressed("switch_weapon"): view_active = not view_active
		else:
			if Input.is_action_pressed("switch_weapon"):
				q_time += 1.0 / 60.0
				view_active = q_time >= view_threshold
			elif Input.is_action_just_released("switch_weapon"):
				frame.switch_pressed = q_time > 0 and q_time < view_threshold
				q_time = 0
				view_active = false
	frame.drop_pressed = Input.is_action_just_pressed("move_down")
	if not Input.is_action_pressed("jump"):
		blocked_jump = false
	frame.jump_pressed = Input.is_action_just_pressed("jump") and not blocked_jump
	if not Input.is_action_pressed("melee"):
		blocked_melee = false
	frame.melee_pressed = Input.is_action_just_pressed("melee") and not blocked_melee
	for index in 6:
		if Input.is_action_just_pressed("weapon_%d" % (index + 1)):
			frame.weapon_slot_pressed = index
			break
	wheel_switch = false
	return frame
