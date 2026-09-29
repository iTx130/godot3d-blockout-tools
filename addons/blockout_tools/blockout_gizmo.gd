@tool
extends EditorNode3DGizmoPlugin

var history: EditorUndoRedoManager
const Shape = preload("blockout_shape.gd")
const MIN_SIZE := 0.01
const WINDOW_OPENING_HANDLES := 3

func _init() -> void:
	create_material("outline", Color(1.0, 0.65, 0.18, 0.6))
	create_material("opening_outline", Color(0.2, 0.85, 1.0, 0.8))
	create_handle_material("handles")

func _has_gizmo(node: Node3D) -> bool:
	# Existing scenes can retain a stale script class object after the plugin is
	# reloaded. Match the script resource path as a compatibility fallback so
	# their handles become available again without recreating the nodes.
	if node is Shape:
		return true
	var script: Script = node.get_script()
	return script != null and script.resource_path == (Shape as Script).resource_path

func _get_gizmo_name() -> String:
	return "BlockoutShape"

static func _handles(node: Node) -> Array:
	match node.shape_type:
		0: return [["box_size",0],["box_size",1],["box_size",2]]
		1: return [["cone_radius",0],["cone_height",1]]
		2: return [["corner_curved_radius",0],["corner_curved_height",1]]
		3,7: return [["ramp_width",0],["ramp_depth",2],["ramp_height",1]]
		4: return [["cylinder_radius",0],["cylinder_height",1]]
		5: return [["doorway_depth",2],["doorway_width",0],["doorway_height",1]]
		6: return [["railing_section_length",2],["railing_skew_elevation",1]]
		8: return [["skewbox_endpoint",0],["skewbox_endpoint",1],["skewbox_endpoint",2]]
		9: return [["sphere_radius",0]]
		10: return [["stairs_inner_radius",2],["step_width",2],["stairs_height",1]]
		11: return [["stairs_size",0],["stairs_size",1],["stairs_size",2]]
		12: return [["step_width",0],["step_depth",2],["step_height",1]]
		13: return [["tube_radius",0],["tube_height",1]]
		14: return [
			["doorway_depth",2],["doorway_width",0],["doorway_height",1],
			["side_thickness",0],["side_thickness",0],
			["top_thickness",1],["bottom_thickness",1],["opening_elevation",1],
		]
	return []

static func _dimension(node: Node, property: String) -> float:
	var value: float = node.get(property)
	return floorf(value * 100 + 0.5) / 100 if node.round_size else value

static func _is_window_opening_handle(node: Node, id: int) -> bool:
	return node.shape_type == Shape.ShapeType.WINDOW and id >= WINDOW_OPENING_HANDLES

static func _handle_axis(node: Node, id: int) -> Vector3:
	var entry: Array = _handles(node)[id]
	var axis := Vector3.ZERO
	# Depth is a positive extent along -Z. Endpoints are signed coordinates.
	axis[entry[1]] = -1.0 if entry[1] == 2 and entry[0] != "skewbox_endpoint" else 1.0
	return axis

static func _handle_position(node: Node, id: int) -> Vector3:
	var entry: Array = _handles(node)[id]
	var point := Vector3.ZERO
	if _is_window_opening_handle(node, id):
		var width := _dimension(node, "doorway_width")
		var ceiling := _dimension(node, "doorway_height") - _dimension(node, "top_thickness")
		var sill := _dimension(node, "bottom_thickness")
		point = Vector3(width / 2, (sill + ceiling) / 2, 0)
		match id:
			3: point.x = _dimension(node, "side_thickness")
			4: point.x = width - _dimension(node, "side_thickness")
			5: point.y = ceiling
			6: point.y = sill
	else:
		var value: Variant = node.get(entry[0])
		var size: float = value[entry[1]] if value is Vector3 else float(value)
		if node.round_size:
			size = floorf(size * 100 + 0.5) / 100
		if node.shape_type == Shape.ShapeType.STAIRS_CURVED and entry[0] == "step_width":
			size += _dimension(node, "stairs_inner_radius")
		point = _handle_axis(node, id) * size
	return point

func _redraw(gizmo: EditorNode3DGizmo) -> void:
	gizmo.clear()
	var node := gizmo.get_node_3d()
	var mesh: Mesh = node.get_mesh()
	if mesh != null and mesh.get_surface_count() > 0:
		gizmo.add_collision_triangles(mesh.generate_triangle_mesh())
	var positions := PackedVector3Array()
	for id in range(_handles(node).size()):
		positions.append(_handle_position(node, id))
	gizmo.add_handles(positions,get_material("handles",gizmo),[])
	if node.shape_type == Shape.ShapeType.WINDOW:
		var left := positions[3].x
		var right := positions[4].x
		var top := positions[5].y
		var bottom := positions[6].y
		var corners := PackedVector3Array([
			Vector3(left, bottom, 0), Vector3(left, top, 0),
			Vector3(right, top, 0), Vector3(right, bottom, 0),
		])
		var lines := PackedVector3Array()
		for i in range(4):
			lines.append(corners[i])
			lines.append(corners[(i + 1) % 4])
		gizmo.add_lines(lines, get_material("opening_outline", gizmo))

func _get_handle_name(gizmo: EditorNode3DGizmo, id: int, _secondary: bool) -> String:
	if _is_window_opening_handle(gizmo.get_node_3d(), id):
		return [
			"Window opening width (left)", "Window opening width (right)",
			"Window opening top", "Window sill height",
			"Window opening elevation (keep size)",
		][id - WINDOW_OPENING_HANDLES]
	var entry: Array = _handles(gizmo.get_node_3d())[id]
	var sign_prefix := "-" if _handle_axis(gizmo.get_node_3d(), id)[entry[1]] < 0 else ""
	return str(entry[0]) + " [Godot " + sign_prefix + ["X","Y","Z"][entry[1]] + "]"

func _get_handle_value(gizmo: EditorNode3DGizmo, id: int, _secondary: bool) -> Variant:
	var node := gizmo.get_node_3d()
	if _is_window_opening_handle(node, id) and id == 7:
		return {"top_thickness": node.top_thickness, "bottom_thickness": node.bottom_thickness}
	return node.get(_handles(node)[id][0])

func _set_handle(gizmo: EditorNode3DGizmo, id: int, _secondary: bool, camera: Camera3D, screen_pos: Vector2) -> void:
	var node := gizmo.get_node_3d()
	var axis := _handle_axis(node, id)
	var inverse := node.global_transform.affine_inverse()
	var origin := inverse * camera.project_ray_origin(screen_pos)
	var end := inverse * (camera.project_ray_origin(screen_pos) + camera.project_ray_normal(screen_pos)*10000)
	# Opening handles slide along an axis through the handle, not the node origin.
	var handle_position := _handle_position(node, id)
	var axis_origin := handle_position - axis * handle_position.dot(axis)
	var closest := Geometry3D.get_closest_points_between_segments(axis_origin-axis*1000,axis_origin+axis*1000,origin,end)
	var size: float = closest[0].dot(axis)
	if node.shape_type == Shape.ShapeType.STAIRS_CURVED and _handles(node)[id][0] == "step_width":
		size -= _dimension(node, "stairs_inner_radius")
	_apply_handle_size(node, id, size)

static func _bounded_size(node: Node, value: float, maximum: float) -> float:
	if node.round_size:
		value = floorf(value * 100 + 0.5) / 100
		maximum = floorf(maximum * 100 + 0.00001) / 100
	return clampf(value, MIN_SIZE, maxf(MIN_SIZE, maximum))

static func _apply_handle_size(node: Node, id: int, size: float) -> void:
	if _is_window_opening_handle(node, id):
		var width := _dimension(node, "doorway_width")
		var height := _dimension(node, "doorway_height")
		var top := _dimension(node, "top_thickness")
		var bottom := _dimension(node, "bottom_thickness")
		match id:
			3, 4:
				if width >= MIN_SIZE * 3:
					node.side_thickness = _bounded_size(node, size if id == 3 else width - size, (width - MIN_SIZE) / 2)
			5:
				if height - bottom >= MIN_SIZE * 2:
					node.top_thickness = _bounded_size(node, height - size, height - bottom - MIN_SIZE)
			6:
				if height - top >= MIN_SIZE * 2:
					node.bottom_thickness = _bounded_size(node, size, height - top - MIN_SIZE)
			7:
				var opening_height := height - top - bottom
				if opening_height >= MIN_SIZE and top + bottom >= MIN_SIZE * 2:
					var new_bottom := _bounded_size(node, size - opening_height / 2, top + bottom - MIN_SIZE)
					node.bottom_thickness = new_bottom
					node.top_thickness = top + bottom - new_bottom
		return
	var entry: Array = _handles(node)[id]
	if entry[0] not in ["skewbox_endpoint","railing_skew_elevation"]:
		size = maxf(size,0.01)
	if node.round_size:
		size = floorf(size*100+0.5)/100
	var value: Variant = node.get(entry[0])
	if value is Vector3:
		value[entry[1]] = size
	else:
		value = size
	node.set(entry[0],value)

func _commit_handle(gizmo: EditorNode3DGizmo, id: int, _secondary: bool, restore: Variant, cancel: bool) -> void:
	var node := gizmo.get_node_3d()
	var property: String = _handles(node)[id][0]
	var previous: Dictionary = restore if restore is Dictionary else {property: restore}
	if cancel:
		for key in previous:
			node.set(key, previous[key])
	elif history != null:
		history.create_action("Resize Blockout " + property)
		for key in previous:
			history.add_do_property(node, key, node.get(key))
			history.add_undo_property(node, key, previous[key])
		history.commit_action()
