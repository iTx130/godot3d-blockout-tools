extends SceneTree

const PLAYER := preload("res://addons/blockout_tools/nodes/player.tscn")
const SPAWN := preload("res://addons/blockout_tools/nodes/spawn_point.tscn")
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
	# Packed fixture: Player comes before SpawnPoint and the main scene has not
	# been assigned yet, as can happen during a real scene's _ready traversal.
	var fixture := Node3D.new()
	fixture.name = "SpawnFixture"
	var actor := PLAYER.instantiate() as CharacterBody3D
	actor.position = Vector3(20, 3, 20)
	fixture.add_child(actor)
	actor.owner = fixture
	var spawn := SPAWN.instantiate() as BlockoutSpawnPoint
	spawn.position = Vector3(3, 0, 4)
	spawn.rotation.y = PI / 2.0
	fixture.add_child(spawn)
	spawn.owner = fixture
	var packed := PackedScene.new()
	check("fixture packs", packed.pack(fixture) == OK)
	fixture.free()
	var stage := packed.instantiate() as Node3D
	root.add_child(stage)
	current_scene = stage
	actor = stage.get_child(0) as CharacterBody3D
	spawn = stage.get_child(1) as BlockoutSpawnPoint
	actor.set_physics_process(false)
	check("player before spawn sibling starts at world foot position", actor.global_position.is_equal_approx(Vector3(3, 0, 4)))
	check("yaw follows arrow toward negative X", (-actor.global_basis.z).is_equal_approx(Vector3.LEFT))
	check("first person camera points toward negative X", (-actor.get_node("Head/Camera3D").global_basis.z).is_equal_approx(Vector3.LEFT))
	check("camera remains at eye height", is_equal_approx(actor.get_node("Head/Camera3D").global_position.y, 1.6))
	check("spawn contains capsule collision", spawn.get_node("CollisionShape3D").shape is CapsuleShape3D)
	check("spawn capsule cannot block or trigger gameplay", spawn.collision_layer == 0 and spawn.collision_mask == 0 and not spawn.monitoring and not spawn.monitorable)
	check("no spawn meshes render at runtime", spawn.find_children("*", "MeshInstance3D", true, false).is_empty())
	check("no additional player was generated", stage.find_children("*", "CharacterBody3D", true, false).size() == 1)
	stage.free()
	current_scene = null

	stage = Node3D.new()
	root.add_child(stage)
	current_scene = stage
	actor = PLAYER.instantiate() as CharacterBody3D
	actor.position = Vector3(7, 2, -8)
	actor.rotation.y = -0.7
	stage.add_child(actor)
	actor.set_physics_process(false)
	check("no spawn preserves authored position", actor.position.is_equal_approx(Vector3(7, 2, -8)))
	check("no spawn preserves authored heading", is_equal_approx(actor.rotation.y, -0.7))
	actor.free()
	spawn = SPAWN.instantiate() as BlockoutSpawnPoint
	spawn.enabled = false
	spawn.position = Vector3(-50, 0, 40)
	stage.add_child(spawn)
	actor = PLAYER.instantiate() as CharacterBody3D
	actor.position = Vector3(7, 2, -8)
	actor.rotation.y = -0.7
	stage.add_child(actor)
	actor.set_physics_process(false)
	check("disabled-only point preserves entire pose", actor.position.is_equal_approx(Vector3(7, 2, -8)) and is_equal_approx(actor.rotation.y, -0.7))
	actor.free()

	var parent := Node3D.new()
	parent.position = Vector3(10, 0, 5)
	parent.rotation.y = PI / 2.0
	stage.add_child(parent)
	var nested := SPAWN.instantiate() as BlockoutSpawnPoint
	nested.position = Vector3(2, 0, -3)
	nested.rotation = Vector3(0.4, 0.5, 0.2)
	nested.scale = Vector3(2, 2, 2)
	parent.add_child(nested)
	var later := SPAWN.instantiate() as BlockoutSpawnPoint
	later.position = Vector3(100, 0, 100)
	stage.add_child(later)
	var actor_parent := Node3D.new()
	actor_parent.position = Vector3(-7, 0, 8)
	actor_parent.rotation.y = -0.6
	stage.add_child(actor_parent)
	actor = PLAYER.instantiate() as CharacterBody3D
	actor.set("perspective", 1)
	actor_parent.add_child(actor)
	actor.set_physics_process(false)
	check("nested spawn uses independently calculated world position", actor.global_position.is_equal_approx(Vector3(7, 0, 3)))
	var expected_forward := -nested.global_basis.z
	expected_forward.y = 0
	expected_forward = expected_forward.normalized()
	check("world yaw survives different actor and spawn parents", (-actor.global_basis.z).is_equal_approx(expected_forward))
	check("spawn pitch and roll leave player upright", actor.global_basis.y.is_equal_approx(Vector3.UP))
	check("spawn scale does not resize player", actor.global_basis.get_scale().is_equal_approx(Vector3.ONE))
	check("third person pivot starts at horizontal spawn heading", actor.get_node("Head").rotation.is_zero_approx() and (-actor.get_node("Head/SpringArm3D/Camera3D").global_basis.z).is_equal_approx(expected_forward))
	check("third person remains selected", actor.get_node("Head/SpringArm3D/Camera3D").is_current())
	var before := actor.global_transform
	nested.enabled = false
	check("toggling during play does not teleport existing player", actor.global_transform.is_equal_approx(before))
	actor.free()
	actor = PLAYER.instantiate() as CharacterBody3D
	actor_parent.add_child(actor)
	actor.set_physics_process(false)
	check("new player skips disabled nested point", actor.global_position.is_equal_approx(Vector3(100, 0, 100)))
	actor.free()
	later.enabled = false
	spawn.enabled = true
	actor = PLAYER.instantiate() as CharacterBody3D
	actor_parent.add_child(actor)
	actor.set_physics_process(false)
	check("re-enabled first point takes priority", actor.global_position.is_equal_approx(Vector3(-50, 0, 40)))
	stage.free()
	current_scene = null

	# Spawn is scoped to the player's active scene, not unrelated viewport trees.
	var unrelated := Node3D.new()
	root.add_child(unrelated)
	unrelated.add_child(SPAWN.instantiate())
	stage = Node3D.new()
	root.add_child(stage)
	current_scene = stage
	actor = PLAYER.instantiate() as CharacterBody3D
	actor.position = Vector3(9, 2, 3)
	stage.add_child(actor)
	actor.set_physics_process(false)
	check("unrelated scene spawn is ignored", actor.position.is_equal_approx(Vector3(9, 2, 3)))
	stage.free()
	unrelated.free()
	current_scene = null
	# Real physics fixture: the matching marker capsule must not trap Player.
	stage = Node3D.new()
	root.add_child(stage)
	current_scene = stage
	var floor_body := StaticBody3D.new()
	var floor_collision := CollisionShape3D.new()
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(40, 1, 40)
	floor_collision.shape = floor_shape
	floor_body.position.y = -0.5
	floor_body.add_child(floor_collision)
	stage.add_child(floor_body)
	spawn = SPAWN.instantiate() as BlockoutSpawnPoint
	spawn.position = Vector3(3, 0, 4)
	spawn.rotation.y = PI / 2.0
	stage.add_child(spawn)
	actor = PLAYER.instantiate() as CharacterBody3D
	stage.add_child(actor)
	await _frames(12)
	check("spawned player lands on the floor without marker interference", actor.is_on_floor() and absf(actor.global_position.y) < 0.02)
	actor.rotation.y = PI / 2.0
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var event := InputEventKey.new()
	event.physical_keycode = KEY_W
	event.pressed = true
	Input.parse_input_event(event)
	await _frames(12)
	event = InputEventKey.new()
	event.physical_keycode = KEY_W
	event.pressed = false
	Input.parse_input_event(event)
	check("W moves toward the spawn arrow", actor.global_position.x < 2.2 and absf(actor.global_position.z - 4.0) < 0.05)
	check("spawn marker does not obstruct movement", actor.is_on_floor() and is_equal_approx(actor.velocity.length(), 5.0))
	stage.free()
	current_scene = null
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var report := {"tested":tested,"passed":tested - failures.size(),"failures":failures}
	var file := FileAccess.open("res://tests/evidence/spawn-runtime.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  "))
	print("SPAWN RUNTIME: ", report.passed, "/", tested)
	quit(0 if failures.is_empty() else 1)

func _frames(count: int) -> void:
	for frame in count:
		await physics_frame
	await process_frame
