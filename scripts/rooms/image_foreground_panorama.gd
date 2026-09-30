@tool
extends Node3D
## A painted near-plane panorama arranged as a short world-space strip. The
## cards recycle outside the view, but do not slide with every camera movement.

const PLANE_Z := 2.35
const BOTTOM_OVERSCAN := 0.16
const MAX_BOTTOM_OVERSCAN := 0.13
const CARD_WIDTH := 3.6
const TILE_SPACING := 3.34
const CARD_COUNT := 7
const GROUND_TELEPORT_THRESHOLD := 1.2
const GROUND_FOLLOW_MAX_STEP := 0.03
const MAX_BASE_ABOVE_GROUND := 0.15
const CLEAR_SCREEN_FRACTION := 0.72
const CONTOUR_TOP := 484 # v4 alpha above this row is discarded by the silhouette shader.
const TEXTURE := preload("res://assets/environments/crimson/foreground_panorama_v4.png")
const SILHOUETTE_SHADER := preload("res://assets/environments/crimson/foreground_silhouette.gdshader")

var cards: Array[Sprite3D] = []
var stage_host: Node
var anchored_bottom_y := 0.0
var anchored_ground_y := 0.0
var ground_anchor_ready := false
var last_player_y := 0.0
var player_position_ready := false
var contour_height := 0.0

func _ready() -> void:
	stage_host = get_parent().get_parent()
	var pixel_size := CARD_WIDTH / float(TEXTURE.get_width())
	contour_height = (TEXTURE.get_height() - CONTOUR_TOP) * pixel_size
	var silhouette_material := ShaderMaterial.new()
	silhouette_material.shader = SILHOUETTE_SHADER
	silhouette_material.set_shader_parameter("mask_texture", TEXTURE)
	silhouette_material.set_shader_parameter("silhouette_color", Color(0.035, 0.025, 0.055, 0.97))
	for index in CARD_COUNT:
		var card := Sprite3D.new()
		card.name = "PaintedNearWall%d" % index
		card.texture = TEXTURE
		card.pixel_size = pixel_size
		card.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
		card.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
		card.shaded = false
		card.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		card.material_override = silhouette_material
		card.modulate = Color.WHITE
		card.set_meta("world_anchored", true)
		card.set_meta("tile_width", TILE_SPACING)
		add_child(card)
		cards.append(card)

func follow_camera(view_camera: Camera3D) -> void:
	if cards.is_empty() or view_camera == null:
		return
	var viewport_size := view_camera.get_viewport().get_visible_rect().size
	var left_top := _on_plane(view_camera, Vector2.ZERO)
	var right_top := _on_plane(view_camera, Vector2(viewport_size.x, 0))
	var left_bottom := _on_plane(view_camera, Vector2(0, viewport_size.y))
	var right_bottom := _on_plane(view_camera, viewport_size)
	var left := minf(left_top.x, left_bottom.x)
	var right := maxf(right_top.x, right_bottom.x)
	var top := maxf(left_top.y, right_top.y)
	var bottom := minf(left_bottom.y, right_bottom.y)
	var view_height := top - bottom
	var card_height := cards[0].pixel_size * TEXTURE.get_height() * cards[0].scale.y
	var bottom_overscan := minf(view_height * BOTTOM_OVERSCAN, MAX_BOTTOM_OVERSCAN)
	var grounded_bottom := _grounded_bottom(bottom - bottom_overscan)
	# A remembered upper landing is not a physical wall in front of every lower
	# floor. Release it as soon as the descending view reaches the contour; do
	# not wait for ground contact and then animate a curtain through the player.
	var clear_y := viewport_size.y * CLEAR_SCREEN_FRACTION
	var player := _player()
	if player != null:
		var feet := view_camera.unproject_position(CrimsonStage3D.to_stage(player.position))
		clear_y = maxf(clear_y, feet.y + 4.0)
	var safe_bottom := minf(_on_plane(view_camera, Vector2(0, clear_y)).y,
		_on_plane(view_camera, Vector2(viewport_size.x, clear_y)).y) - contour_height
	if player != null and player.is_on_floor():
		grounded_bottom = maxf(grounded_bottom, bottom - bottom_overscan)
	grounded_bottom = minf(grounded_bottom, safe_bottom)
	anchored_ground_y += grounded_bottom - anchored_bottom_y
	anchored_bottom_y = grounded_bottom
	var extension := maxf(0.0, grounded_bottom - bottom + bottom_overscan)
	var material := cards[0].material_override as ShaderMaterial
	material.set_shader_parameter("base_extension", extension)
	material.set_shader_parameter("authored_height", card_height)
	var center_x := (left + right) * 0.5
	var center_tile := floori(center_x / TILE_SPACING)
	for index in cards.size():
		var tile := center_tile + index - cards.size() / 2
		cards[index].global_position = Vector3((tile + 0.5) * TILE_SPACING,
			grounded_bottom + card_height * 0.5, PLANE_Z)
		# Shader-deformed geometry must remain inside the CPU frustum-culling bounds.
		cards[index].custom_aabb = AABB(Vector3(-CARD_WIDTH * 0.5, -card_height * 0.5 - extension, -0.01),
			Vector3(CARD_WIDTH, card_height + extension, 0.02))

func reset_ground_anchor() -> void:
	ground_anchor_ready = false
	player_position_ready = false

func _grounded_bottom(screen_bottom: float) -> float:
	var player := _player()
	if player == null:
		if not ground_anchor_ready:
			anchored_bottom_y = screen_bottom
			ground_anchor_ready = true
		return anchored_bottom_y
	var ground_y := -player.position.y * 0.01
	var frame_delta := ground_y - last_player_y if player_position_ready else 0.0
	last_player_y = ground_y
	player_position_ready = true
	if not ground_anchor_ready:
		# Keep the authored crest below the actual landing plane, even when the
		# anchor was first created using the closest weapon camera.
		anchored_bottom_y = minf(screen_bottom, ground_y + MAX_BASE_ABOVE_GROUND)
		anchored_ground_y = ground_y
		ground_anchor_ready = true
		return anchored_bottom_y
	var target_bottom := anchored_bottom_y + ground_y - anchored_ground_y
	var next_bottom := advance_ground_anchor(anchored_bottom_y, target_bottom,
		player.is_on_floor(), absf(frame_delta) > GROUND_TELEPORT_THRESHOLD)
	anchored_ground_y += next_bottom - anchored_bottom_y
	anchored_bottom_y = next_bottom
	return anchored_bottom_y

func should_reanchor(grounded: bool, player_frame_delta: float) -> bool:
	return grounded or absf(player_frame_delta) > GROUND_TELEPORT_THRESHOLD

func advance_ground_anchor(current_bottom: float, target_bottom: float,
		grounded: bool, teleported: bool) -> float:
	if teleported:
		return target_bottom
	if not grounded:
		return current_bottom
	return move_toward(current_bottom, target_bottom, GROUND_FOLLOW_MAX_STEP)

func _player() -> CharacterBody2D:
	if not is_instance_valid(stage_host):
		return null
	var game_value: Variant = stage_host.get("game")
	if game_value == null:
		return null
	var player_value: Variant = game_value.get("player")
	return player_value as CharacterBody2D

func _on_plane(view_camera: Camera3D, screen: Vector2) -> Vector3:
	var origin := view_camera.project_ray_origin(screen)
	var direction := view_camera.project_ray_normal(screen)
	return origin + direction * ((PLANE_Z - origin.z) / direction.z)
