extends SceneTree

const FONT = preload("res://assets/fonts/unifont-18.0.01.otf")
var checks := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func _initialize() -> void:
	run.call_deferred()

func check_controls(node: Node) -> void:
	for child in node.find_children("*", "Control", true, false):
		if child is Label or child is Button or child is LineEdit:
			check(child.get_theme_font("font").get_font_name() == FONT.get_font_name(),
				"All native interface text shares the authored pixel font: " + str(child.name))

func run() -> void:
	check(not FONT.allow_system_fallback, "No platform-dependent smooth CJK fallback")
	check(FONT.subpixel_positioning == TextServer.SUBPIXEL_POSITIONING_DISABLED, "Pixel glyphs retain stable positions")
	var copy: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/campaign/monastery_text.json"))
	var settings: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/settings_text.json"))
	copy.merge(settings)
	var characters := {}
	for value in copy.values():
		for i in str(value).length():
			var code := str(value).unicode_at(i)
			if code > 32: characters[code] = true
	for code in characters:
		check(FONT.has_char(code), "Missing campaign glyph U+%04X" % code)
	var app = load("res://scenes/game.tscn").instantiate()
	root.add_child(app)
	await process_frame
	check(ThemeDB.fallback_font == FONT, "Custom HUD/map drawing uses the same font")
	check_controls(app)
	var overlay = app.stage.game.overlay
	check(overlay._fields.gravity.get_parent().get_child(0).text == "重力", "Settings field captions are Chinese")
	check(overlay._panel.find_child("Resume", true, false).text == "继续游戏", "Translated settings preserve stable button IDs")
	var tabs: TabContainer = overlay._panel.find_children("*", "TabContainer", true, false)[0]
	check(tabs.get_tab_title(0) == "移动" and tabs.get_tab_title(1) == "武器", "Settings page titles are Chinese")
	for line in FileAccess.get_file_as_string("res://game-text/settings-ui-zh-review.md").split("\n"):
		if not line.begins_with("| ") or line.begins_with("| 原文键"): continue
		var fields := line.split("|")
		check(settings.get(fields[1].strip_edges(), "") == fields[2].strip_edges(), "Settings text matches the reviewed draft")
	var ui = app.stage.game.campaign_session.ui
	app.stage.game.campaign_session.pause()
	check(app.stage.game.overlay.combat.blocked, "Campaign modals hide combat numbers instead of painting them over the map")
	ui.show_dialogue("莉芙", ["莉芙：维拉今晚要离开修道院。"], [{"id":"close", "text":"结束交谈"}])
	await process_frame
	check_controls(ui)
	app.stage.game.campaign_session.close()
	check(not app.stage.game.overlay.combat.blocked, "Closing a campaign modal restores combat information")
	app.free()
	print("UI TYPOGRAPHY STAGE RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
