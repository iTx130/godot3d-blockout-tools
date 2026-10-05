extends SceneTree

const PLAYER := preload("res://addons/blockout_tools/nodes/player.tscn")
var failures: Array[String] = []
var tested := 0

func _initialize() -> void:
	call_deferred("_run")

func check(label: String, passed: bool) -> void:
	tested += 1
	if not passed:
		failures.append(label)
		push_error(label)

func _frames(count: int) -> void:
	for frame in count:
		await physics_frame
	await process_frame

func _key(code: Key, pressed: bool, echo: bool = false) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	event.echo = echo
	Input.parse_input_event(event)

func _body(stage: Node3D, size: Vector3, position: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	collision.shape = box
	body.add_child(collision)
	stage.add_child(body)
	body.position = position
	return body

func _run() -> void:
	var stage := Node3D.new()
	root.add_child(stage)
	current_scene = stage
	_body(stage, Vector3(40, 1, 40), Vector3(0, -0.5, 0))
	var configured := PLAYER.instantiate() as CharacterBody3D
	configured.set("perspective", 1)
	configured.set("view_height", 1.85)
	stage.add_child(configured)
	await _frames(3)
	check("exported initial third person activates correct camera", configured.get_node("Head/SpringArm3D/Camera3D").is_current())
	check("exported height is applied on start", is_equal_approx(configured.get_node("Head").position.y, 1.85))
	check("initial third person shows body", configured.get_node("BodyMesh").visible)
	configured.free()
	var player := PLAYER.instantiate() as CharacterBody3D
	check("body mesh visible in standalone scene before runtime", player.get_node("BodyMesh").visible)
	player.position = Vector3(0, 2, 0)
	stage.add_child(player)
	var head := player.get_node("Head") as Node3D
	var camera := player.get_node("Head/Camera3D") as Camera3D
	check("standalone scene instance", player.scene_file_path == PLAYER.resource_path)
	check("capsule collision", player.get_node("CollisionShape3D").shape is CapsuleShape3D)
	check("eye height", is_equal_approx(camera.global_position.y - player.global_position.y, 1.6))
	check("active first person camera", camera.is_current())
	check("captures mouse on start", Input.mouse_mode == Input.MOUSE_MODE_CAPTURED)
	check("first person hides body", not player.get_node("BodyMesh").visible)
	await _frames(90)
	check("gravity lands on floor at foot origin", player.is_on_floor() and absf(player.position.y) < 0.02)
	for code in [KEY_W, KEY_S, KEY_A, KEY_D]:
		# Mouse capture/release during the startup fixture can enqueue native motion.
		# These direction checks require a known pose, unlike the later mouse tests.
		player.rotation = Vector3.ZERO
		head.rotation = Vector3.ZERO
		var before := player.position
		_key(code, true)
		await _frames(12)
		_key(code, false)
		await _frames(2)
		var delta := player.position - before
		var direction: Vector3 = {KEY_W: Vector3.FORWARD, KEY_S: Vector3.BACK, KEY_A: Vector3.LEFT, KEY_D: Vector3.RIGHT}[code]
		check("physical key movement %d, displacement %s" % [code, delta], delta.dot(direction) > 0.8 and absf(delta.y) < 0.02)
	_key(KEY_W, true)
	_key(KEY_D, true)
	await _frames(4)
	check("diagonal speed is normalized", is_equal_approx(Vector2(player.velocity.x, player.velocity.z).length(), 5.0))
	_key(KEY_W, false)
	_key(KEY_D, false)
	await _frames(2)
	player.rotation.y = PI / 2.0
	head.rotation.x = deg_to_rad(70.0)
	var before_turn := player.position
	_key(KEY_W, true)
	await _frames(12)
	_key(KEY_W, false)
	await _frames(2)
	check("forward follows yaw and stays on ground when looking up", player.position.x < before_turn.x - 0.8 and absf(player.position.y) < 0.02)
	player.rotation = Vector3.ZERO
	head.rotation = Vector3.ZERO
	_key(KEY_SPACE, true)
	await _frames(3)
	check("space jumps from floor", player.position.y > 0.1 and player.velocity.y > 0.0)
	_key(KEY_SPACE, false)
	await _frames(1)
	var airborne_velocity := player.velocity.y
	_key(KEY_SPACE, true)
	await _frames(2)
	check("no air jump", player.velocity.y < airborne_velocity)
	_key(KEY_SPACE, false)
	await _frames(90)
	check("jump returns to floor", player.is_on_floor() and absf(player.position.y) < 0.02)
	_key(KEY_SPACE, true, true)
	await _frames(3)
	check("key repeat does not jump", player.is_on_floor())
	_key(KEY_SPACE, false)
	# Use actual physics collision, rather than asserting controller internals.
	player.position = Vector3(0, 0.01, 0)
	_body(stage, Vector3(10, 4, 1), Vector3(0, 2, -2))
	await _frames(3)
	_key(KEY_W, true)
	await _frames(45)
	_key(KEY_W, false)
	await _frames(2)
	check("wall blocks forward movement", player.position.z > -1.02 and player.position.z < -0.9)
	await _check_perspectives(stage, player)
	await _check_noclip(player)
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(100, -100000)
	Input.parse_input_event(motion)
	await _frames(2)
	check("mouse changes yaw", player.rotation.y < -0.29)
	check("pitch is limited above", head.rotation.x < PI / 2.0 and head.rotation.x > 1.5)
	motion = InputEventMouseMotion.new()
	motion.relative = Vector2(0, 100000)
	Input.parse_input_event(motion)
	await _frames(2)
	check("pitch is limited below", head.rotation.x > -PI / 2.0 and head.rotation.x < -1.5)
	_key(KEY_ESCAPE, true)
	await _frames(2)
	_key(KEY_ESCAPE, false)
	check("escape releases mouse", Input.mouse_mode == Input.MOUSE_MODE_VISIBLE)
	var before_pause := player.position
	_key(KEY_D, true)
	await _frames(12)
	_key(KEY_D, false)
	check("released mouse pauses movement", player.position.distance_to(before_pause) < 0.02)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	Input.parse_input_event(click)
	await _frames(2)
	check("left click recaptures mouse", Input.mouse_mode == Input.MOUSE_MODE_CAPTURED)
	click.pressed = false
	Input.parse_input_event(click)
	player.notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	check("focus loss releases mouse", Input.mouse_mode == Input.MOUSE_MODE_VISIBLE)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	stage.free()
	check("removing active player releases mouse", Input.mouse_mode == Input.MOUSE_MODE_VISIBLE)
	print("PLAYER RUNTIME: ", tested - failures.size(), "/", tested)
	quit(0 if failures.is_empty() else 1)

func _check_perspectives(stage: Node3D, player: CharacterBody3D) -> void:
	var head := player.get_node("Head") as Node3D
	var first_camera := player.get_node("Head/Camera3D") as Camera3D
	var third_camera := player.get_node("Head/SpringArm3D/Camera3D") as Camera3D
	var arm := player.get_node("Head/SpringArm3D") as SpringArm3D
	var body := player.get_node("BodyMesh") as MeshInstance3D
	player.position = Vector3(8, 0.01, 8)
	player.rotation = Vector3.ZERO
	head.rotation = Vector3.ZERO

	await _frames(3)
	_key(KEY_TAB, true)
	await _frames(3)
	_key(KEY_TAB, false)
	check("Tab switches to third person", third_camera.is_current() and not first_camera.is_current() and player.get("perspective") == 1)
	check("third person body is visible", body.visible)
	check("third person camera is behind player without hitting own capsule", is_equal_approx(arm.get_hit_length(), 3.0) and third_camera.global_position.z > player.global_position.z + 2.9)
	check("body mesh rests at feet and matches collider height", absf((body.mesh.get_aabb().position + body.position).y) < 0.001 and is_equal_approx(body.mesh.get_aabb().size.y, 2.0))
	_key(KEY_TAB, true, true)
	await _frames(2)
	_key(KEY_TAB, false)
	check("held Tab does not repeatedly switch", third_camera.is_current())
	player.set("view_height", 1.9)
	await _frames(2)
	check("height adjusts third person pivot and camera", is_equal_approx(head.position.y, 1.9) and absf(third_camera.global_position.y - player.global_position.y - 1.9) < 0.01)
	var back_wall := _body(stage, Vector3(2, 4, 0.4), Vector3(8, 2, 9.4))
	await _frames(5)
	check("spring arm retracts before wall", arm.get_hit_length() > 0.5 and arm.get_hit_length() < 1.3 and third_camera.global_position.z < 9.2)
	back_wall.free()
	await _frames(5)
	check("spring arm extends after obstruction removed", is_equal_approx(arm.get_hit_length(), 3.0))
	var before_move := player.position
	_key(KEY_W, true)
	await _frames(12)
	_key(KEY_W, false)
	await _frames(2)
	check("third person keeps forward movement", player.position.z < before_move.z - 0.8)
	_key(KEY_SPACE, true)
	await _frames(3)
	_key(KEY_SPACE, false)
	check("third person can jump", player.velocity.y > 0.0 and player.position.y > 0.1)
	await _frames(90)
	player.rotation.y = 0.3
	head.rotation.x = -0.25
	_key(KEY_TAB, true)
	await _frames(3)
	_key(KEY_TAB, false)
	check("Tab returns to first person and hides body", first_camera.is_current() and not third_camera.is_current() and not body.visible)
	check("switch preserves yaw and pitch", is_equal_approx(player.rotation.y, 0.3) and is_equal_approx(head.rotation.x, -0.25))
	check("first person stays at configured height without backward offset", first_camera.position.is_zero_approx() and is_equal_approx(first_camera.global_position.y - player.global_position.y, 1.9))
	player.set("perspective", 1)
	check("runtime exported perspective switches camera", third_camera.is_current())
	player.set("perspective", 0)
	player.set("view_height", 1.6)
	player.rotation = Vector3.ZERO
	head.rotation = Vector3.ZERO

func _check_noclip(player: CharacterBody3D) -> void:
	var head := player.get_node("Head") as Node3D
	var arm := player.get_node("Head/SpringArm3D") as SpringArm3D
	var original_layer := player.collision_layer
	var original_mask := player.collision_mask
	var original_arm_mask := arm.collision_mask
	# Restore custom masks, rather than assuming every user uses the defaults.
	player.collision_layer = 4
	player.collision_mask = 9
	arm.collision_mask = 17
	player.position = Vector3(0, 3, 0)
	player.rotation = Vector3.ZERO
	head.rotation = Vector3.ZERO
	_key(KEY_ALT, true)
	await _frames(3)
	_key(KEY_ALT, false)
	check("Alt disables player collision layers and masks", player.collision_layer == 0 and player.collision_mask == 0)
	check("noclip disables camera obstruction checks", arm.collision_mask == 0)
	var hover := player.position
	await _frames(12)
	check("noclip hovers without gravity", player.position.distance_to(hover) < 0.001)
	_key(KEY_ALT, true, true)
	await _frames(2)
	_key(KEY_ALT, false)
	check("held Alt does not repeatedly toggle flight", player.collision_mask == 0)
	head.rotation.x = 0.4
	var before_look := player.position
	_key(KEY_W, true)
	await _frames(12)
	_key(KEY_W, false)
	await _frames(2)
	check("flight follows camera pitch", player.position.y > before_look.y + 0.3 and player.position.z < before_look.z - 1.2)
	head.rotation = Vector3.ZERO
	player.position = Vector3(0, 1, 0)
	_key(KEY_W, true)
	await _frames(30)
	_key(KEY_W, false)
	await _frames(2)
	check("noclip passes through solid wall", player.position.z < -3.3)
	player.position = Vector3(0, 1, 0)
	_key(KEY_CTRL, true)
	await _frames(18)
	_key(KEY_CTRL, false)
	await _frames(2)
	check("Ctrl descends through solid floor", player.position.y < -0.8)
	var below_floor := player.position
	_key(KEY_SPACE, true)
	await _frames(18)
	_key(KEY_SPACE, false)
	await _frames(2)
	check("Space ascends through floor", player.position.y > below_floor.y + 2.0 and player.position.y > 0.5)
	_key(KEY_W, true)
	_key(KEY_D, true)
	_key(KEY_SPACE, true)
	await _frames(5)
	check("combined flight input has normalized speed", is_equal_approx(player.velocity.length(), 8.0))
	_key(KEY_W, false)
	_key(KEY_D, false)
	_key(KEY_SPACE, false)
	await _frames(3)
	player.position = Vector3(0, 1, -4)
	_key(KEY_TAB, true)
	await _frames(5)
	_key(KEY_TAB, false)
	check("Tab changes perspective while flying", player.get_node("Head/SpringArm3D/Camera3D").is_current() and player.collision_mask == 0)
	check("third person camera passes through wall during flight", is_equal_approx(arm.get_hit_length(), 3.0))
	var before_third := player.position
	_key(KEY_W, true)
	await _frames(12)
	_key(KEY_W, false)
	await _frames(2)
	check("third person can fly", player.position.z < before_third.z - 1.2)
	_key(KEY_ESCAPE, true)
	await _frames(3)
	_key(KEY_ESCAPE, false)
	var paused := player.position
	_key(KEY_W, true)
	_key(KEY_SPACE, true)
	await _frames(12)
	_key(KEY_W, false)
	_key(KEY_SPACE, false)
	check("released mouse pauses flight without falling", player.position.distance_to(paused) < 0.001)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	Input.parse_input_event(click)
	await _frames(2)
	click.pressed = false
	Input.parse_input_event(click)
	player.position = Vector3(0, 3, 3)
	var before_exit := player.position.y
	_key(KEY_ALT, true)
	await _frames(10)
	_key(KEY_ALT, false)
	check("Alt restores custom collision layers and masks", player.collision_layer == 4 and player.collision_mask == 9)
	check("Alt restores custom camera mask", arm.collision_mask == 17)
	check("leaving flight restores gravity", player.position.y < before_exit - 0.05 and player.velocity.y < 0.0)
	await _frames(90)
	check("leaving flight lands on floor", player.is_on_floor() and absf(player.position.y) < 0.02)
	player.position = Vector3(0, 0.01, 0)
	await _frames(5)
	_key(KEY_W, true)
	await _frames(45)
	_key(KEY_W, false)
	await _frames(2)
	check("leaving flight restores wall blocking", player.position.z > -1.02 and player.position.z < -0.9)
	_key(KEY_SPACE, true)
	await _frames(3)
	_key(KEY_SPACE, false)
	check("leaving flight restores normal jump", player.velocity.y > 0.0 and player.position.y > 0.1)
	await _frames(90)
	player.collision_layer = original_layer
	player.collision_mask = original_mask
	arm.collision_mask = original_arm_mask
	player.set("perspective", 0)
	player.position = Vector3(8, 0.01, 8)
	player.rotation = Vector3.ZERO
	head.rotation = Vector3.ZERO
	await _frames(3)
