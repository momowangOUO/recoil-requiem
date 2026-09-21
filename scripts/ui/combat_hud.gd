class_name CombatHud
extends Control

const COPY = preload("res://assets/ui/hud_text.json")
const POINTS := [Vector2(64,-67), Vector2(120,-94), Vector2(180,-105), Vector2(240,-94), Vector2(296,-67)]
const BONE := Color("e8e4d5")
const TIMING := {"transition":0.12, "number":0.45, "wheel":0.8, "view":0.12, "restore":0.4, "task":2.0, "area":3.0}
var metrics: Dictionary = {}
var order: Array[int] = []
var hold := 0.0
var opening := 0.0
var viewing := false
var blocked := false
var ui_scale := 1.0
var high_contrast := false
var reduced_motion := false
var view_toggle := false
var reverse_wheel := false
var quiet := 0.0
var messages: Array[Dictionary] = []
var area := ""
var notice_label: Label
var old_health := 5
var hurt_cell := -1
var hurt_time := 0.0
var failure := 0.0
var shot_time := 0.0
var icons: Array[Texture2D] = []
static var icon_cache: Array[Texture2D] = []
const ART_PATHS := [
	"res://assets/ui/v2/runtime/weapon_frame.png",
	"res://assets/ui/v2/runtime/health_full.png",
	"res://assets/ui/v2/runtime/health_empty.png",
	"res://assets/ui/v2/runtime/gun_revolver.png",
	"res://assets/ui/v2/runtime/gun_shotgun.png",
	"res://assets/ui/v2/runtime/gun_smg.png",
	"res://assets/ui/v2/runtime/slot_frame.png",
	"res://assets/ui/v2/runtime/divider.png",
]

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	scale = Vector2.ONE * 0.25
	notice_label = Label.new()
	notice_label.name = "ReadableNotice"
	notice_label.position = Vector2(32, 24)
	notice_label.size = Vector2(720, 80)
	notice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	notice_label.add_theme_font_size_override("font_size", 20)
	notice_label.add_theme_color_override("font_color", BONE)
	notice_label.add_theme_color_override("font_outline_color", Color("080b12"))
	notice_label.add_theme_constant_override("outline_size", 4)
	add_child(notice_label)
	notice_label.hide()
	if not icon_cache.is_empty():
		icons = icon_cache
		return
	for path in ART_PATHS:
		icons.append(load(path) as Texture2D)
	icon_cache = icons

func suspend(value: bool) -> void:
	blocked = value
	viewing = false
	hold = 0
	opening = 0
	shot_time = 0
	queue_redraw()

func result(_slot: int, success: bool, changed: bool, source: String) -> void:
	if not success:
		failure = 0.6
	elif changed:
		shot_time = 0
		hold = TIMING.wheel if source == "wheel" else TIMING.number

func notify(message: String, kind := "task") -> void:
	if message.is_empty(): return
	for item in messages.duplicate():
		if item.kind == kind: messages.erase(item)
	var duration: float = TIMING.area if kind == "area" else clampf(message.length() * 0.09, TIMING.task, 8.0)
	messages.append({"text": message, "kind": kind, "time": duration})
	messages.sort_custom(func(a: Dictionary, b: Dictionary): return a.kind == "task" and b.kind != "task")
	while messages.size() > 3: messages.pop_front()

func sync(data: Dictionary) -> void:
	metrics = data
	order.assign(data.get("cycle_order", []))
	viewing = bool(data.get("viewing", false)) and not blocked
	var next_area := str(data.get("title", ""))
	if next_area != area:
		area = next_area
		notify(area, "area")
	var hp := int(data.get("health", 5))
	if hp < old_health:
		hurt_cell = hp
		hurt_time = 0.18
	old_health = hp
	queue_redraw()

func others() -> Array[int]:
	var result: Array[int] = []
	var active := int(metrics.get("active_slot", -1))
	var start := order.find(active)
	if start < 0: return result
	for i in range(1, order.size()): result.append(order[(start + i) % order.size()])
	return result

func visible_slots() -> Array[int]:
	if opening <= 0.0:
		var next := others()
		var collapsed: Array[int] = []
		if not next.is_empty(): collapsed.append(next[0])
		return collapsed
	var slots: Array[int] = []
	var active := int(metrics.get("active_slot", -1))
	for slot in 6:
		if slot != active: slots.append(slot)
	return slots

func _process(delta: float) -> void:
	scale = Vector2.ONE * 0.25 * ui_scale
	visible = not blocked
	if blocked: return
	shot_time = maxf(0, shot_time - delta)
	hold = maxf(0, hold - delta)
	failure = maxf(0, failure - delta)
	hurt_time = maxf(0, hurt_time - delta)
	var expanded := (viewing or hold > 0) and order.size() > 1
	opening = move_toward(opening, 1.0 if expanded else 0.0, delta / (0.06 if reduced_motion else TIMING.transition))
	if opening > 0 or metrics.get("combat", false):
		quiet = TIMING.restore
	else:
		quiet = maxf(0, quiet - delta)
		if quiet <= 0 and not messages.is_empty():
			messages[0].time -= delta
			if messages[0].time <= 0: messages.pop_front()
	var message := str(metrics.get("objective", ""))
	if not messages.is_empty(): message = str(messages[0].text)
	notice_label.text = message.replace(" · ", "\n")
	notice_label.size.x = minf(720, get_viewport_rect().size.x / scale.x * 0.58 - 32)
	notice_label.visible = opening <= 0 and quiet <= 0 and not message.is_empty()
	queue_redraw()

func text_at(at: Vector2, value: String, size_px: int, tint := BONE) -> void:
	var font := preload("res://assets/fonts/unifont-18.0.01.otf")
	draw_string_outline(font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, 6 if high_contrast else 4, Color("080b12"))
	draw_string(font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, tint)

func icon(index: int, rect: Rect2, tint := Color.WHITE) -> void:
	if index >= icons.size(): return
	var tex := icons[index]
	if tex == null: return
	var factor := minf(rect.size.x / tex.get_width(), rect.size.y / tex.get_height())
	var dim := tex.get_size() * factor
	draw_texture_rect(tex, Rect2(rect.get_center() - dim * 0.5, dim), false, tint)

func weapon_icon(slot: int, center: Vector2, diameter: float, alpha := 1.0) -> void:
	icon(0 if diameter >= 48 else 6, Rect2(center - Vector2.ONE * diameter * 0.5, Vector2.ONE * diameter), Color(1,1,1,alpha))
	var inv: Array = metrics.get("inventory", [])
	if slot < 0 or slot >= inv.size() or not inv[slot].get("occupied", false): return
	var index: int = {"revolver":3,"shotgun":4,"smg":5}.get(str(inv[slot].get("id", "")), -1)
	if index >= 0: icon(index, Rect2(center - Vector2(diameter * 0.34,diameter * 0.22), Vector2(diameter * 0.68,diameter * 0.44)), Color(1,1,1,alpha))
	else: text_at(center + Vector2(-4,5), "?", 16)

func _draw() -> void:
	if metrics.is_empty(): return
	# All combat information shares a bottom-left anchor, independent of window scale.
	draw_set_transform(weapon_origin())
	for i in int(metrics.get("max_health", 5)):
		var full := i < int(metrics.get("health", 5))
		var tint := Color(1.6,1.6,1.6) if i == hurt_cell and hurt_time > 0 else Color.WHITE
		icon(1 if full else 2, Rect2(132+i*31,-18,20,29), tint)
	icon(7, Rect2(128,13,157,10))
	var active := int(metrics.get("active_slot", -1))
	var available := visible_slots()
	for i in available.size():
		var p: Vector2 = POINTS[i]
		if i > 0 and not reduced_motion: p += Vector2(-4,4) * (1.0-opening)
		var a := 1.0 if opening <= 0.0 else opening
		weapon_icon(available[i], p, 36, a)
		text_at(p + Vector2(-5,32), str(available[i]+1), 16, Color(BONE, a))
	weapon_icon(active, Vector2(64,59), 64)
	text_at(Vector2(59,105), str(active+1) if active in order else "—", 16)
	if active in order:
		var ammo := int(metrics.get("ammo",0))
		var magazine := int(metrics.get("magazine",0))
		var tint := ammo_color(ammo, magazine)
		text_at(Vector2(132,32), str(metrics.get("weapon_name", "")), 20)
		text_at(Vector2(128,83), "%02d" % ammo, 56, tint)
		text_at(Vector2(214,81), "/ %d" % magazine, 24)
	var ring := ring_state()
	if failure > 0: text_at(Vector2(108,-17), COPY.data.empty, 16)
	draw_set_transform(Vector2.ZERO)
	if ring.visible and active in order:
		var alpha := 1.0 if float(metrics.get("reload_progress",-1)) >= 0 else clampf(shot_time / 0.1,0,1)
		ReloadFeedback.draw_ring(self, weapon_origin() + Vector2(64,59), ring.ratio, alpha, 37.0)

func weapon_origin() -> Vector2:
	return Vector2(0, get_viewport_rect().size.y / scale.y - 140)

func ammo_color(ammo: int, magazine: int) -> Color:
	if ammo == 0: return Color("ff6c74")
	if ammo <= ceili(magazine * 0.25): return Color("ffc16e")
	return Color("fff5df")

func ring_state() -> Dictionary:
	var reload := float(metrics.get("reload_progress", -1))
	if reload >= 0: return {"ratio":clampf(reload,0,1), "color":ReloadFeedback.progress_color(reload), "visible":true}
	var ammo := int(metrics.get("ammo",0))
	var magazine := int(metrics.get("magazine",0))
	return {"ratio":clampf(float(ammo)/maxi(1,magazine),0,1), "color":ammo_color(ammo,magazine), "visible":shot_time > 0}
