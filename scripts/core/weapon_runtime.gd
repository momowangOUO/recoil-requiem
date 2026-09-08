class_name WeaponRuntime
extends RefCounted

var data: WeaponData
var ammo: int
var cooldown: float = 0.0
var reloading := false
var reload_interrupted := false
var reload_elapsed: float = 0.0

func _init(definition: WeaponData) -> void:
	data = definition
	ammo = data.magazine_size

func tick(delta: float, active: bool) -> void:
	cooldown = maxf(0.0, cooldown - delta)
	if not active or not reloading:
		return
	reload_elapsed += delta
	while reloading and reload_elapsed + 0.000001 >= data.reload_time:
		reload_elapsed -= data.reload_time
		ammo = mini(ammo + 1, data.magazine_size) if data.per_shell else data.magazine_size
		if ammo == data.magazine_size:
			reloading = false
			reload_elapsed = 0.0

func try_fire() -> bool:
	if reloading or cooldown > 0.000001 or ammo <= 0:
		return false
	ammo -= 1
	cooldown = 1.0 / data.fire_rate
	if ammo == 0:
		start_reload()
	return true

func start_reload() -> void:
	if ammo < data.magazine_size and not reloading:
		reload_interrupted = false
		reloading = true
		reload_elapsed = 0.0

func cancel_reload() -> void:
	reload_interrupted = reloading
	reloading = false
	reload_elapsed = 0.0

func progress() -> float:
	return clampf(reload_elapsed / data.reload_time, 0.0, 1.0) if reloading else -1.0
