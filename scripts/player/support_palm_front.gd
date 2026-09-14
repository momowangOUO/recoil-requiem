extends Node2D
## Only the visible portion of the far palm may wrap in front of the gun.
var rig: Node2D
func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var mask := ShaderMaterial.new()
	mask.shader = preload("res://assets/characters/requiem/support_palm_mask.gdshader")
	material = mask
func _process(_delta: float) -> void: queue_redraw()
func _draw() -> void:
	if not is_instance_valid(rig.actor): return
	if rig.actor.melee.active(): return
	var weapon: WeaponRuntime = rig.actor.weapons.current()
	var index := 1 if weapon.data.id == &"shotgun" else (2 if weapon.data.id == &"smg" else 0)
	if index == 0 or weapon.reloading: return
	var body: Dictionary = rig.body_layout()
	material.set_shader_parameter("body_atlas",body.atlas)
	material.set_shader_parameter("body_source",Vector4(body.region.position.x,body.region.position.y,body.region.size.x,body.region.size.y))
	material.set_shader_parameter("body_destination",Vector4(body.dest.position.x,body.dest.position.y,body.dest.size.x,body.dest.size.y))
	material.set_shader_parameter("facing",rig.actor.facing)
	material.set_shader_parameter("near_atlas",rig.FIRING_ARMS[index])
	material.set_shader_parameter("muzzle",rig.MUZZLES[index])
	material.set_shader_parameter("aim_angle",rig.actor.aim_direction.angle())
	material.set_shader_parameter("hit_flash",clampf(rig.actor.hit_flash / 0.06,0,1))
	var pose: Dictionary = rig.left_pose(index,rig.actor.aim_direction,-1)
	var region: Rect2 = rig.LEFT_HAND[index]
	var vertices := PackedVector2Array()
	var uv := PackedVector2Array()
	for corner in [region.position,Vector2(region.end.x,region.position.y),region.end,Vector2(region.position.x,region.end.y)]:
		vertices.append(pose.palm+rig._oriented((corner-rig.LEFT_PALMS[index])*rig.ARM_SCALE,pose.angle))
		uv.append(corner/rig.SUPPORT_ARMS[index].get_size())
	draw_polygon(vertices,PackedColorArray([Color.WHITE,Color.WHITE,Color.WHITE,Color.WHITE]),uv,rig.SUPPORT_ARMS[index])
