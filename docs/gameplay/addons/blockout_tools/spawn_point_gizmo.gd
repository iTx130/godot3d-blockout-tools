@tool
extends EditorNode3DGizmoPlugin

const SPAWN := preload("nodes/spawn_point.gd")

func _init() -> void:
	create_material("enabled", Color(0.25, 1.0, 0.45))
	create_material("disabled", Color(0.55, 0.55, 0.55))

func _has_gizmo(node: Node3D) -> bool:
	var script: Script = node.get_script()
	return script != null and script.resource_path == (SPAWN as Script).resource_path

func _get_gizmo_name() -> String:
	return "BlockoutSpawnPoint"

func _redraw(gizmo: EditorNode3DGizmo) -> void:
	gizmo.clear()
	var spawn := gizmo.get_node_3d() as BlockoutSpawnPoint
	# Match runtime heading even under rotated/scaled parents.
	var preview_transform := spawn.global_transform.affine_inverse() * spawn.get_spawn_transform()
	var lines := SPAWN.preview_lines()
	for i in lines.size():
		lines[i] = preview_transform * lines[i]
	gizmo.add_lines(lines, get_material("enabled" if spawn.enabled else "disabled", gizmo))
	gizmo.add_collision_segments(lines)
