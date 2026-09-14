extends SceneTree
## Measures source regions only; does not modify or repaint any image pixels.
const ROOTS := {
	"charger": [175,560,940,1340,215,615,945,1330],
	"grenadier": [210,660,1100,1540,260,650,1090,1510],
	"flyer": [230,630,1070,1490,260,645,1030,1450],
	"support": [195,560,945,1320,195,585,935,1320],
	"elite": [155,520,910,1330,160,560,920,1320],
	"boss": [190,585,1000,1430,230,600,1005,1440]
}
func _initialize() -> void:
	var manifest := {}
	for kind in ROOTS:
		var path := "res://assets/characters/campaign/%s_actions_v1.png" % kind
		var source := Image.load_from_file(path)
		var w := source.get_width()
		var h := source.get_height()
		var frames := []
		for frame in 8:
			var x0 := int(frame % 4 * w / 4.0)
			var x1 := int((frame % 4 + 1) * w / 4.0)
			var y0 := 0 if frame < 4 else h / 2
			var y1 := h / 2 if frame < 4 else h
			# Authored weapon extensions need individual windows, never equal-cell clipping.
			if kind == "charger":
				var edges := [0,400,790,1150,w] if frame < 4 else [0,500,790,1130,w]
				x0 = edges[frame % 4]
				x1 = edges[frame % 4 + 1]
			if kind in ["flyer", "boss"] and frame >= 4:
				var edges := [0,490,810,1190,w]
				x0 = edges[frame % 4]
				x1 = edges[frame % 4 + 1]
			if kind == "elite" and frame >= 4:
				var edges := [0,420,760,1080,w]
				x0 = edges[frame % 4]
				x1 = edges[frame % 4 + 1]
			if kind == "boss" and frame < 4:
				var edges := [0,418,835,1210,w]
				x0 = edges[frame % 4]
				x1 = edges[frame % 4 + 1]
			if kind == "support" and frame >= 4:
				var edges := [0,420,760,1110,w]
				x0 = edges[frame % 4]
				x1 = edges[frame % 4 + 1]
			if kind == "grenadier" and frame >= 4:
				var edges := [0,443,887,1260,w]
				x0 = edges[frame % 4]
				x1 = edges[frame % 4 + 1]
			var low := Vector2i(w,h)
			var high := Vector2i.ZERO
			for y in range(y0,y1):
				for x in range(x0,x1):
					var c := source.get_pixel(x,y)
					if c.a > 0.8 and minf(c.r,c.b)-c.g < 0.18:
						low = low.min(Vector2i(x,y))
						high = high.max(Vector2i(x,y))
			frames.append({"region": [low.x,low.y,high.x-low.x+1,high.y-low.y+1], "anchor": [ROOTS[kind][frame],high.y+1]})
		var standing_height: float = frames[0].region[3]
		# Flyer wings exceed the body crown; use her actual head-to-boot baseline.
		if kind == "flyer": standing_height = 330
		manifest[kind] = {"path":path,"scale":44.0/standing_height,"frames":frames}
	var file := FileAccess.open("res://assets/characters/campaign/manifest.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest,"\t"))
	var gd_file := FileAccess.open("res://assets/characters/campaign/manifest_data.gd",FileAccess.WRITE)
	gd_file.store_string("extends RefCounted\nconst DATA := " + JSON.stringify(manifest,"\t") + "\n")
	print("Campaign source regions measured: ",manifest.size())
	quit()
