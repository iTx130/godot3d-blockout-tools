@tool
extends EditorNode3DGizmoPlugin

var history: EditorUndoRedoManager
const Shape = preload("blockout_shape.gd")
const Generator = preload("shape_generator.gd")
const MIN_SIZE := 0.01
const OPENING_HANDLES := 3
const BOX_CORNER_HANDLE := 3
const RAILING_LAYOUT_KEYS: Array[String] = ["railing_sections", "railing_section_length", "_railing_last_section_length"]
const ROUNDED_PROPERTIES: Array[String] = [
	"box_size", "cone_radius", "cone_height", "cylinder_radius", "cylinder_height",
	"corner_curved_radius", "corner_curved_height", "ramp_width", "ramp_depth", "ramp_height",
	"doorway_width", "doorway_height", "doorway_depth", "side_thickness", "top_thickness", "bottom_thickness",
	"railing_section_length", "railing_skew_elevation", "railing_height", "_railing_last_section_length", "skewbox_endpoint", "skewbox_start_size", "skewbox_end_size",
	"sphere_radius", "stairs_size", "step_width", "step_depth", "step_height",
	"step_depth_spacing", "step_height_spacing", "stairs_inner_radius", "stairs_height",
	"tube_radius", "tube_thickness", "tube_height",
]


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
		0: return [["box_size",0],["box_size",1],["box_size",2],["box_size",0]]
		1: return [["cone_radius",0],["cone_height",1]]
		2: return [["corner_curved_radius",0],["corner_curved_height",1]]
		3,7: return [["ramp_width",0],["ramp_depth",2],["ramp_height",1]]
		4: return [["cylinder_radius",0],["cylinder_height",1]]
		5: return [
			["doorway_depth",2],["doorway_width",0],["doorway_height",1],
			["side_thickness",0],["side_thickness",0],["top_thickness",1],
		]
		6: return [["railing_section_length",2],["railing_skew_elevation",1],["railing_height",1]]
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

static func _is_opening_handle(node: Node, id: int) -> bool:
	return node.shape_type in [Shape.ShapeType.DOORWAY, Shape.ShapeType.WINDOW] and id >= OPENING_HANDLES

static func _is_box_corner_handle(node: Node, id: int) -> bool:
	return node.shape_type == Shape.ShapeType.BOX and id == BOX_CORNER_HANDLE

static func _handle_axis(node: Node, id: int) -> Vector3:
	if _is_box_corner_handle(node, id):
		return Vector3.ZERO
	var entry: Array = _handles(node)[id]
	var axis := Vector3.ZERO
	# Depth is a positive extent along -Z. Endpoints are signed coordinates.
	axis[entry[1]] = -1.0 if entry[1] == 2 and entry[0] != "skewbox_endpoint" else 1.0
	return axis

static func _railing_elevation_distance(distances: PackedFloat64Array) -> float:
	var total := distances[distances.size() - 1]
	if distances.size() == 2:
		return total
	var middle := distances[1]
	for i in range(2, distances.size() - 1):
		if absf(distances[i] - total * 0.5) < absf(middle - total * 0.5) - 0.000000001:
			middle = distances[i]
	return middle

static func _handle_position(node: Node, id: int) -> Vector3:
	var entry: Array = _handles(node)[id]
	var point := Vector3.ZERO
	if _is_box_corner_handle(node, id):
		var size: Vector3 = _rounded_value(node.box_size) if node.round_size else node.box_size
		return Vector3(maxf(size.x, 0.001), maxf(size.y, 0.001), -maxf(size.z, 0.001))
	if node.shape_type == Shape.ShapeType.RAILING:
		var distances := Generator.railing_joint_distances(node)
		var total := distances[distances.size() - 1]
		var elevation := _dimension(node, "railing_skew_elevation")
		var height := Generator.railing_height(node)
		if id == 2:
			return Vector3(0, height, 0)
		if id == 0:
			return Vector3(0, elevation, -total)
		var distance := _railing_elevation_distance(distances)
		return Vector3(0, height + elevation * distance / total, -distance)
	if _is_opening_handle(node, id):
		var width := _dimension(node, "doorway_width")
		var ceiling := _dimension(node, "doorway_height") - _dimension(node, "top_thickness")
		var sill := _dimension(node, "bottom_thickness") if node.shape_type == Shape.ShapeType.WINDOW else 0.0
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
	if node.shape_type in [Shape.ShapeType.DOORWAY, Shape.ShapeType.WINDOW]:
		var left := positions[3].x
		var right := positions[4].x
		var top := positions[5].y
		var bottom := positions[6].y if node.shape_type == Shape.ShapeType.WINDOW else 0.0
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
	if _is_box_corner_handle(gizmo.get_node_3d(), id):
		return "Box width/depth [Godot X/-Z]"
	if _is_opening_handle(gizmo.get_node_3d(), id):
		if gizmo.get_node_3d().shape_type == Shape.ShapeType.DOORWAY:
			return ["Doorway opening width (left)", "Doorway opening width (right)", "Doorway opening top"][id - OPENING_HANDLES]
		return [
			"Window opening width (left)", "Window opening width (right)",
			"Window opening top", "Window sill height",
			"Window opening elevation (keep size)",
		][id - OPENING_HANDLES]
	var entry: Array = _handles(gizmo.get_node_3d())[id]
	var sign_prefix := "-" if _handle_axis(gizmo.get_node_3d(), id)[entry[1]] < 0 else ""
	return str(entry[0]) + " [Godot " + sign_prefix + ["X","Y","Z"][entry[1]] + "]"

func _get_handle_value(gizmo: EditorNode3DGizmo, _id: int, _secondary: bool) -> Variant:
	return _geometry_snapshot(gizmo.get_node_3d())

static func _rounded_properties(node: Node) -> Array[String]:
	var properties: Array[String] = []
	for property: String in ROUNDED_PROPERTIES:
		if node.shape_type in Shape.PROPERTY_SHAPES[property]:
			properties.append(property)
	return properties

static func _geometry_snapshot(node: Node) -> Dictionary:
	var result := {"round_size": node.round_size}
	if node.shape_type == Shape.ShapeType.RAILING:
		result["railing_sections"] = node.railing_sections
	for property in _rounded_properties(node):
		result[property] = node.get(property)
	return result

static func _rounded_value(value: Variant) -> Variant:
	if value is Vector3:
		return (value * 100.0 + Vector3.ONE * 0.5).floor() / 100.0
	if value is Vector2:
		return (value * 100.0 + Vector2.ONE * 0.5).floor() / 100.0
	return floorf(float(value) * 100.0 + 0.5) / 100.0

func _set_handle(gizmo: EditorNode3DGizmo, id: int, _secondary: bool, camera: Camera3D, screen_pos: Vector2) -> void:
	var node := gizmo.get_node_3d()
	if absf(node.global_basis.determinant()) < 0.000000001:
		return
	var inverse := node.global_transform.affine_inverse()
	var origin := inverse * camera.project_ray_origin(screen_pos)
	var step: float = _editor_grid_snap_step() * node.grid_snap_ratio
	if _is_box_corner_handle(node, id):
		var direction := inverse.basis * camera.project_ray_normal(screen_pos)
		var point: Variant = _box_corner_ray_point(origin, direction, _handle_position(node, id).y)
		if point != null:
			var grid_transform := _box_grid_transform(node, EditorInterface.get_edited_scene_root()) if step > 0.0 else Transform3D.IDENTITY
			_apply_box_corner_size(node, Vector2(point.x, -point.z), grid_transform, step)
		return
	var axis := _handle_axis(node, id)
	var end := inverse * (camera.project_ray_origin(screen_pos) + camera.project_ray_normal(screen_pos)*10000)
	# Opening handles slide along an axis through the handle, not the node origin.
	var handle_position := _handle_position(node, id)
	var axis_origin := handle_position - axis * handle_position.dot(axis)
	var closest := Geometry3D.get_closest_points_between_segments(axis_origin-axis*1000,axis_origin+axis*1000,origin,end)
	var coordinate: float = closest[0].dot(axis)
	if step > 0.0:
		var grid_transform := _box_grid_transform(node, EditorInterface.get_edited_scene_root())
		coordinate = _snap_handle_coordinate(node, id, coordinate, grid_transform, step)
		_apply_grid_handle_size(node, id, _coordinate_to_size(node, id, coordinate))
		return
	_apply_handle_size(node, id, _coordinate_to_size(node, id, coordinate))

static func _box_corner_ray_point(origin: Vector3, direction: Vector3, height: float) -> Variant:
	if not origin.is_finite() or not direction.is_finite() or absf(direction.y) <= direction.length() * 0.000001:
		return null
	var distance := (height - origin.y) / direction.y
	if distance < 0.0 or not is_finite(distance):
		return null
	var point := origin + direction * distance
	return point if point.is_finite() else null

static func _snap_box_corner_size(grid_transform: Transform3D, height: float, size: Vector2, step: float) -> Vector2:
	if step <= 0.0 or not is_finite(step):
		return size
	var width_axis := grid_transform.basis * Vector3.RIGHT
	var depth_axis := grid_transform.basis * Vector3.FORWARD
	# Solve two independent grid planes together; sequential axis snaps can
	# undo each other on a rotated box. Drop the least informative coordinate.
	var omitted := width_axis.cross(depth_axis).abs().max_axis_index()
	var first := (omitted + 1) % 3
	var second := (omitted + 2) % 3
	var determinant := width_axis[first] * depth_axis[second] - width_axis[second] * depth_axis[first]
	if not is_finite(determinant) or absf(determinant) <= width_axis.length() * depth_axis.length() * 0.000000001:
		return size
	var origin := grid_transform * Vector3(0, height, 0)
	var point := origin + width_axis * size.x + depth_axis * size.y
	var a := snappedf(point[first], step) - origin[first]
	var b := snappedf(point[second], step) - origin[second]
	var width := (a * depth_axis[second] - b * depth_axis[first]) / determinant
	var depth := (width_axis[first] * b - width_axis[second] * a) / determinant
	return Vector2(maxf(width, MIN_SIZE), maxf(depth, MIN_SIZE))

static func _apply_box_corner_size(node: Node, size: Vector2, grid_transform: Transform3D = Transform3D.IDENTITY, step: float = 0.0) -> void:
	if not size.is_finite():
		return
	var point := _handle_position(node, BOX_CORNER_HANDLE)
	if size.distance_to(Vector2(point.x, -point.z)) < 0.00001:
		return
	size = Vector2(maxf(size.x, MIN_SIZE), maxf(size.y, MIN_SIZE))
	var use_grid := step > 0.0 and is_finite(step)
	var value: Vector3 = node.box_size
	if use_grid:
		size = _snap_box_corner_size(grid_transform, point.y, size, step)
		if node.round_size:
			value = _rounded_value(value)
	elif node.round_size:
		size = (size * 100.0 + Vector2.ONE * 0.5).floor() / 100.0
	value.x = size.x
	value.z = size.y
	if use_grid:
		_apply_grid_handle_changes(node, BOX_CORNER_HANDLE, {"box_size": value})
	else:
		node.box_size = value

static func _coordinate_to_size(node: Node, id: int, coordinate: float) -> float:
	if node.shape_type == Shape.ShapeType.RAILING and id == 1:
		var distances := Generator.railing_joint_distances(node)
		# The middle post rises by only its fraction of the end elevation.
		return (coordinate - Generator.railing_height(node)) * distances[distances.size() - 1] / _railing_elevation_distance(distances)
	if node.shape_type == Shape.ShapeType.STAIRS_CURVED and _handles(node)[id][0] == "step_width":
		return coordinate - _dimension(node, "stairs_inner_radius")
	return coordinate

func _editor_grid_snap_step() -> float:
	# These editor APIs include Ctrl's temporary toggle and Shift's fine step.
	if Engine.is_editor_hint() and EditorInterface.is_node_3d_snap_enabled():
		return EditorInterface.get_node_3d_translate_snap()
	return 0.0

static func _box_grid_transform(node: Node3D, scene_root: Node) -> Transform3D:
	if scene_root is Node3D and (scene_root == node or scene_root.is_ancestor_of(node)):
		if absf(scene_root.global_basis.determinant()) >= 0.000000001:
			return scene_root.global_transform.affine_inverse() * node.global_transform
	# A plain Node scene root has no spatial transform: its grid is world space.
	return node.global_transform

static func _grid_handle_limits(node: Node, id: int) -> Vector2:
	if _is_opening_handle(node, id):
		var width := _dimension(node, "doorway_width")
		var height := _dimension(node, "doorway_height")
		var top := _dimension(node, "top_thickness")
		var bottom := _dimension(node, "bottom_thickness") if node.shape_type == Shape.ShapeType.WINDOW else 0.0
		var side_limit := minf((width - MIN_SIZE) / 2.0, width * 0.49)
		match id:
			3: return Vector2(MIN_SIZE, side_limit)
			4: return Vector2(width - side_limit, width - MIN_SIZE)
			5: return Vector2(maxf(bottom + MIN_SIZE, height * 0.01), height - MIN_SIZE)
			6: return Vector2(MIN_SIZE, height - top - MIN_SIZE)
			7:
				var opening := height - top - bottom
				return Vector2(opening / 2.0 + maxf(MIN_SIZE, height * 0.01 - opening), height - opening / 2.0 - MIN_SIZE)
	var property: String = _handles(node)[id][0]
	if node.shape_type == Shape.ShapeType.RAILING and id == 0:
		return Vector2(MIN_SIZE, 256.0)
	if node.shape_type == Shape.ShapeType.RAILING and id == 2:
		return Vector2(Generator.RAILING_MIN_HEIGHT, Generator.RAILING_MAX_HEIGHT)
	if property in ["skewbox_endpoint", "railing_skew_elevation"]:
		return Vector2(-INF, INF)
	if node.shape_type == Shape.ShapeType.STAIRS_CURVED and property == "step_width":
		return Vector2(_dimension(node, "stairs_inner_radius") + MIN_SIZE, INF)
	return Vector2(MIN_SIZE, INF)

static func _snap_axis_coordinate(grid_transform: Transform3D, axis_origin: Vector3, direction: Vector3, coordinate: float, step: float, limits: Vector2) -> float:
	if step <= 0.0 or not is_finite(step) or limits.x > limits.y:
		return coordinate
	var movement := grid_transform.basis * direction
	var component := movement.abs().max_axis_index()
	var speed := movement[component]
	if absf(speed) < 0.000000001:
		return coordinate
	var origin: float = (grid_transform * axis_origin)[component]
	var first_coordinate := origin + speed * limits.x
	var last_coordinate := origin + speed * limits.y
	var lower := minf(first_coordinate, last_coordinate)
	var upper := maxf(first_coordinate, last_coordinate)
	# Epsilon only resolves floating point noise at an existing grid plane.
	var first_plane := ceilf(lower / step - 0.000001) * step if is_finite(lower) else -INF
	var last_plane := floorf(upper / step + 0.000001) * step if is_finite(upper) else INF
	if first_plane > last_plane:
		# A narrow opening may contain no legal grid plane: keep its constraints.
		return clampf(coordinate, limits.x, limits.y)
	var plane := snappedf(origin + speed * clampf(coordinate, limits.x, limits.y), step)
	plane = clampf(plane, first_plane, last_plane)
	return clampf((plane - origin) / speed, limits.x, limits.y)

static func _snap_handle_coordinate(node: Node, id: int, coordinate: float, grid_transform: Transform3D, step: float) -> float:
	if node.shape_type == Shape.ShapeType.RAILING and id == 1 and step > 0.0 and is_finite(step):
		var distances := Generator.railing_joint_distances(node)
		var total := distances[distances.size() - 1]
		var fraction := _railing_elevation_distance(distances) / total
		var height := Generator.railing_height(node)
		var elevation := (coordinate - height) / fraction
		# Snap the far bottom edge, not the middle post's top.
		var snapped_elevation := _snap_axis_coordinate(grid_transform, Vector3(0,0,-total), Vector3.UP, elevation, step, Vector2(-INF,INF))
		if absf(elevation) <= absf(elevation - snapped_elevation):
			snapped_elevation = 0.0
		return height + snapped_elevation * fraction
	var axis := _handle_axis(node, id)
	var point := _handle_position(node, id)
	var axis_origin := point - axis * point.dot(axis)
	var snapped := _snap_axis_coordinate(grid_transform, axis_origin, axis, coordinate, step, _grid_handle_limits(node, id))
	if node.shape_type == Shape.ShapeType.RAILING and id == 2 and step > 0.0 and is_finite(step):
		# Keep the one-layer minimum reachable between scene-grid planes.
		if absf(coordinate - Generator.RAILING_MIN_HEIGHT) <= absf(coordinate - snapped):
			return Generator.RAILING_MIN_HEIGHT
	return snapped

static func _snap_box_extent(grid_transform: Transform3D, id: int, size: float, step: float) -> float:
	var direction := Vector3.ZERO
	direction[id] = -1.0 if id == 2 else 1.0
	return _snap_axis_coordinate(grid_transform, Vector3.ZERO, direction, size, step, Vector2(MIN_SIZE, INF))

static func _apply_grid_handle_size(node: Node, id: int, size: float) -> void:
	_apply_grid_handle_changes(node, id, _handle_changes(node, id, size, false))

static func _apply_grid_handle_changes(node: Node, id: int, values: Dictionary) -> void:
	if values.is_empty():
		return
	var precise := false
	for value in values.values():
		var rounded: Variant = _rounded_value(value)
		if value is Vector3 or value is Vector2:
			precise = precise or value.distance_to(rounded) > 0.000001
		else:
			precise = precise or absf(float(value) - float(rounded)) > 0.000001
	if node.round_size and precise:
		# All dimensions currently rounded by the generator must keep their
		# visible values when exact snapping disables centimetre rounding.
		var dimensions := {}
		for property in _rounded_properties(node):
			dimensions[property] = _rounded_value(node.get(property))
		_assign_properties(node, dimensions)
		node.round_size = false
	elif node.round_size:
		# A centimetre-aligned edit leaves untouched raw vector components intact.
		var entry: Array = _handles(node)[id]
		var property: String = entry[0]
		if values.has(property) and values[property] is Vector3:
			var vector: Vector3 = node.get(property)
			if _is_box_corner_handle(node, id):
				vector.x = values[property].x
				vector.z = values[property].z
			else:
				vector[entry[1]] = values[property][entry[1]]
			values[property] = vector
	_assign_properties(node, values)

static func _apply_box_grid_size(node: Node3D, id: int, size: float) -> void:
	_apply_grid_handle_size(node, id, size)

static func _bounded_size(node: Node, value: float, maximum: float, rounded: bool = true) -> float:
	if rounded and node.round_size:
		value = floorf(value * 100 + 0.5) / 100
		maximum = floorf(maximum * 100 + 0.00001) / 100
	return clampf(value, MIN_SIZE, maxf(MIN_SIZE, maximum))

static func _handle_changes(node: Node, id: int, size: float, rounded: bool = true) -> Dictionary:
	if node.shape_type == Shape.ShapeType.RAILING and id == 0:
		size = clampf(size, MIN_SIZE, 256.0)
		if rounded and node.round_size:
			size = floorf(size * 100 + 0.5) / 100
		var distances := Generator.railing_joint_distances(node)
		if absf(size - distances[distances.size() - 1]) < 0.000001:
			return {}
		var count := clampi(ceili(size), 1, 256)
		return {
			"railing_sections": count,
			"railing_section_length": 1.0,
			"_railing_last_section_length": size - float(count - 1),
		}
	if node.shape_type == Shape.ShapeType.RAILING and id == 2:
		size = clampf(size, Generator.RAILING_MIN_HEIGHT, Generator.RAILING_MAX_HEIGHT)
	if _is_opening_handle(node, id):
		var width := _dimension(node, "doorway_width")
		var height := _dimension(node, "doorway_height")
		var top := _dimension(node, "top_thickness")
		var bottom := _dimension(node, "bottom_thickness") if node.shape_type == Shape.ShapeType.WINDOW else 0.0
		match id:
			3, 4:
				if width >= MIN_SIZE * 3:
					return {"side_thickness": _bounded_size(node, size if id == 3 else width - size, (width - MIN_SIZE) / 2, rounded)}
			5:
				if height - bottom >= MIN_SIZE * 2:
					return {"top_thickness": _bounded_size(node, height - size, height - bottom - MIN_SIZE, rounded)}
			6:
				if height - top >= MIN_SIZE * 2:
					return {"bottom_thickness": _bounded_size(node, size, height - top - MIN_SIZE, rounded)}
			7:
				var opening_height := height - top - bottom
				if opening_height >= MIN_SIZE and top + bottom >= MIN_SIZE * 2:
					var new_bottom := _bounded_size(node, size - opening_height / 2, top + bottom - MIN_SIZE, rounded)
					return {"bottom_thickness": new_bottom, "top_thickness": top + bottom - new_bottom}
		return {}
	var entry: Array = _handles(node)[id]
	if entry[0] not in ["skewbox_endpoint", "railing_skew_elevation"]:
		size = maxf(size, MIN_SIZE)
	if rounded and node.round_size:
		size = floorf(size * 100 + 0.5) / 100
	var value: Variant = node.get(entry[0])
	if value is Vector3:
		if not rounded and node.round_size:
			value = _rounded_value(value)
		value[entry[1]] = size
	else:
		value = size
	return {entry[0]: value}

static func _apply_handle_size(node: Node, id: int, size: float) -> void:
	_assign_properties(node, _handle_changes(node, id, size))

## Writes properties, applying the railing span layout atomically so the result
## never depends on dictionary key order.
static func _assign_properties(node: Node, values: Dictionary) -> void:
	var has_layout := false
	for key in RAILING_LAYOUT_KEYS:
		has_layout = has_layout or values.has(key)
	if has_layout:
		node.set_railing_layout(
			int(values.get("railing_sections", node.railing_sections)),
			float(values.get("railing_section_length", node.railing_section_length)),
			float(values.get("_railing_last_section_length", node._railing_last_section_length)))
	for key in values:
		if key not in RAILING_LAYOUT_KEYS:
			node.set(key, values[key])

func _commit_handle(gizmo: EditorNode3DGizmo, id: int, _secondary: bool, restore: Variant, cancel: bool) -> void:
	var node := gizmo.get_node_3d()
	var property: String = _handles(node)[id][0]
	var previous: Dictionary = restore if restore is Dictionary else {property: restore}
	if cancel:
		_assign_properties(node, previous)
	elif history != null:
		history.create_action("Resize Blockout " + property)
		var has_layout := false
		for key in RAILING_LAYOUT_KEYS:
			has_layout = has_layout or previous.has(key)
		if has_layout:
			history.add_do_method(node, "set_railing_layout", node.railing_sections, node.railing_section_length, node._railing_last_section_length)
			history.add_undo_method(node, "set_railing_layout",
				int(previous.get("railing_sections", node.railing_sections)),
				float(previous.get("railing_section_length", node.railing_section_length)),
				float(previous.get("_railing_last_section_length", node._railing_last_section_length)))
		for key in previous:
			if key not in RAILING_LAYOUT_KEYS:
				history.add_do_property(node, key, node.get(key))
				history.add_undo_property(node, key, previous[key])
		history.commit_action()
