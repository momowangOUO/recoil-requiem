class_name WeaponData
extends Resource

@export var id: StringName
@export var display_name: String
@export var magazine_size: int = 6
@export var fire_rate: float = 3.0
@export var damage: float = 24.0
@export var recoil_impulse: float = 250.0
@export var enemy_knockback: float = 125.0
@export var reload_time: float = 1.05
@export var projectile_speed: float = 1400.0
@export var pellet_count: int = 1
@export var spread_degrees: float = 0.5
@export var automatic: bool = false
@export var per_shell: bool = false
@export var color := Color("e8d4ad")

const FIELDS := ["id", "display_name", "magazine_size", "fire_rate", "damage", "recoil_impulse", "enemy_knockback", "reload_time", "projectile_speed", "pellet_count", "spread_degrees", "automatic", "per_shell", "color"]

static func baselines() -> Array:
	return [load("res://data/weapons/nightwatch.tres").duplicate(true), load("res://data/weapons/coffin_nail.tres").duplicate(true), load("res://data/weapons/hymn.tres").duplicate(true)]

func to_dict() -> Dictionary:
	var result := {}
	for key in FIELDS:
		result[key] = get(key)
	return result

func apply_dict(values: Dictionary) -> void:
	for key in ["fire_rate", "recoil_impulse", "reload_time"]:
		if values.has(key):
			set(key, maxf(0.01, float(values[key])))
