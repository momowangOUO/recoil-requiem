class_name WeaponController
extends Node

var slots: Array[WeaponRuntime] = []
var active_slot: int = 0

func configure(definitions: Array, loadout: Array) -> void:
	slots.clear()
	for index in loadout:
		slots.append(WeaponRuntime.new(definitions[index]))
	active_slot = 0

func current() -> WeaponRuntime:
	return slots[active_slot]

func advance(delta: float, frame: InputFrame) -> WeaponData:
	for index in slots.size():
		slots[index].tick(delta, index == active_slot)
	if frame.switch_pressed:
		current().cancel_reload()
		active_slot = 1 - active_slot
		if current().ammo == 0 or current().reload_interrupted:
			current().start_reload()
	var weapon := current()
	if frame.reload_pressed:
		weapon.start_reload()
	var wants_fire := frame.fire_held if weapon.data.automatic else frame.fire_pressed
	if wants_fire and weapon.try_fire():
		return weapon.data
	return null
