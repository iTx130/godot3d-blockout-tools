@tool
class_name BlockoutMeshBuilder
extends RefCounted
## Geometry buffers in Godot local metres. Each three vertices form a triangle.

var vertices := PackedVector3Array()
var normals := PackedVector3Array()
var uvs := PackedVector2Array()
var collision_hulls: Array[PackedVector3Array] = []

func triangle(a: Vector3, b: Vector3, c: Vector3, na: Vector3, nb: Vector3, nc: Vector3, uv_a := Vector2.ZERO, uv_b := Vector2.ZERO, uv_c := Vector2.ZERO) -> void:
	var cross := (b - a).cross(c - a)
	if cross.length_squared() < 1e-18:
		return
	if cross.dot(na + nb + nc) > 0.0:
		vertices.append_array(PackedVector3Array([a, c, b]))
		normals.append_array(PackedVector3Array([na.normalized(), nc.normalized(), nb.normalized()]))
		uvs.append_array(PackedVector2Array([uv_a, uv_c, uv_b]))
	else:
		vertices.append_array(PackedVector3Array([a, b, c]))
		normals.append_array(PackedVector3Array([na.normalized(), nb.normalized(), nc.normalized()]))
		uvs.append_array(PackedVector2Array([uv_a, uv_b, uv_c]))

static func _project_uv(point: Vector3, normal: Vector3) -> Vector2:
	var axis := normal.abs()
	if axis.y >= axis.x and axis.y >= axis.z:
		return Vector2(point.x, -point.z)
	if axis.x >= axis.z:
		return Vector2(-point.z, point.y)
	return Vector2(point.x, point.y)

func face(points: PackedVector3Array, outward: Vector3) -> void:
	for i in range(1, points.size() - 1):
		var normal := (points[i] - points[0]).cross(points[i + 1] - points[0]).normalized()
		if normal.dot(outward) < 0.0:
			normal = -normal
		triangle(points[0], points[i], points[i + 1], normal, normal, normal, _project_uv(points[0], normal), _project_uv(points[i], normal), _project_uv(points[i + 1], normal))

func collider(points: PackedVector3Array) -> void:
	var unique := PackedVector3Array()
	for point in points:
		if point.is_finite() and not unique.has(point):
			unique.append(point)
	if unique.size() < 4:
		return
	var axis := unique[1] - unique[0]
	var plane := Vector3.ZERO
	for i in range(2, unique.size()):
		plane = axis.cross(unique[i] - unique[0])
		if plane.length_squared() > 1e-18:
			break
	for point in unique:
		if absf(plane.dot(point - unique[0])) > 1e-12:
			collision_hulls.append(unique)
			return

func solid(points: PackedVector3Array, faces: Array) -> void:
	if points.size() < 4:
		return
	var center := Vector3.ZERO
	for point in points:
		center += point
	center /= points.size()
	for indices in faces:
		var polygon := PackedVector3Array()
		var midpoint := Vector3.ZERO
		for index in indices:
			polygon.append(points[index])
			midpoint += points[index]
		face(polygon, midpoint / polygon.size() - center)
	collider(points)

func box(origin: Vector3, size: Vector3) -> void:
	var x := Vector3(size.x, 0, 0)
	var y := Vector3(0, size.y, 0)
	var z := Vector3(0, 0, -size.z)
	solid(PackedVector3Array([origin, origin+x, origin+x+y, origin+y, origin+z, origin+x+z, origin+x+y+z, origin+y+z]), [[0,1,2,3],[4,7,6,5],[0,4,5,1],[3,2,6,7],[0,3,7,4],[1,5,6,2]])

func make_array_mesh() -> ArrayMesh:
	var mesh := ArrayMesh.new()
	if vertices.is_empty():
		return mesh
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
