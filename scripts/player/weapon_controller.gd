class_name WeaponController
extends Node

const SLOT_COUNT := 6

## Fixed numbered arsenal. Empty entries are visible, unselectable inventory slots.
var slots: Array = []
var active_slot: int = 0

func configure(definitions: Array, initial_slot: int = 0) -> void:
	slots.clear()
	for definition in definitions.slice(0, SLOT_COUNT):
		slots.append(WeaponRuntime.new(definition))
	while slots.size() < SLOT_COUNT:
		slots.append(null)
	active_slot = _first_occupied_from(initial_slot)

func current() -> WeaponRuntime:
	return slots[active_slot]

func select_weapon(index: int) -> bool:
	if index < 0 or index >= slots.size() or slots[index] == null:
		return false
	if index == active_slot:
		return true
	current().cancel_reload()
	active_slot = index
	if current().ammo == 0 or current().reload_interrupted:
		current().start_reload()
	return true

func cycle_weapon(direction: int = 1) -> bool:
	var step := 1 if direction >= 0 else -1
	for distance in range(1, SLOT_COUNT + 1):
		var candidate := posmod(active_slot + distance * step, SLOT_COUNT)
		if slots[candidate] != null:
			return select_weapon(candidate)
	return false

func inventory_snapshot() -> Array:
	var result: Array = []
	for runtime in slots:
		if runtime == null:
			result.append({"occupied": false})
		else:
			result.append({"occupied": true, "id": runtime.data.id, "display_name": runtime.data.display_name, "ammo": runtime.ammo, "magazine": runtime.data.magazine_size})
	return result

func _first_occupied_from(preferred: int) -> int:
	if preferred >= 0 and preferred < slots.size() and slots[preferred] != null:
		return preferred
	for index in slots.size():
		if slots[index] != null:
			return index
	return 0

func advance(delta: float, frame: InputFrame) -> WeaponData:
	for index in slots.size():
		if slots[index] != null:
			slots[index].tick(delta, index == active_slot)
	if frame.weapon_slot_pressed >= 0:
		select_weapon(frame.weapon_slot_pressed)
	elif frame.switch_pressed:
		cycle_weapon()
	var weapon := current()
	if frame.reload_pressed:
		weapon.start_reload()
	var wants_fire := frame.fire_held if weapon.data.automatic else frame.fire_pressed
	if wants_fire and weapon.try_fire():
		return weapon.data
	return null
