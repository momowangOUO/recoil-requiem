class_name PlayerTuning
extends Resource

@export var gravity: float = 1500.0
@export var jump_impulse: float = 460.0
@export var walk_max_speed: float = 150.0
@export var ground_acceleration: float = 1400.0
@export var ground_deceleration: float = 1800.0
@export var air_control_x: float = 380.0
@export var air_control_y: float = 180.0
@export var terminal_velocity: float = 900.0
@export var soft_cap_x: float = 760.0
@export var soft_cap_y: float = 900.0
@export var overspeed_drag_x: float = 900.0
@export var overspeed_drag_y: float = 700.0
@export var air_max_speed: float = 220.0
@export var air_deceleration: float = 180.0
@export var ground_recoil_scale: float = 0.45
@export var horizontal_recoil_scale: float = 1.0
## Zero preserves the historical additive GDD recoil.
@export var air_lift_speed: float = 0.0

const FIELDS := ["gravity", "jump_impulse", "walk_max_speed", "ground_acceleration", "ground_deceleration", "air_control_x", "air_control_y", "terminal_velocity", "soft_cap_x", "soft_cap_y", "overspeed_drag_x", "overspeed_drag_y", "air_max_speed", "air_deceleration", "ground_recoil_scale"]

static func gdd_baseline() -> PlayerTuning:
	var result := PlayerTuning.new()
	result.air_max_speed = 760.0
	result.air_deceleration = 0.0
	result.ground_recoil_scale = 1.0
	return result

static func responsive() -> PlayerTuning:
	var result := PlayerTuning.new()
	result.gravity = 2100.0
	result.jump_impulse = 545.0
	result.ground_acceleration = 2400.0
	result.ground_deceleration = 3200.0
	result.horizontal_recoil_scale = 1.1
	result.air_lift_speed = 720.0
	return result

func to_dict() -> Dictionary:
	var result := {}
	result.horizontal_recoil_scale = horizontal_recoil_scale
	result.air_lift_speed = air_lift_speed
	for key in FIELDS:
		result[key] = get(key)
	return result

func apply_dict(values: Dictionary) -> void:
	horizontal_recoil_scale = clampf(float(values.get("horizontal_recoil_scale", horizontal_recoil_scale)), 0.0, 2.0)
	air_lift_speed = maxf(0.0, float(values.get("air_lift_speed", air_lift_speed)))
	for key in FIELDS:
		if values.has(key):
			set(key, maxf(0.0 if key in ["air_control_x", "air_control_y", "air_deceleration", "ground_recoil_scale"] else 1.0, float(values[key])))
	air_control_y = minf(air_control_y, gravity * 0.8)
	ground_recoil_scale = clampf(ground_recoil_scale, 0.0, 1.0)
