extends SceneTree

var tested := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(label: String, passed: bool) -> void:
	tested += 1
	if not passed:
		failures.append(label)
		push_error(label)

func _run() -> void:
	var suite := "all"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--suite="):
			suite = argument.trim_prefix("--suite=")
	if suite not in ["all", "shape", "gameplay"]:
		push_error("Unknown cold-install suite: " + suite)
		quit(1)
		return
	var stage := Node3D.new()
	root.add_child(stage)
	current_scene = stage
	check("isolated_from_development_tests", not DirAccess.dir_exists_absolute("res://tests"))
	if suite in ["all", "shape"]:
		await _shape_checks(stage)
	if suite in ["all", "gameplay"]:
		_gameplay_checks(stage)
	var report := {"suite":suite,"engine":Engine.get_version_info().string,"tested":tested,"passed":tested-failures.size(),"failures":failures,"project_path":ProjectSettings.globalize_path("res://")}
	var file := FileAccess.open("res://cold-result.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	print("COLD INSTALL: ",report.passed,"/",tested)
	stage.free()
	quit(0 if failures.is_empty() else 1)

func _shape_checks(stage: Node3D) -> void:
	var Shape = load("res://addons/blockout_tools/blockout_shape.gd")
	for kind in range(15):
		var shape = Shape.new()
		shape.shape_type = kind
		stage.add_child(shape)
		await process_frame
		await process_frame
		check("shape_%d_mesh"%kind,shape.get_mesh()!=null and shape.get_mesh().get_surface_count()==1)
		check("shape_%d_collision"%kind,shape.get_node("BlockoutCollision/CollisionShape").shape!=null)
		var packed := PackedScene.new()
		check("shape_%d_parameter_only_save"%kind,packed.pack(shape)==OK and packed.get_state().get_node_count()==1)
		shape.free()
	var gallery := (load("res://demo/blockout_gallery.tscn") as PackedScene).instantiate()
	stage.add_child(gallery)
	await process_frame
	await process_frame
	check("gallery_has_15_shapes",gallery.get_node("Shapes").get_child_count()==15)

func _gameplay_checks(stage: Node3D) -> void:
	var Player = load("res://addons/blockout_tools/nodes/player.tscn") as PackedScene
	var Spawn = load("res://addons/blockout_tools/nodes/spawn_point.tscn") as PackedScene
	var player := Player.instantiate()
	stage.add_child(player)
	check("player_available_in_addon_only_install", player is CharacterBody3D and player.scene_file_path == Player.resource_path)
	check("player_camera_available", player.get_node("Head/Camera3D").is_current())
	check("player_collision_available", player.get_node("CollisionShape3D").shape is CapsuleShape3D)
	check("third_person_available", player.has_node("Head/SpringArm3D/Camera3D") and player.has_node("BodyMesh"))
	var spawn := Spawn.instantiate() as BlockoutSpawnPoint
	spawn.position = Vector3(4, 0, 6)
	spawn.rotation.y = PI / 2.0
	stage.add_child(spawn)
	var spawned := Player.instantiate() as CharacterBody3D
	stage.add_child(spawned)
	check("spawn_available_in_addon_only_install", spawn.scene_file_path == Spawn.resource_path and spawn.enabled)
	check("cold_player_uses_spawn_position", spawned.global_position.is_equal_approx(Vector3(4, 0, 6)))
	check("cold_player_uses_spawn_heading", (-spawned.global_basis.z).is_equal_approx(Vector3.LEFT))
