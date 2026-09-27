extends Camera3D

var target := Vector3.ZERO
var distance := 23.0
var yaw := 0.42
var pitch := 0.64
var selected := -1

func _ready() -> void:
	_update()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		yaw -= event.relative.x * 0.006
		pitch = clampf(pitch + event.relative.y * 0.006,-1.4,1.4)
		_update()
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = maxf(1.0,distance*0.88)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = minf(60.0,distance/0.88)
		_update()
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB:
			selected = posmod(selected + (-1 if event.shift_pressed else 1),15)
			var shape: Node3D = get_parent().get_node("Shapes").get_child(selected)
			var bounds: AABB = shape.get_mesh().get_aabb()
			target = shape.to_global(bounds.get_center())
			distance = maxf(4.0,bounds.size.length()*2)
			get_parent().get_node("HUD/Help").text = _help(shape.name)
		elif event.keycode == KEY_R:
			selected = -1
			target = Vector3.ZERO
			distance = 23
			yaw = 0.42
			pitch = 0.64
			get_parent().get_node("HUD/Help").text = _help("All 15 original defaults")
		_update()

func _help(title: String) -> String:
	return "Blockout Tools | " + title + "\nRMB drag: orbit   Wheel: zoom   Tab / Shift+Tab: shape   R: overview"

func _update() -> void:
	position = target + Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))*distance
	look_at(target)
