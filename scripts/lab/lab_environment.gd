class_name LabEnvironment
extends Node2D

var preset: int = 0
var spawn := Vector2(80, 320)
var bounds := Rect2(0, 0, 1008, 448)
var blocks: Array[Rect2] = []
var platforms: Array[Rect2] = []
var labels: Array = []
var font: Font = ThemeDB.fallback_font

func build(index: int) -> void:
	preset = index
	match preset:
		0:
			spawn = Vector2(80, 320)
			bounds = Rect2(0, 0, 1008, 448)
			_solid(Rect2(0, 320, 512, 128))
			_solid(Rect2(672, 320, 336, 128))
			_solid(Rect2(136, 304, 64, 16))
			_platform(Rect2(248, 224, 88, 8))
			_platform(Rect2(376, 176, 96, 8))
			labels = [[Vector2(24, 253), "01 / RECOIL STEP"], [Vector2(136, 296), "16 PX"], [Vector2(248, 214), "96 PX"], [Vector2(376, 166), "144 PX"], [Vector2(545, 349), "160 PX GAP"], [Vector2(736, 286), "BRAKE / REVERSE"]]
		1:
			spawn = Vector2(128, 128)
			bounds = Rect2(0, 0, 448, 2432)
			_platform(Rect2(48, 128, 192, 8))
			_solid(Rect2(0, 2304, 448, 128))
			labels = [[Vector2(62, 67), "02 / DESCENT CHAMBER"], [Vector2(62, 83), "S: DROP   |   TAB: EQUIP HYMN"], [Vector2(92, 2286), "2176 PX / LANDING ZONE"]]
			for y in range(256, 2304, 256):
				labels.append([Vector2(26, y), "%04d PX" % (y - 128)])
		2:
			spawn = Vector2(112, 320)
			bounds = Rect2(0, 0, 640, 416)
			_solid(Rect2(0, 320, 640, 96))
			_platform(Rect2(176, 224, 112, 8))
			_platform(Rect2(432, 224, 112, 8))
			labels = [[Vector2(28, 263), "03 / BLIND SIDE"], [Vector2(176, 210), "CROSS OVER"], [Vector2(432, 210), "RELOAD HERE"]]
	# Jump + shotgun reaches above the former camera limit. Add visible headroom.
	bounds.position.y = -512
	bounds.size.y += 512
	_solid(Rect2(-16, bounds.position.y - 16, 16, bounds.size.y + 32))
	_solid(Rect2(bounds.size.x, bounds.position.y - 16, 16, bounds.size.y + 32))
	_solid(Rect2(0, bounds.position.y - 16, bounds.size.x, 16))
	queue_redraw()

func _solid(rect: Rect2) -> void:
	blocks.append(rect)
	_collision(rect, false)

func _platform(rect: Rect2) -> void:
	platforms.append(rect)
	_collision(rect, true)

func _collision(rect: Rect2, one_way: bool) -> void:
	var body := StaticBody2D.new()
	body.position = rect.get_center()
	body.collision_layer = 1024 if one_way else 1
	body.collision_mask = 0
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	collision.one_way_collision = one_way
	collision.one_way_collision_margin = 2.0
	body.add_child(collision)
	add_child(body)

func _draw() -> void:
	draw_rect(bounds, Color("111722"))
	# Measured grid with quiet Gothic arches, kept behind all collision silhouettes.
	for x in range(0, int(bounds.size.x), 16):
		draw_line(Vector2(x, bounds.position.y), Vector2(x, bounds.end.y), Color("19202d"), 1)
	for y in range(int(bounds.position.y), int(bounds.end.y), 16):
		draw_line(Vector2(0, y), Vector2(bounds.size.x, y), Color("19202d"), 1)
	for x in range(80, int(bounds.size.x), 176):
		for y in range(int(bounds.position.y) + 128, int(bounds.end.y), 256):
			var arch := PackedVector2Array([Vector2(x - 32, y + 90), Vector2(x - 32, y - 30), Vector2(x, y - 64), Vector2(x + 32, y - 30), Vector2(x + 32, y + 90)])
			draw_polyline(arch, Color("263043"), 2)
			draw_line(Vector2(x, y - 64), Vector2(x, y + 90), Color("222b3c"), 1)
	for rect in blocks:
		draw_rect(rect, Color("323e50"))
		draw_line(rect.position, Vector2(rect.end.x, rect.position.y), Color("a7b7bb"), 2)
		for x in range(int(rect.position.x) + 8, int(rect.end.x), 16):
			draw_line(Vector2(x, rect.position.y + 5), Vector2(x - 4, rect.position.y + 9), Color("47546a"), 1)
	for rect in platforms:
		draw_rect(rect, Color("435365"))
		draw_line(rect.position, Vector2(rect.end.x, rect.position.y), Color("77c9c2"), 2)
		for x in range(int(rect.position.x) + 8, int(rect.end.x), 16):
			draw_line(Vector2(x, rect.position.y + 2), Vector2(x + 3, rect.end.y), Color("283443"), 1)
	for label in labels:
		draw_string(font, label[0], label[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("879aa7"))
	if preset == 0:
		for x in range(16, 1008, 32):
			draw_line(Vector2(x, 334), Vector2(x, 339), Color("7d8e99"), 1)
			draw_string(font, Vector2(x, 350), str(x), HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("7d8e99"))
		draw_line(Vector2(512, 367), Vector2(672, 367), Color("c7646f"), 1)
		draw_line(Vector2(512, 363), Vector2(512, 371), Color("c7646f"), 1)
		draw_line(Vector2(672, 363), Vector2(672, 371), Color("c7646f"), 1)
