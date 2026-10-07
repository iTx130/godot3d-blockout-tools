@tool
extends RefCounted
## Parametric solids generated directly in Godot local XYZ, measured in metres.

const Builder = preload("blockout_mesh.gd")
const HEX_FACES = [[0,1,2,3],[4,7,6,5],[0,4,5,1],[3,2,6,7],[0,3,7,4],[1,5,6,2]]
const RAILING_LAYER_STEP := 0.5
const RAILING_MIN_HEIGHT := RAILING_LAYER_STEP
const RAILING_MAX_HEIGHT := RAILING_LAYER_STEP * 256.0

static func _q(value: float, rounded: bool) -> float:
	return floorf(value * 100.0 + 0.5) / 100.0 if rounded else value

static func _length(value: float, rounded: bool) -> float:
	return maxf(_q(value, rounded), 0.001)

static func _size(value: Vector3, rounded: bool) -> Vector3:
	var result := (value * 100.0 + Vector3.ONE * 0.5).floor() / 100.0 if rounded else value
	return Vector3(maxf(result.x, 0.001), maxf(result.y, 0.001), maxf(result.z, 0.001))

static func _size2(value: Vector2, rounded: bool) -> Vector2:
	var result := (value * 100.0 + Vector2.ONE * 0.5).floor() / 100.0 if rounded else value
	return Vector2(maxf(result.x, 0.001), maxf(result.y, 0.001))

static func _segments(quality: int) -> int:
	return 8 * clampi(quality, 1, 4)

static func _ring(radius: float, angle: float, height: float = 0.0) -> Vector3:
	var x := cos(angle)
	var z := -sin(angle)
	return Vector3(0.0 if absf(x) < 1e-7 else radius*x, height, 0.0 if absf(z) < 1e-7 else radius*z)

static func generate(p: Node) -> BlockoutMeshBuilder:
	var b := Builder.new()
	var rounded: bool = p.round_size
	match p.shape_type:
		0:
			b.box(Vector3.ZERO, _size(p.box_size, rounded))
		1, 4:
			var cone: bool = p.shape_type == 1
			_round_solid(b, _length(p.cone_radius if cone else p.cylinder_radius, rounded), _length(p.cone_height if cone else p.cylinder_height, rounded), _segments(p.quality), cone)
		2:
			_corner(b, _length(p.corner_curved_radius, rounded), _length(p.corner_curved_height, rounded), 2 * clampi(p.corner_curved_quality, 1, 4), p.corner_curved_inner)
		3:
			var w := _length(p.ramp_width, rounded)
			var h := _length(p.ramp_height, rounded)
			var d := _length(p.ramp_depth, rounded)
			b.solid(PackedVector3Array([Vector3.ZERO,Vector3(w,0,0),Vector3(w,0,-d),Vector3(0,0,-d),Vector3(w,h,-d)]), [[0,3,2,1],[0,1,4],[1,2,4],[2,3,4],[3,0,4]])
		5, 14:
			_opening(b, p)
		6:
			_railing(b, p)
		7:
			var d := _length(p.ramp_depth, rounded)
			var h := _length(p.ramp_height, rounded)
			_profile(b, PackedVector2Array([Vector2.ZERO,Vector2(d,0),Vector2(d,h)]), _length(p.ramp_width, rounded), Vector3.ZERO)
		8:
			_skewbox(b, p)
		9:
			_sphere(b, _length(p.sphere_radius, rounded), _segments(p.sphere_quality), p.sphere_hemisphere)
		10:
			_curved_stairs(b, p)
		11, 12:
			_linear_stairs(b, p)
		13:
			_tube(b, p)
	return b

static func _column(b: BlockoutMeshBuilder, footprint: PackedVector2Array, bottom: float, top: float) -> void:
	var polygon := PackedVector2Array()
	for point in footprint:
		if not polygon.has(point):
			polygon.append(point)
	var n := polygon.size()
	if n < 3 or top <= bottom:
		return
	var points := PackedVector3Array()
	for height in [bottom, top]:
		for point in polygon:
			points.append(Vector3(point.x, height, point.y))
	var faces: Array = [range(n), range(n, n*2)]
	for i in range(n):
		var next := (i + 1) % n
		faces.append([i,next,next+n,i+n])
	b.solid(points, faces)

static func _profile(b: BlockoutMeshBuilder, profile: PackedVector2Array, width: float, origin: Vector3) -> void:
	var points := PackedVector3Array()
	var n := profile.size()
	for x in [0.0, width]:
		for point in profile:
			points.append(origin + Vector3(x, point.y, -point.x))
	var faces: Array = [range(n), range(n,n*2)]
	for i in range(n):
		var next := (i+1)%n
		faces.append([i,next,next+n,i+n])
	b.solid(points, faces)

static func _round_solid(b: BlockoutMeshBuilder, radius: float, height: float, segments: int, cone: bool) -> void:
	var hull := PackedVector3Array()
	var peak := Vector3(0,height,0)
	for i in range(segments):
		var t0 := TAU * float(i) / segments
		var t1 := TAU * float(i+1) / segments
		var a := _ring(radius,t0)
		var c := _ring(radius,t1)
		var na := _ring(1.0,t0)
		var nc := _ring(1.0,t1)
		hull.append(a)
		b.face(PackedVector3Array([Vector3.ZERO,a,c]), Vector3.DOWN)
		var u0 := float(i)/segments
		var u1 := float(i+1)/segments
		if cone:
			na.y = radius/height
			nc.y = radius/height
			var tip_normal := (na+nc).normalized()
			b.triangle(a,c,peak,na,nc,tip_normal,Vector2(u0,1),Vector2(u1,1),Vector2((u0+u1)*0.5,0))
		else:
			var upper_a := a+peak
			var upper_c := c+peak
			hull.append(upper_a)
			b.triangle(a,c,upper_c,na,nc,nc,Vector2(u0,1),Vector2(u1,1),Vector2(u1,0))
			b.triangle(a,upper_c,upper_a,na,nc,na,Vector2(u0,1),Vector2(u1,0),Vector2(u0,0))
			b.face(PackedVector3Array([peak,upper_a,upper_c]), Vector3.UP)
	if cone:
		hull.append(peak)
	b.collider(hull)

static func _sphere_point(radius: float, longitude: float, latitude: float) -> Vector3:
	var point := _ring(radius*sin(latitude),longitude,radius*cos(latitude))
	if absf(point.y) < 1e-7:
		point.y = 0.0
	return point

static func _sphere(b: BlockoutMeshBuilder, radius: float, segments: int, hemisphere: bool) -> void:
	var rows: int = segments/4 if hemisphere else segments/2
	var extent := PI*0.5 if hemisphere else PI
	var hull := PackedVector3Array()
	for row in range(rows):
		var v0 := float(row)/rows
		var v1 := float(row+1)/rows
		for i in range(segments):
			var u0 := float(i)/segments
			var u1 := float(i+1)/segments
			var a := _sphere_point(radius,TAU*u0,extent*v0)
			var c := _sphere_point(radius,TAU*u1,extent*v0)
			var d := _sphere_point(radius,TAU*u1,extent*v1)
			var e := _sphere_point(radius,TAU*u0,extent*v1)
			b.triangle(a,c,d,a.normalized(),c.normalized(),d.normalized(),Vector2(u0,v0),Vector2(u1,v0),Vector2(u1,v1))
			b.triangle(a,d,e,a.normalized(),d.normalized(),e.normalized(),Vector2(u0,v0),Vector2(u1,v1),Vector2(u0,v1))
			hull.append(a)
			hull.append(e)
			if hemisphere and row == rows-1:
				b.face(PackedVector3Array([Vector3.ZERO,e,d]),Vector3.DOWN)
	hull.append(Vector3(0,0 if hemisphere else -radius,0))
	b.collider(hull)

static func _corner(b: BlockoutMeshBuilder, radius: float, height: float, segments: int, inner: bool) -> void:
	var anchor := Vector2(radius,-radius) if inner else Vector2.ZERO
	for i in range(segments):
		var a := _ring(radius,PI*0.5*float(i)/segments)
		var c := _ring(radius,PI*0.5*float(i+1)/segments)
		_column(b,PackedVector2Array([anchor,Vector2(a.x,a.z),Vector2(c.x,c.z)]),0,height)

static func _opening(b: BlockoutMeshBuilder, p: Node) -> void:
	var rounded: bool = p.round_size
	var w := _length(p.doorway_width,rounded)
	var h := _length(p.doorway_height,rounded)
	var d := _length(p.doorway_depth,rounded)
	var side := minf(_length(p.side_thickness,rounded), w*0.49)
	var top := minf(_length(p.top_thickness,rounded), h*0.99)
	b.box(Vector3.ZERO,Vector3(side,h,d))
	b.box(Vector3(w-side,0,0),Vector3(side,h,d))
	b.box(Vector3(side,h-top,0),Vector3(w-2*side,top,d))
	if p.shape_type == 14:
		var bottom := minf(_length(p.bottom_thickness,rounded),maxf(h-top-0.001,0.001))
		b.box(Vector3(side,0,0),Vector3(w-2*side,bottom,d))

static func _beam(b: BlockoutMeshBuilder, start: Vector3, end: Vector3, width: float, height: float, side := Vector3.RIGHT, up := Vector3.UP) -> void:
	var x := side*width
	var y := up*height
	b.solid(PackedVector3Array([start,start+x,start+x+y,start+y,end,end+x,end+x+y,end+y]),HEX_FACES)

static func railing_joint_distances(p: Node) -> PackedFloat64Array:
	var count := clampi(p.railing_sections, 1, 256)
	var length := _length(p.railing_section_length, p.round_size)
	var last_length: float = length
	if p._railing_last_section_length >= 0.0:
		last_length = maxf(_q(p._railing_last_section_length, p.round_size), 0.000001)
	var distances := PackedFloat64Array()
	for i in range(count):
		distances.append(length * i)
	distances.append(length * (count - 1) + last_length)
	return distances

static func railing_height(p: Node) -> float:
	return clampf(_q(p.railing_height, p.round_size), RAILING_MIN_HEIGHT, RAILING_MAX_HEIGHT)

static func railing_layer_heights(p: Node) -> PackedFloat64Array:
	var height := railing_height(p)
	var count := clampi(ceili(height / RAILING_LAYER_STEP), 1, 256)
	var heights := PackedFloat64Array()
	for i in range(count):
		heights.append(minf(RAILING_LAYER_STEP * (i + 1), height) - 0.15)
	return heights

static func _railing(b: BlockoutMeshBuilder, p: Node) -> void:
	var distances := railing_joint_distances(p)
	var height := railing_height(p)
	var layers := railing_layer_heights(p)
	var count := distances.size() - 1
	var total := distances[count]
	var elevation := _q(p.railing_skew_elevation,p.round_size)
	for i in range(count+1):
		var joint := Vector3(0, elevation * distances[i] / total, -distances[i])
		if i < count or p.railing_has_end_pole:
			b.box(joint+Vector3(-0.05,0,0.05),Vector3(0.1,height,0.1))
		if i == count:
			continue
		var next := Vector3(0, elevation * distances[i + 1] / total, -distances[i + 1])
		if p.railing_type == 1:
			_beam(b,joint+Vector3(-0.035,0.1,0),next+Vector3(-0.035,0.1,0),0.07,height-0.2)
		else:
			for y in layers:
				_beam(b,joint+Vector3(-0.04,y,0),next+Vector3(-0.04,y,0),0.08,0.08)

static func _skewbox(b: BlockoutMeshBuilder, p: Node) -> void:
	var value: Vector3 = p.skewbox_endpoint
	var end: Vector3 = (value * 100.0 + Vector3.ONE * 0.5).floor() / 100.0 if p.round_size else value
	if end.length_squared() < 1e-12:
		return
	var start_size := _size2(p.skewbox_start_size,p.round_size)
	var end_size := _size2(p.skewbox_end_size,p.round_size)
	var alignment := -0.5*clampi(p.skewbox_alignment,0,2)
	var side := Vector3.RIGHT
	var up := Vector3.UP
	if absf(end.z) < 0.0001:
		var direction := end.normalized()
		side = direction.cross(Vector3.UP).normalized()
		if side.length_squared() < 0.5:
			side = Vector3.RIGHT
		up = side.cross(direction).normalized()
	var points := PackedVector3Array()
	for i in range(2):
		var size := start_size if i == 0 else end_size
		var anchor := Vector3.ZERO if i == 0 else end
		anchor += side*size.x*alignment
		points.append_array(PackedVector3Array([anchor,anchor+side*size.x,anchor+side*size.x+up*size.y,anchor+up*size.y]))
	b.solid(points,HEX_FACES)

static func _linear_stairs(b: BlockoutMeshBuilder, p: Node) -> void:
	var count := clampi(p.number_of_steps,1,256)
	var size := _size(p.stairs_size,p.round_size)
	var w := size.x
	var d := size.z/count
	var h := size.y/count
	var gap_d := 0.0
	var gap_h := 0.0
	if p.shape_type == 12:
		w = _length(p.step_width,p.round_size)
		d = _length(p.step_depth,p.round_size)
		h = _length(p.step_height,p.round_size)
		gap_d = maxf(_q(p.step_depth_spacing,p.round_size),0.0)
		gap_h = maxf(_q(p.step_height_spacing,p.round_size),0.0)
	for i in range(count):
		if p.stairs_type == 2:
			b.box(Vector3(0,0,-d*i),Vector3(w,h*(i+1),d))
		else:
			var origin := Vector3(0,(h+gap_h)*i,-(d+gap_d)*i)
			if p.stairs_type == 1:
				_profile(b,PackedVector2Array([Vector2(0,-h),Vector2(d,0),Vector2(d,h),Vector2(0,h)]),w,origin)
			else:
				b.box(origin,Vector3(w,h,d))

static func _stair_point(radius: float, angle: float, height: float) -> Vector3:
	return Vector3(sin(angle)*radius,height,-cos(angle)*radius)

static func _curved_stairs(b: BlockoutMeshBuilder, p: Node) -> void:
	var count := clampi(p.number_of_steps,1,256)
	var inner := _length(p.stairs_inner_radius,p.round_size)
	var outer := inner+_length(p.step_width,p.round_size)
	var h := _length(p.stairs_height,p.round_size)/count
	var step_angle := deg_to_rad(clampf(p.stairs_angle,1,360))/count
	var direction := -1.0 if p.stairs_counter_clockwise else 1.0
	var divisions := maxi(1,ceili(step_angle/(PI/12.0)))
	for i in range(count):
		for j in range(divisions):
			var f0 := float(j)/divisions
			var f1 := float(j+1)/divisions
			var a0 := (i+f0)*step_angle*direction
			var a1 := (i+f1)*step_angle*direction
			var bottom0 := 0.0 if p.stairs_type == 2 else h*i
			var bottom1 := bottom0
			if p.stairs_type == 1:
				bottom0 = h*(i-1+f0)
				bottom1 = h*(i-1+f1)
			var top := h*(i+1)
			b.solid(PackedVector3Array([_stair_point(inner,a0,bottom0),_stair_point(outer,a0,bottom0),_stair_point(outer,a1,bottom1),_stair_point(inner,a1,bottom1),_stair_point(inner,a0,top),_stair_point(outer,a0,top),_stair_point(outer,a1,top),_stair_point(inner,a1,top)]),[[0,1,2,3],[4,7,6,5],[0,4,5,1],[3,2,6,7],[0,3,7,4],[1,5,6,2]])

static func _tube(b: BlockoutMeshBuilder, p: Node) -> void:
	var radius := _length(p.tube_radius,p.round_size)
	var thickness := _length(p.tube_thickness,p.round_size)
	var height := _length(p.tube_height,p.round_size)
	var angle := deg_to_rad(clampf(p.tube_angle,1,360))
	var count := maxi(clampi(p.tube_sections,1,256),ceili(angle/(PI*0.5)))
	var inner := radius-thickness*0.5*clampi(p.tube_alignment,0,2)
	var outer := inner+thickness
	inner = maxf(inner,0.001)
	outer = maxf(outer,inner+0.001)
	for i in range(count):
		var a0 := angle*float(i)/count
		var a1 := angle*float(i+1)/count
		var v0 := _ring(inner,a0)
		var v1 := _ring(outer,a0)
		var v2 := _ring(outer,a1)
		var v3 := _ring(inner,a1)
		_column(b,PackedVector2Array([Vector2(v0.x,v0.z),Vector2(v1.x,v1.z),Vector2(v2.x,v2.z),Vector2(v3.x,v3.z)]),0,height)
