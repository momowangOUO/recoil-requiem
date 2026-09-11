class_name WeaponController
extends Node

const SLOT_COUNT := 6
signal equipment_result(index: int, success: bool, changed: bool, source: String)

func cycle_slots() -> Array[int]:
	var result: Array[int] = []
	for i in slots.size():
		if slots[i] != null: result.append(i)
	return result

func next_slot(direction: int = 1) -> int:
	var order := cycle_slots()
	if order.size() < 2: return -1
	return order[posmod(order.find(active_slot) + direction, order.size())]

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

func select_weapon(index: int, source: String = "number") -> bool:
	if index < 0 or index >= slots.size() or slots[index] == null:
		equipment_result.emit(index, false, false, source)
		return false
	if index == active_slot:
		return true
	if current() != null: current().cancel_reload()
	active_slot = index
	if current().ammo == 0 or current().reload_interrupted:
		current().start_reload()
	equipment_result.emit(index, true, true, source)
	return true

func cycle_weapon(direction: int = 1) -> bool:
	var candidate := next_slot(1 if direction >= 0 else -1)
	return select_weapon(candidate, "wheel") if candidate >= 0 else false

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
	for step in frame.wheel_steps: cycle_weapon(step)
	var weapon := current()
	if weapon == null: return null
	if frame.reload_pressed:
		weapon.start_reload()
	var wants_fire := frame.fire_held if weapon.data.automatic else frame.fire_pressed
	if wants_fire and weapon.try_fire():
		return weapon.data
	return null
