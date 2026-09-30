extends CharacterBody3D
## Standalone first-/third-person blockout controller. The root origin is at the feet.
## Physical keys deliberately do not depend on the project's Input Map.

enum Perspective { FIRST_PERSON, THIRD_PERSON }

const MOVE_SPEED := 5.0
const JUMP_SPEED := 4.5
const MOUSE_SENSITIVITY := 0.003
const PITCH_LIMIT := deg_to_rad(89.0)
const THIRD_PERSON_DISTANCE := 3.0
const FLY_SPEED := 8.0

## Initial perspective; Tab changes this property at runtime as well.
@export var perspective: Perspective = Perspective.FIRST_PERSON:
	set(value):
		perspective = value
		if is_node_ready():
			_apply_perspective()

## Height above the foot origin, shared by both camera perspectives.
@export_range(0.1, 3.0, 0.01, "or_greater", "suffix:m") var view_height := 1.6:
	set(value):
		view_height = maxf(value, 0.1)
		if is_node_ready():
			head.position.y = view_height

@onready var head: Node3D = $Head
@onready var first_person_camera: Camera3D = $Head/Camera3D
@onready var third_person_camera: Camera3D = $Head/SpringArm3D/Camera3D
@onready var spring_arm: SpringArm3D = $Head/SpringArm3D
@onready var body_mesh: MeshInstance3D = $BodyMesh
@onready var camera: Camera3D = $Head/Camera3D

var _jump_requested := false
var _noclip_enabled := false
var _saved_collision_layer: int
var _saved_collision_mask: int
var _saved_spring_arm_mask: int

func _ready() -> void:
	head.position.y = view_height
	# The camera arm must hit the world, but never the player's own capsule.
	spring_arm.add_excluded_object(get_rid())
	spring_arm.collision_mask = collision_mask
	_apply_perspective()
	camera.make_current()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _apply_perspective() -> void:
	var was_current := camera.is_current()
	var third_person := perspective == Perspective.THIRD_PERSON
	camera = third_person_camera if third_person else first_person_camera
	body_mesh.visible = third_person
	spring_arm.spring_length = THIRD_PERSON_DISTANCE if third_person else 0.0
	# Editing an inactive player's properties must not take over another camera.
	if was_current:
		camera.make_current()

func _set_noclip(enabled: bool) -> void:
	if enabled == _noclip_enabled:
		return
	_noclip_enabled = enabled
	velocity = Vector3.ZERO
	_jump_requested = false
	if enabled:
		_saved_collision_layer = collision_layer
		_saved_collision_mask = collision_mask
		_saved_spring_arm_mask = spring_arm.collision_mask
		collision_layer = 0
		collision_mask = 0
		spring_arm.collision_mask = 0
	else:
		collision_layer = _saved_collision_layer
		collision_mask = _saved_collision_mask
		spring_arm.collision_mask = _saved_spring_arm_mask

func _unhandled_input(event: InputEvent) -> void:
	if not camera.is_current():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE or event.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			_jump_requested = false
			get_viewport().set_input_as_handled()
		elif event.physical_keycode == KEY_TAB:
			perspective = Perspective.THIRD_PERSON if perspective == Perspective.FIRST_PERSON else Perspective.FIRST_PERSON
			get_viewport().set_input_as_handled()
		elif event.physical_keycode == KEY_ALT and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			_set_noclip(not _noclip_enabled)
			get_viewport().set_input_as_handled()
		elif event.physical_keycode == KEY_SPACE and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			_jump_requested = not _noclip_enabled
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		head.rotation.x = clampf(head.rotation.x - event.relative.y * MOUSE_SENSITIVITY, -PITCH_LIMIT, PITCH_LIMIT)
		get_viewport().set_input_as_handled()

func _physics_process(delta: float) -> void:
	var input := Vector2.ZERO
	var controls_active := camera.is_current() and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	if controls_active:
		input = Vector2(
			float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
			float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
		).normalized()
	if _noclip_enabled:
		var flight_direction := Vector3.ZERO
		if controls_active:
			flight_direction = camera.global_basis * Vector3(input.x, 0.0, input.y)
			flight_direction += Vector3.UP * (float(Input.is_physical_key_pressed(KEY_SPACE)) - float(Input.is_physical_key_pressed(KEY_CTRL)))
		velocity = flight_direction.normalized() * FLY_SPEED
		# Direct movement deliberately bypasses CharacterBody3D collision and gravity.
		global_position += velocity * delta
		_jump_requested = false
		return
	if not is_on_floor():
		velocity += get_gravity() * delta
	if controls_active and _jump_requested and is_on_floor():
		velocity.y = JUMP_SPEED
	_jump_requested = false
	# Only yaw affects movement; looking up or down never makes the player fly.
	var direction := global_basis * Vector3(input.x, 0.0, input.y)
	direction.y = 0.0
	direction = direction.normalized()
	velocity.x = direction.x * MOVE_SPEED
	velocity.z = direction.z * MOVE_SPEED
	move_and_slide()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_jump_requested = false
		if is_instance_valid(camera) and camera.is_current():
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _exit_tree() -> void:
	if is_instance_valid(camera) and camera.is_current():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
