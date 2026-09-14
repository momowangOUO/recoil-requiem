extends SceneTree
## Render staging uses explicit positions; this is not a human playthrough.
var game: RecoilLab
var presentation: Control
func _initialize() -> void: run.call_deferred()
func settle(count: int = 90) -> void:
	for i in count: await process_frame
func capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/campaign_"+label+".png")
func at(id: String) -> void:
	for p in game.campaign_session.points:
		if p.id == id:
			game.player.position = p.position + Vector2(-32,0)
			game.player.velocity = Vector2.ZERO
			return
func run() -> void:
	root.size = Vector2i(1280,720)
	presentation = load("res://scenes/game.tscn").instantiate()
	root.add_child(presentation)
	await settle(15)
	game = presentation.stage.game
	game.player.manual_control = true
	game.player.invulnerability = 10000
	await capture("entry")
	at("mara")
	await settle()
	await capture("mara_world")
	var press := InputEventKey.new()
	press.physical_keycode = KEY_E
	press.pressed = true
	Input.parse_input_event(press)
	await settle(3)
	await capture("mara_dialogue")
	print("CAMPAIGN E INPUT MODAL: ",game.campaign_session.ui.is_panel_open())
	game.campaign_session.close()
	at("vira")
	await settle()
	game.campaign_session.talk("vira")
	await settle(2)
	await capture("vira_dialogue")
	game.campaign_session.close()
	for id in ["ina","ruka","celine"]:
		at(id)
		await settle()
		await capture(id+"_world")
		game.campaign_session.talk(id)
		game.campaign_session.close()
	game.campaign_session.event("inner_reached")
	at("departure")
	await settle()
	game.campaign_session.interact("departure")
	game.campaign_session.choose("depart")
	await settle(2)
	await capture("departure_dialogue")
	game.campaign_session.close()
	await settle(50)
	await capture("celine_encounter")
	game.campaign_session.pause()
	game.campaign_session.ui.show_journal(game.campaign_session.journal_entries())
	await settle(3)
	await capture("journal")
	game.campaign_session.close()
	var map_key := InputEventKey.new()
	map_key.physical_keycode = KEY_M
	map_key.pressed = true
	game.campaign_session.handle_input(map_key)
	await settle(3)
	await capture("map")
	game.campaign_session.close()
	print("CAMPAIGN RENDER STAGE RESULT: completed actual main-scene views; staged positions, engine E event")
	presentation.free()
	quit()
