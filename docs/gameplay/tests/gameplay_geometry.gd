extends SceneTree

var checks: Array = []

func _initialize() -> void:
	call_deferred("_run")

func check(label: String, passed: bool) -> void:
	checks.append({"check": label, "passed": passed})
	if not passed:
		push_error(label)

func _close(actual: float, expected: float) -> bool:
	return absf(actual - expected) <= maxf(0.00001, absf(expected) * 0.0001)

func _spawn_geometry_checks() -> void:
	var scene := preload("res://addons/blockout_tools/nodes/spawn_point.tscn")
	var spawn := scene.instantiate() as BlockoutSpawnPoint
	var collision := spawn.get_node("CollisionShape3D") as CollisionShape3D
	var capsule := collision.shape as CapsuleShape3D
	check("spawn_capsule_radius_matches_player", _close(capsule.radius, 0.5))
	check("spawn_capsule_height_matches_player", _close(capsule.height, 2.0))
	check("spawn_capsule_foot_origin", _close(collision.position.y - capsule.height / 2.0, 0.0))
	var lines := BlockoutSpawnPoint.preview_lines()
	check("spawn_preview_line_pairs", lines.size() > 8 and lines.size() % 2 == 0)
	var bounds := AABB(lines[0], Vector3.ZERO)
	for point in lines:
		bounds = bounds.expand(point)
	check("spawn_preview_capsule_height", _close(bounds.position.y, 0.0) and _close(bounds.end.y, 2.0))
	check("spawn_preview_capsule_width", _close(bounds.position.x, -0.5) and _close(bounds.end.x, 0.5))
	var horizontal := true
	for i in range(lines.size() - 8, lines.size()):
		horizontal = horizontal and _close(lines[i].y, 1.0)
	check("spawn_arrow_horizontal", horizontal)
	check("spawn_arrow_forward_tip", lines[lines.size() - 7].is_equal_approx(Vector3(0, 1, -1.8)))
	root.add_child(spawn)
	for pitch in [0.0, 0.4, PI / 2.0]:
		spawn.rotation = Vector3(pitch, 0.7, 0.0)
		spawn.scale = Vector3(2, 3, 4)
		var pose := spawn.get_spawn_transform()
		check("spawn_pose_upright_%s" % pitch, pose.basis.y.is_equal_approx(Vector3.UP))
		check("spawn_pose_scale_free_%s" % pitch, pose.basis.get_scale().is_equal_approx(Vector3.ONE))
		check("spawn_pose_yaw_%s" % pitch, (-pose.basis.z).is_equal_approx(Vector3(-sin(0.7), 0, -cos(0.7))))
	spawn.free()

func _run() -> void:
	_spawn_geometry_checks()
	var failed: Array = checks.filter(func(c): return not c.passed)
	var report := {"engine": Engine.get_version_info().string, "tested": checks.size(), "passed": checks.size() - failed.size(), "failures": failed, "checks": checks}
	var file := FileAccess.open("res://tests/evidence/godot-gameplay-geometry.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  "))
	print("GAMEPLAY GEOMETRY: ", report.passed, "/", report.tested)
	quit(0 if failed.is_empty() else 1)