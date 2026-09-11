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
var old_health := 5
var hurt_cell := -1
var hurt_time := 0.0
var failure := 0.0
var shot_time := 0.0
var icons: Array[Texture2D] = []
static var icon_cache: Array[Texture2D] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	scale = Vector2.ONE * 0.25
	if not icon_cache.is_empty():
		icons = icon_cache
		return
	var atlas := preload("res://assets/ui/combat_atlas_v1.png").get_image()
	atlas.convert(Image.FORMAT_RGBA8)
	for y in atlas.get_height():
		for x in atlas.get_width():
			var c := atlas.get_pixel(x,y)
			if c.r > 0.5 and c.b > 0.5 and c.g < minf(c.r,c.b) * 0.6: atlas.set_pixel(x,y,Color.TRANSPARENT)
	for i in 6:
		var split := int(atlas.get_height() * 0.585)
		var cell := Rect2i((i % 3) * atlas.get_width() / 3, 0 if i < 3 else split, atlas.get_width() / 3, split if i < 3 else atlas.get_height()-split)
		var image := atlas.get_region(cell)
		icons.append(ImageTexture.create_from_image(image.get_region(image.get_used_rect())))
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
	messages.append({"text": message, "kind": kind, "time": TIMING.area if kind == "area" else TIMING.task})
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
	queue_redraw()

func text_at(at: Vector2, value: String, size_px: int, tint := BONE) -> void:
	var font := ThemeDB.fallback_font
	draw_string_outline(font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, 6 if high_contrast else 4, Color("080b12"))
	draw_string(font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, tint)

func icon(index: int, rect: Rect2, tint := Color.WHITE) -> void:
	if index >= icons.size(): return
	var tex := icons[index]
	var factor := minf(rect.size.x / tex.get_width(), rect.size.y / tex.get_height())
	var dim := tex.get_size() * factor
	draw_texture_rect(tex, Rect2(rect.get_center() - dim * 0.5, dim), false, tint)

func weapon_icon(slot: int, center: Vector2, diameter: float, alpha := 1.0) -> void:
	draw_arc(center, diameter * 0.5, 0, TAU, 48, Color(BONE, alpha), 1.2, true)
	var inv: Array = metrics.get("inventory", [])
	if slot < 0 or slot >= inv.size() or not inv[slot].get("occupied", false): return
	var index: int = {"revolver":3,"shotgun":4,"smg":5}.get(str(inv[slot].get("id", "")), -1)
	if index >= 0: icon(index, Rect2(center - Vector2(diameter * 0.40,diameter * 0.32), Vector2(diameter * 0.80,diameter * 0.64)), Color(1,1,1,alpha))
	else: text_at(center + Vector2(-4,5), "?", 16)

func _draw() -> void:
	if metrics.is_empty(): return
	# All combat information shares a bottom-left anchor, independent of window scale.
	if opening <= 0 and quiet <= 0:
		var message := str(metrics.get("objective", ""))
		if not messages.is_empty(): message = str(messages[0].text)
		var lines := message.split(" · ")
		for i in mini(2,lines.size()): text_at(Vector2(32,40+i*20), lines[i].left(28),16)
	draw_set_transform(weapon_origin())
	for i in int(metrics.get("max_health", 5)):
		var full := i < int(metrics.get("health", 5))
		var tint := Color(1.6,1.6,1.6) if i == hurt_cell and hurt_time > 0 else Color.WHITE
		icon(1 if full else 2, Rect2(132+i*31,-18,20,29), tint)
	draw_line(Vector2(116,26),Vector2(116,104),Color(0.6,0.57,0.48,0.6),1.0,true)
	var active := int(metrics.get("active_slot", -1))
	var available := others()
	var previous := Vector2(64,59)
	for i in available.size():
		if i > 0 and opening <= 0: break
		var p: Vector2 = POINTS[i]
		var a := 1.0 if i == 0 else opening
		draw_line(previous, p, Color(0.55,0.56,0.65,a * 0.65), 1.0, true)
		previous = p
	for i in available.size():
		if i > 0 and opening <= 0: break
		var p: Vector2 = POINTS[i]
		if i > 0 and not reduced_motion: p += Vector2(-4,4) * (1.0-opening)
		weapon_icon(available[i], p, 32, 1.0 if i == 0 else opening)
		text_at(p + Vector2(-5,32), str(available[i]+1), 16, Color(BONE, 1.0 if i == 0 else opening))
	weapon_icon(active, Vector2(64,59), 64)
	icon(0, Rect2(24,19,80,80))
	var diamond := PackedVector2Array([Vector2(64,88),Vector2(74,99),Vector2(64,110),Vector2(54,99),Vector2(64,88)])
	draw_colored_polygon(diamond, Color("10121d"))
	draw_polyline(diamond, BONE, 1.5, true)
	text_at(Vector2(59,105), str(active+1) if active in order else "—", 16)
	if active in order:
		var ammo := int(metrics.get("ammo",0))
		var magazine := int(metrics.get("magazine",0))
		var tint := ammo_color(ammo, magazine)
		text_at(Vector2(132,32), str(metrics.get("weapon_name", "")), 14)
		text_at(Vector2(128,83), "%02d" % ammo, 56, tint)
		text_at(Vector2(214,81), "/ %d" % magazine, 24)
	var ring := ring_state()
	if ring.visible and active in order:
		var alpha := 1.0 if float(metrics.get("reload_progress",-1)) >= 0 else clampf(shot_time / 0.1,0,1)
		draw_arc(Vector2(64,59),36,0,TAU,64,Color(Color("39343f"),alpha),4,true)
		draw_arc(Vector2(64,59),36,-PI*0.5,-PI*0.5+TAU*ring.ratio,64,Color(ring.color,alpha),4,true)
	if failure > 0: text_at(Vector2(108,-17), COPY.data.empty, 16)
	draw_set_transform(Vector2.ZERO)

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
