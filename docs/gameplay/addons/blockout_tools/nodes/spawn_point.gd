@tool
extends Area3D
class_name BlockoutSpawnPoint
## Foot origin; local -Z is forward. The capsule marks clearance, never blocks.

@export var enabled := true:
	set(value):
		enabled = value
		if Engine.is_editor_hint() and is_inside_tree():
			update_gizmos()

func _ready() -> void:
	if Engine.is_editor_hint():
		set_notify_transform(true)

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED and Engine.is_editor_hint():
		update_gizmos()

func get_spawn_transform() -> Transform3D:
	# Use world heading only, keeping the player upright and at its own scale.
	var forward := -global_basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.000001:
		var right := global_basis.x
		right.y = 0.0
		forward = Vector3.UP.cross(right)
	if forward.length_squared() < 0.000001:
		forward = Vector3.FORWARD
	return Transform3D(Basis.looking_at(forward.normalized(), Vector3.UP), global_position)

static func find_enabled(scene_root: Node) -> BlockoutSpawnPoint:
	# Depth-first scene order works before sibling _ready callbacks have run.
	if scene_root is BlockoutSpawnPoint and scene_root.enabled:
		return scene_root
	for child in scene_root.get_children():
		var spawn := find_enabled(child)
		if spawn != null:
			return spawn
	return null

static func preview_lines() -> PackedVector3Array:
	var lines := PackedVector3Array()
	# Capsule radius 0.5, height 2.0: four meridians and two rings.
	for axis in 2:
		for side in [-1.0, 1.0]:
			var radial := Vector3(side * 0.5, 0, 0) if axis == 0 else Vector3(0, 0, side * 0.5)
			lines.append_array([radial + Vector3.UP * 0.5, radial + Vector3.UP * 1.5])
		for cap in 2:
			for segment in 16:
				for angle in [PI * segment / 16.0, PI * (segment + 1) / 16.0]:
					var radial := Vector3(cos(angle) * 0.5, 0, 0) if axis == 0 else Vector3(0, 0, cos(angle) * 0.5)
					lines.append(radial + Vector3.UP * ((1.5 + sin(angle) * 0.5) if cap == 0 else (0.5 - sin(angle) * 0.5)))
	for height in [0.5, 1.5]:
		for segment in 32:
			for angle in [TAU * segment / 32.0, TAU * (segment + 1) / 32.0]:
				lines.append(Vector3(cos(angle) * 0.5, height, sin(angle) * 0.5))
	# Horizontal arrow at waist height, with a wide arrowhead along -Z.
	lines.append_array([
		Vector3(0, 1, 0), Vector3(0, 1, -1.8),
		Vector3(0, 1, -1.8), Vector3(-0.4, 1, -1.25),
		Vector3(0, 1, -1.8), Vector3(0.4, 1, -1.25),
		Vector3(-0.4, 1, -1.25), Vector3(0.4, 1, -1.25),
	])
	return lines
