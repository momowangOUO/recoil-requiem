extends Node3D
## Authored architectural silhouettes in real world space, in front of combat.
## Only their material is soft; gameplay and native UI never enter this pass.

func _ready() -> void:
	var crop := PaperStage.ATLAS.get_image().get_region(Rect2i(PaperStage.COLUMN_REGION))
	var texture := ImageTexture.create_from_image(crop)
	var material := ShaderMaterial.new()
	material.shader = preload("res://assets/shaders/foreground_soft.gdshader")
	material.set_shader_parameter("artwork", texture)
	for index in 14:
		var card := Sprite3D.new()
		card.name = "NearColumn%d" % index
		card.texture = texture
		card.pixel_size = 0.008
		card.scale.y = 2.5
		card.position = Vector3(0.8 + index * 3.6, -2.0, 1.25)
		card.material_override = material
		card.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(card)
