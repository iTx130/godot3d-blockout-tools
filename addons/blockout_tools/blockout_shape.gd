@tool
class_name BlockoutShape
extends Node3D
## Parameters use metres and Godot local axes: X width, Y height, Z depth.
## Positive depth extends toward -Z; signed endpoints use Godot XYZ directly.
## Generated children are transient; scenes save the parameters, not duplicated geometry.
const Builder = preload("blockout_mesh.gd")
const Generator = preload("shape_generator.gd")
const GRID_SHADER = preload("blockout_grid.gdshader")
const NAMES = ["Box", "Cone", "Corner Curved", "Corner Ramp", "Cylinder", "Doorway", "Railing", "Ramp", "Skewbox", "Sphere", "Stairs Curved", "Stairs Linear", "Stairs Linear Manual", "Tube", "Window"]
enum ShapeType {BOX, CONE, CORNER_CURVED, CORNER_RAMP, CYLINDER, DOORWAY, RAILING, RAMP, SKEWBOX, SPHERE, STAIRS_CURVED, STAIRS_LINEAR, STAIRS_LINEAR_MANUAL, TUBE, WINDOW}

@export_category("Blockout Shape")
@export_enum("Box", "Cone", "Corner Curved", "Corner Ramp", "Cylinder", "Doorway", "Railing", "Ramp", "Skewbox", "Sphere", "Stairs Curved", "Stairs Linear", "Stairs Linear Manual", "Tube", "Window")
var shape_type: int = 0:
	set(value):
		shape_type = clampi(value, 0, 14)
		notify_property_list_changed()
		request_rebuild()
@export var rebuild_in_editor := true:
	set(value):
		rebuild_in_editor = value
		request_rebuild()

@export_category("Geometry")
@export var round_size: bool = true:
	set(value):
		round_size = value
		request_rebuild()

## Fraction of the editor translation snap step used by this shape's handles.
## 1.0 follows the editor grid step; Ctrl/Shift keep their editor behavior.
@export_range(0.001, 1.0, 0.001, "or_greater") var grid_snap_ratio: float = 1.0:
	set(value):
		grid_snap_ratio = maxf(value, 0.001) if is_finite(value) else 1.0

@export_category("Box")
## Godot local X/Y/Z extents in metres. The base corner remains at the origin.
@export var box_size: Vector3 = Vector3.ONE:
	set(value):
		box_size = value
		request_rebuild()

@export_category("Cone / Cylinder")
@export_range(0.01, 100.0, 0.01, "or_greater") var cone_radius: float = 0.5:
	set(value):
		cone_radius = value
		request_rebuild()
@export_range(0.01, 100.0, 0.01, "or_greater") var cone_height: float = 1.0:
	set(value):
		cone_height = value
		request_rebuild()
@export_range(0.01, 100.0, 0.01, "or_greater") var cylinder_radius: float = 0.5:
	set(value):
		cylinder_radius = value
		request_rebuild()
@export_range(0.01, 100.0, 0.01, "or_greater") var cylinder_height: float = 1.0:
	set(value):
		cylinder_height = value
		request_rebuild()
@export_range(1, 4, 1) var quality: int = 1:
	set(value):
		quality = value
		request_rebuild()

@export_category("Corner Curved")
@export_range(0.01, 100.0, 0.01, "or_greater") var corner_curved_radius: float = 1.0:
	set(value):
		corner_curved_radius = value
		request_rebuild()
@export_range(0.01, 100.0, 0.01, "or_greater") var corner_curved_height: float = 1.0:
	set(value):
		corner_curved_height = value
		request_rebuild()
@export_range(1, 4, 1) var corner_curved_quality: int = 1:
	set(value):
		corner_curved_quality = value
		request_rebuild()
@export var corner_curved_inner: bool = false:
	set(value):
		corner_curved_inner = value
		request_rebuild()

@export_category("Ramp / Corner Ramp")
@export_range(0.01, 100.0, 0.01, "or_greater") var ramp_width: float = 1.0:
	set(value):
		ramp_width = value
		request_rebuild()
@export_range(0.01, 100.0, 0.01, "or_greater") var ramp_depth: float = 1.0:
	set(value):
		ramp_depth = value
		request_rebuild()
@export_range(0.01, 100.0, 0.01, "or_greater") var ramp_height: float = 1.0:
	set(value):
		ramp_height = value
		request_rebuild()

@export_category("Doorway / Window")
@export_range(0.01, 100.0, 0.01, "or_greater") var doorway_width: float = 2.0:
	set(value):
		doorway_width = value
		request_rebuild()
@export_range(0.01, 100.0, 0.01, "or_greater") var doorway_height: float = 2.5:
	set(value):
		doorway_height = value
		request_rebuild()
@export_range(0.01, 100.0, 0.01, "or_greater") var doorway_depth: float = 0.5:
	set(value):
		doorway_depth = value
		request_rebuild()
@export_range(0.01, 100.0, 0.01, "or_greater") var side_thickness: float = 0.5:
	set(value):
		side_thickness = value
		request_rebuild()
@export_range(0.01, 100.0, 0.01, "or_greater") var top_thickness: float = 0.5:
	set(value):
		top_thickness = value
		request_rebuild()
@export_range(0.01, 100.0, 0.01, "or_greater") var bottom_thickness: float = 1.0:
	set(value):
		bottom_thickness = value
		request_rebuild()

@export_category("Railing")
var _railing_layout_batch := false
@export_range(1, 256, 1) var railing_sections: int = 2:
	set(value):
		railing_sections = value
		if not _railing_layout_batch:
			_railing_last_section_length = -1.0
		request_rebuild()
@export_range(0.01, 100.0, 0.01, "or_greater") var railing_section_length: float = 1.0:
	set(value):
		railing_section_length = value
		if not _railing_layout_batch:
			_railing_last_section_length = -1.0
		request_rebuild()
## Length drags preserve full metre spans and store the final partial span.
## Negative values retain the legacy uniform-section layout.
@export_storage var _railing_last_section_length: float = -1.0:
	set(value):
		_railing_last_section_length = value
		request_rebuild()
## Open railings grow a layer every half metre, with at least one layer.
@export_range(0.5, 128.0, 0.01) var railing_height: float = 1.0:
	set(value):
		railing_height = clampf(value, Generator.RAILING_MIN_HEIGHT, Generator.RAILING_MAX_HEIGHT) if is_finite(value) else 1.0
		request_rebuild()
@export var railing_skew_elevation: float = 0.0:
	set(value):
		railing_skew_elevation = value
		request_rebuild()
@export_enum("Open", "Closed") var railing_type: int = 0:
	set(value):
		railing_type = value
		request_rebuild()
@export var railing_has_end_pole: bool = true:
	set(value):
		railing_has_end_pole = value
		request_rebuild()

@export_category("Skewbox")
## Signed endpoint in Godot local coordinates (Y up, negative Z forward).
@export var skewbox_endpoint: Vector3 = Vector3(0, 0.5, -1):
	set(value):
		skewbox_endpoint = value
		request_rebuild()
## Cross-section width and height, perpendicular to the spline direction.
@export var skewbox_start_size: Vector2 = Vector2.ONE:
	set(value):
		skewbox_start_size = value
		request_rebuild()
## Cross-section width and height, perpendicular to the spline direction.
@export var skewbox_end_size: Vector2 = Vector2.ONE:
	set(value):
		skewbox_end_size = value
		request_rebuild()
@export_enum("Left", "Center", "Right") var skewbox_alignment: int = 1:
	set(value):
		skewbox_alignment = value
		request_rebuild()

@export_category("Sphere")
@export_range(0.01, 100.0, 0.01, "or_greater") var sphere_radius: float = 0.5:
	set(value):
		sphere_radius = value
		request_rebuild()
@export_range(1, 4, 1) var sphere_quality: int = 1:
	set(value):
		sphere_quality = value
		request_rebuild()
@export var sphere_hemisphere: bool = false:
	set(value):
		sphere_hemisphere = value
		request_rebuild()

@export_category("Stairs")
@export_range(1, 256, 1) var number_of_steps: int = 10:
	set(value):
		number_of_steps = value
		request_rebuild()
@export_enum("Box", "Sloped", "Closed") var stairs_type: int = 0:
	set(value):
		stairs_type = value
		request_rebuild()
## Godot local X width, Y total height, Z total depth. Stairs rise toward -Z.
@export var stairs_size: Vector3 = Vector3.ONE:
	set(value):
		stairs_size = value
		request_rebuild()
@export_range(0.01, 100.0, 0.01, "or_greater") var step_width: float = 1.0:
	set(value):
		step_width = value
		request_rebuild()
@export_range(0.01, 100.0, 0.01, "or_greater") var step_depth: float = 0.1:
	set(value):
		step_depth = value
		request_rebuild()
@export_range(0.01, 100.0, 0.01, "or_greater") var step_height: float = 0.1:
	set(value):
		step_height = value
		request_rebuild()
@export_range(0.0, 100.0, 0.01) var step_depth_spacing: float = 0.0:
	set(value):
		step_depth_spacing = value
		request_rebuild()
@export_range(0.0, 100.0, 0.01) var step_height_spacing: float = 0.0:
	set(value):
		step_height_spacing = value
		request_rebuild()
@export_range(0.01, 100.0, 0.01, "or_greater") var stairs_inner_radius: float = 0.5:
	set(value):
		stairs_inner_radius = value
		request_rebuild()
@export_range(0.01, 100.0, 0.01, "or_greater") var stairs_height: float = 1.0:
	set(value):
		stairs_height = value
		request_rebuild()
@export_range(1.0, 360.0, 1.0) var stairs_angle: float = 90.0:
	set(value):
		stairs_angle = value
		request_rebuild()
@export var stairs_counter_clockwise: bool = false:
	set(value):
		stairs_counter_clockwise = value
		request_rebuild()

@export_category("Tube")
@export_range(0.01, 100.0, 0.01, "or_greater") var tube_radius: float = 0.5:
	set(value):
		tube_radius = value
		request_rebuild()
@export_range(0.01, 100.0, 0.01, "or_greater") var tube_thickness: float = 0.1:
	set(value):
		tube_thickness = value
		request_rebuild()
@export_range(0.01, 100.0, 0.01, "or_greater") var tube_height: float = 1.0:
	set(value):
		tube_height = value
		request_rebuild()
@export_range(1.0, 360.0, 1.0) var tube_angle: float = 360.0:
	set(value):
		tube_angle = value
		request_rebuild()
@export_range(1, 256, 1) var tube_sections: int = 8:
	set(value):
		tube_sections = value
		request_rebuild()
@export_enum("Left", "Center", "Right") var tube_alignment: int = 0:
	set(value):
		tube_alignment = value
		request_rebuild()

@export_category("Blockout Material")
@export_enum("Blockout Grid", "Custom Material") var material_type: int = 0:
	set(value):
		material_type = value
		notify_property_list_changed()
		request_material_update()
## Open the arrow on this resource slot to create a StandardMaterial3D,
## ORMMaterial3D or ShaderMaterial, or drag an existing material here.
@export_custom(PROPERTY_HINT_RESOURCE_TYPE, "StandardMaterial3D,ORMMaterial3D,ShaderMaterial")
var custom_material: Material = null:
	set(value):
		custom_material = value
		request_material_update()
@export_color_no_alpha var blockout_material_color: Color = Color("9e9e9e"):
	set(value):
		blockout_material_color = value
		request_material_update()
@export_storage var _grid_override: int = -1
@export_storage var _top_color_override: int = -1
@export var use_grid: bool:
	get:
		return shape_type != 6 if _grid_override < 0 else bool(_grid_override)
	set(value):
		_grid_override = int(value)
		request_material_update()
@export var world_aligned: bool = false:
	set(value):
		world_aligned = value
		request_material_update()
## Major grid spacing in metres; Grid Subdivisions controls the minor spacing.
@export_range(0.01, 100.0, 0.01, "or_greater") var grid_size: float = 0.5:
	set(value):
		grid_size = value
		request_material_update()
## Divisions per major grid cell; minor spacing is Grid Size / Grid Subdivisions.
@export_range(1, 100, 1) var grid_subdivisions: int = 5:
	set(value):
		grid_subdivisions = clampi(value, 1, 100)
		request_material_update()
@export_range(0, 1, 0.01) var checker_luminance: float = 0.3:
	set(value):
		checker_luminance = value
		request_material_update()
@export_range(0, 1, 0.01) var roughness: float = 0.3:
	set(value):
		roughness = value
		request_material_update()
@export var use_top_color: bool:
	get:
		return shape_type not in [3, 6, 9] if _top_color_override < 0 else bool(_top_color_override)
	set(value):
		_top_color_override = int(value)
		request_material_update()
@export_color_no_alpha var top_color: Color = Color(0.25, 0.25, 0.25):
	set(value):
		top_color = value
		request_material_update()

@export_category("Collision / Rendering")
@export var enable_collisions: bool = true:
	set(value):
		enable_collisions = value
		request_rebuild()
@export var enable_custom_collision: bool = false:
	set(value):
		enable_custom_collision = value
		request_rebuild()
@export_flags_3d_physics var custom_collision_layer: int = 1:
	set(value):
		custom_collision_layer = value
		request_rebuild()
@export_flags_3d_physics var custom_collision_mask: int = 1:
	set(value):
		custom_collision_mask = value
		request_rebuild()
@export var cast_shadows: bool = true:
	set(value):
		cast_shadows = value
		request_rebuild()

const PROPERTY_SHAPES: Dictionary = {"box_size":[0],"cone_radius":[1],"cone_height":[1],"cylinder_radius":[4],"cylinder_height":[4],"quality":[1,4],"corner_curved_radius":[2],"corner_curved_height":[2],"corner_curved_quality":[2],"corner_curved_inner":[2],"ramp_width":[3,7],"ramp_depth":[3,7],"ramp_height":[3,7],"doorway_width":[5,14],"doorway_height":[5,14],"doorway_depth":[5,14],"side_thickness":[5,14],"top_thickness":[5,14],"bottom_thickness":[14],"railing_sections":[6],"railing_section_length":[6],"_railing_last_section_length":[6],"railing_height":[6],"railing_skew_elevation":[6],"railing_type":[6],"railing_has_end_pole":[6],"skewbox_endpoint":[8],"skewbox_start_size":[8],"skewbox_end_size":[8],"skewbox_alignment":[8],"sphere_radius":[9],"sphere_quality":[9],"sphere_hemisphere":[9],"number_of_steps":[10,11,12],"stairs_type":[10,11,12],"stairs_size":[11],"step_width":[10,12],"step_depth":[12],"step_height":[12],"step_depth_spacing":[12],"step_height_spacing":[12],"stairs_inner_radius":[10],"stairs_height":[10],"stairs_angle":[10],"stairs_counter_clockwise":[10],"tube_radius":[13],"tube_thickness":[13],"tube_height":[13],"tube_angle":[13],"tube_sections":[13],"tube_alignment":[13]}
var _mesh_instance: MeshInstance3D
var _static_body: StaticBody3D
var _collision_shape: CollisionShape3D
var _grid_material: ShaderMaterial
var _queued := false
var _material_queued := false
var last_builder: BlockoutMeshBuilder
var build_count := 0

func _validate_property(property: Dictionary) -> void:
	if property.name == "shape_type":
		var choices := PackedStringArray()
		for id in NAMES.size():
			# Legacy manual-stair nodes retain their current value and parameters.
			if id == ShapeType.STAIRS_LINEAR_MANUAL and shape_type != id:
				continue
			choices.append("%s:%d" % [NAMES[id], id])
		property.hint_string = ",".join(choices)
	if PROPERTY_SHAPES.has(property.name) and shape_type not in PROPERTY_SHAPES[property.name]:
		property.usage &= ~PROPERTY_USAGE_EDITOR
	if property.name == "custom_material" and material_type != 1:
		property.usage &= ~PROPERTY_USAGE_EDITOR
	if material_type == 1 and property.name in ["blockout_material_color", "use_grid", "world_aligned", "grid_size", "grid_subdivisions", "checker_luminance", "roughness", "use_top_color", "top_color"]:
		property.usage &= ~PROPERTY_USAGE_EDITOR

func _enter_tree() -> void:
	request_rebuild()

## Sets the railing span layout as one unit. A negative last_length keeps the
## uniform layout. Unlike assigning the properties one by one, the result does
## not depend on assignment order.
func set_railing_layout(sections: int, section_length: float, last_length: float = -1.0) -> void:
	_railing_layout_batch = true
	railing_sections = sections
	railing_section_length = section_length
	_railing_last_section_length = last_length
	_railing_layout_batch = false

func request_rebuild() -> void:
	if not is_inside_tree() or _queued:
		return
	if Engine.is_editor_hint() and not rebuild_in_editor:
		return
	_queued = true
	call_deferred("rebuild")

func request_material_update() -> void:
	if not is_inside_tree() or _material_queued:
		return
	_material_queued = true
	call_deferred("_update_material")

func _ensure_children() -> void:
	_mesh_instance = get_node_or_null("BlockoutMesh") as MeshInstance3D
	if not is_instance_valid(_mesh_instance):
		_mesh_instance = MeshInstance3D.new()
		_mesh_instance.name = "BlockoutMesh"
		add_child(_mesh_instance, false, Node.INTERNAL_MODE_BACK)
	_static_body = get_node_or_null("BlockoutCollision") as StaticBody3D
	if not is_instance_valid(_static_body):
		_static_body = StaticBody3D.new()
		_static_body.name = "BlockoutCollision"
		add_child(_static_body, false, Node.INTERNAL_MODE_BACK)
	_collision_shape = _static_body.get_node_or_null("CollisionShape") as CollisionShape3D
	if not is_instance_valid(_collision_shape):
		_collision_shape = CollisionShape3D.new()
		_collision_shape.name = "CollisionShape"
		_static_body.add_child(_collision_shape)
	# Reclaim legacy generated children so they are not baked into saved scenes.
	_mesh_instance.owner = null
	_static_body.owner = null
	_collision_shape.owner = null

func rebuild() -> void:
	_queued = false
	if not is_inside_tree():
		return
	_ensure_children()
	last_builder = Generator.generate(self)
	_mesh_instance.mesh = last_builder.make_array_mesh()
	_update_material()
	_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if cast_shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_static_body.collision_layer = custom_collision_layer if enable_custom_collision else 1
	_static_body.collision_mask = custom_collision_mask if enable_custom_collision else 1
	for child in _static_body.get_children():
		if child != _collision_shape:
			child.free()
	_collision_shape.shape = null
	if enable_collisions:
		for i in range(last_builder.collision_hulls.size()):
			var child := _collision_shape if i == 0 else CollisionShape3D.new()
			if i > 0:
				_static_body.add_child(child)
			var hull := ConvexPolygonShape3D.new()
			hull.points = last_builder.collision_hulls[i]
			child.shape = hull
	build_count += 1
	update_gizmos()

func _update_material() -> void:
	_material_queued = false
	if not is_instance_valid(_mesh_instance):
		return
	if material_type == 1 and custom_material != null:
		_mesh_instance.material_override = custom_material
		return
	if _grid_material == null:
		_grid_material = ShaderMaterial.new()
		_grid_material.shader = GRID_SHADER
	for key in ["use_grid", "world_aligned", "grid_size", "grid_subdivisions", "checker_luminance", "roughness", "use_top_color"]:
		_grid_material.set_shader_parameter(key, get(key))
	_grid_material.set_shader_parameter("base_color", blockout_material_color)
	_grid_material.set_shader_parameter("top_color", top_color)
	_mesh_instance.material_override = _grid_material

func shape_type_name(value: int = -1) -> String:
	return "Blockout" + NAMES[shape_type if value < 0 else clampi(value, 0, 14)].replace(" ", "")

func get_mesh() -> ArrayMesh:
	return _mesh_instance.mesh as ArrayMesh if is_instance_valid(_mesh_instance) else null
