class_name InputFrame
extends RefCounted

var move := Vector2.ZERO
var aim_world := Vector2.ZERO
var fire_pressed := false
var fire_held := false
var reload_pressed := false
var switch_pressed := false
var wheel_steps: Array[int] = []
var drop_pressed := false
var jump_pressed := false
## Zero-based direct weapon index; -1 means no numeric selection this frame.
var weapon_slot_pressed := -1
