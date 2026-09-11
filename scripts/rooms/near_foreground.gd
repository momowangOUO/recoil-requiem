@tool
extends Node3D
## Origin is the highest coping stone; foundations continue below the frame.
@export_range(1.2, 2.2) var width := 1.6:
	set(value):
		width = value
		if is_inside_tree(): rebuild()
@export var end_pier := false:
	set(value):
		end_pier = value
		if is_inside_tree(): rebuild()

func _ready() -> void: rebuild()

func stone(region: Rect2i, tint: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = ImageTexture.create_from_image(PaperStage.ATLAS.get_image().get_region(region))
	mat.albedo_color = tint
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.roughness = 1.0
	mat.uv1_triplanar = true
	mat.uv1_world_triplanar = true
	mat.uv1_scale = Vector3(1.5, 1.5, 1.5)
	mat.set_meta("authored_texture", mat.albedo_texture)
	return mat

func block(label: String, at: Vector3, size: Vector3, mat: Material) -> void:
	var piece := MeshInstance3D.new()
	piece.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	piece.mesh = mesh
	piece.position = at
	piece.material_override = mat
	piece.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(piece)

func rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var face := stone(Rect2i(668, 42, 526, 62), Color("5b5267"))
	face.uv1_scale = Vector3(0.6, 5.0, 0.6)
	var cap := stone(Rect2i(48, 34, 548, 526), Color("72677c"))
	block("Foundation", Vector3(width * 0.5, -2.18, 0), Vector3(width, 4.0, 0.30), face)
	block("LeftCoping", Vector3(width * 0.19, -0.21 if end_pier else -0.09, 0), Vector3(width * 0.38, 0.18, 0.38), cap)
	block("BrokenCourse", Vector3(width * 0.50, -0.145, 0), Vector3(width * 0.24, 0.07, 0.31), face)
	block("RightCoping", Vector3(width * 0.81, -0.09, 0), Vector3(width * 0.38, 0.18, 0.38), cap)
	if end_pier:
		block("Pier", Vector3(0.14, -0.28, 0), Vector3(0.28, 0.56, 0.42), face)
		block("PierCap", Vector3(0.14, -0.04, 0), Vector3(0.34, 0.08, 0.46), cap)
