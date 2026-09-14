extends Node2D
var actor: ShieldEnemy
static var manifest: Dictionary = {}
static var textures: Dictionary = {}
var stride := 0.0
var death_time := 0.0
var idle_time := 0.0
var frame := 0
var previous_state := -1

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var keyed := ShaderMaterial.new()
	keyed.shader = preload("res://assets/characters/requiem/chroma_key.gdshader")
	material = keyed
	if manifest.is_empty():
		manifest = preload("res://assets/characters/campaign/manifest_data.gd").DATA
	var kind: String = actor.archetype
	if not textures.has(kind): textures[kind] = load(manifest[kind].path)

func _physics_process(delta: float) -> void:
	if not actor.can_process(): return
	material.set_shader_parameter("hit_flash",0.0 if actor.state == ShieldEnemy.State.DEAD else clampf(actor.hit_flash / 0.06,0,1))
	if actor.state != previous_state:
		if actor.state == ShieldEnemy.State.DEAD: death_time = 0
		previous_state = actor.state
	if actor.state == ShieldEnemy.State.DEAD:
		death_time += delta
		frame = 6 if death_time < 0.13 else (5 if death_time < 0.27 else 7)
	elif actor.hurt_stun > 0:
		frame = 6
	else:
		match actor.state:
			ShieldEnemy.State.APPROACH:
				var speed: float = (actor.velocity - actor.knockback_velocity).length()
				if speed > 8 or actor.archetype == "flyer":
					stride += delta * maxf(speed / 70.0,0.5) * 7
					frame = 1 + int(stride) % 2
				else:
					idle_time += delta
					frame = 0
			ShieldEnemy.State.WINDUP: frame = 3
			ShieldEnemy.State.ATTACK: frame = 4
			ShieldEnemy.State.RECOVERY: frame = 5
	queue_redraw()

func frame_layout() -> Dictionary:
	var kind: String = actor.archetype
	var data: Dictionary = manifest[kind]
	var pose: Dictionary = data.frames[frame]
	var region := Rect2(pose.region[0],pose.region[1],pose.region[2],pose.region[3])
	var anchor := Vector2(pose.anchor[0],pose.anchor[1])
	var size_scale: float = data.scale
	return {"texture":textures[kind],"region":region,"destination":Rect2(((region.position-anchor)*size_scale).round(),region.size*size_scale)}

func _draw() -> void:
	if not is_instance_valid(actor) or manifest.is_empty(): return
	var layout := frame_layout()
	draw_set_transform(Vector2.ZERO,0,Vector2(-1 if cos(actor.facing_angle)<0 else 1,1))
	draw_texture_rect_region(layout.texture,layout.destination,layout.region)
