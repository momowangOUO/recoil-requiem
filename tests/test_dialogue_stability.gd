extends SceneTree

var checks := 0
var failures := 0
var ui: CampaignUI

func _initialize() -> void: run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func geometry() -> Array:
	var text: Label = ui.find_child("CurrentUtterance", true, false)
	return [ui.panel.get_rect(), text.get_global_rect(), ui._dialogue_nameplate.get_rect(), ui._dialogue_portrait.get_rect(), ui._dialogue_actions.get_global_rect()]

func observe(label: String, expected: Array) -> void:
	# Start at the immediate state and the first drawn frame, never settle first.
	check(geometry() == expected, label + ": immediate committed geometry")
	for frame in 12:
		if DisplayServer.get_name() == "headless": await process_frame
		else: await RenderingServer.frame_post_draw
		check(geometry() == expected, "%s: no layout movement on frame %d" % [label, frame])
		var text: Label = ui.find_child("CurrentUtterance", true, false)
		if frame == 0 and text.get_global_rect().end.y >= ui._dialogue_actions.global_position.y:
			print("LAYOUT TRACE ", label, " text=", text.get_global_rect(), " actions=", ui._dialogue_actions.get_global_rect(), " measured=", ui._dialogue_text_rect)
		check(text.get_global_rect().end.y < ui._dialogue_actions.global_position.y, label + ": text clears actions")
		check(text.get_line_count() == text.get_visible_line_count(), label + ": every wrapped line stays visible")

func run() -> void:
	root.content_scale_size = Vector2i(320, 180)
	root.size = Vector2i(1280, 720)
	ui = load("res://scripts/ui/campaign_ui.gd").new()
	root.add_child(ui)
	var lines := ["玛拉：找谁？", "鲁卡：交接的价钱还没谈，我得让他们知道这些地方怎么修。", "莉芙：维拉。"]
	var options := [{"id":"later", "text":"先带着箱子离开。"}, {"id":"tools_ina", "text":"把箱子交还伊娜。"}, {"id":"tools_mara", "text":"把箱子留在交接处。"}]
	for dimensions in [Vector2i(960,540), Vector2i(1280,720), Vector2i(1920,1080), Vector2i(2560,1080)]:
		root.size = dimensions
		ui.show_dialogue("玛拉", lines, options)
		var text: Label = ui.find_child("CurrentUtterance", true, false)
		var text_id := text.get_instance_id()
		var plate_id := ui._dialogue_nameplate.get_instance_id()
		var segment_rect := ui.panel.get_rect()
		var reading_top := text.global_position
		await observe("open %s" % dimensions, geometry())
		for page in range(1, 3):
			ui.advance_dialogue()
			check(ui.panel.get_rect() == segment_rect, "Whole conversation reserves one frame")
			text = ui.find_child("CurrentUtterance", true, false)
			check(text.get_instance_id() == text_id and ui._dialogue_nameplate.get_instance_id() == plate_id, "Page changes reuse text and nameplate")
			check(text.global_position == reading_top, "Short/long/choices keep the same reading top")
			await observe("page %s/%d" % [dimensions, page], geometry())
		ui.close_panel()
		ui.show_dialogue("玛拉", [lines[0]], [])
		await observe("immediate reopen %s" % dimensions, geometry())
	# Resize an already visible conversation: the new layout must be ready before drawing.
	root.size = Vector2i(960, 540)
	await observe("live resize", geometry())
	ui.close_panel()
	ui.free()
	print("DIALOGUE STABILITY STAGE RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
