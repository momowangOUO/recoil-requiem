extends SceneTree

var checks := 0
var failures := 0

func _initialize() -> void: run.call_deferred()

func run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(640, 360)
	root.add_child(viewport)
	var camera := Camera3D.new()
	viewport.add_child(camera)
	camera.fov = CrimsonStage3D.CAMERA_FOV
	camera.far = 60
	var night := NightBackdrop.new()
	viewport.add_child(night)
	var extension := night.layer("CastleSilhouette9", preload("res://assets/environments/crimson/castle_v3.png"), Vector3(170,-5.1,-9), 20.0/1536.0)
	if extension.material_override == null or extension.material_override != night.get_node("CastleSilhouette0").material_override:
		push_error("Expanded-map castle cards must share the lower-edge haze material")
		failures += 1
	# Image-map bounds, old campaign bounds, and legacy fixture extremes.
	for point in [Vector2(0,-2080), Vector2(16384,-2080), Vector2(0,4120), Vector2(16384,4120), Vector2(9680,1540), Vector2(9592,932.8), Vector2(0,-160), Vector2(12000,2240), Vector2(0,-20), Vector2(4800,350)]:
		for profile in CrimsonStage3D.WEAPON_CAMERA.values():
			for distance in [profile.near, profile.far]:
				for yaw in [-0.32, 0.0, 0.32]:
					var target := CrimsonStage3D.to_stage(point)
					camera.position = target + Vector3(yaw, CrimsonStage3D.CAMERA_RISE, distance)
					camera.look_at(target)
					night.follow_camera(camera.position, camera)
					var covers := true
					for corner in [Vector2.ZERO, Vector2(640,0), Vector2(0,360), Vector2(640,360)]:
						var ray := camera.project_ray_normal(corner)
						var hit := camera.position + ray * ((night.sky.global_position.z - camera.position.z) / ray.z)
						var local := night.sky.to_local(hit)
						var half_size := night.sky.texture.get_size() * night.sky.pixel_size * 0.5
						covers = covers and absf(local.x) < half_size.x and absf(local.y) < half_size.y
					checks += 1
					if not covers: failures += 1
	viewport.free()
	print("SKY COVERAGE STAGE RESULT: %d camera poses, %d failures" % [checks, failures])
	quit(1 if failures else 0)
