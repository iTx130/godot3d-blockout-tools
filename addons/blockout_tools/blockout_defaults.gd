@tool
extends RefCounted
## Project-wide defaults affect newly created shapes, never existing scene instances.
const VALUES = {
	"material_type":0, "blockout_material_color":Color(1,0.3,0.05),
	"use_grid":true, "world_aligned":false, "grid_size":1.0,
	"checker_luminance":0.3, "roughness":0.3,
	"use_top_color":true, "top_color":Color(0.25,0.25,0.25)
}
const PREFIX = "blockout_tools/material_defaults/"
const DEFAULT_BOX_SIZE := Vector3.ONE
const BOX_SIZE_KEY := "blockout_tools/shape_defaults/box_size"

static func register_settings() -> void:
	for property in VALUES:
		var key: String = PREFIX + property
		if not ProjectSettings.has_setting(key):
			ProjectSettings.set_setting(key,VALUES[property])
		ProjectSettings.set_initial_value(key,VALUES[property])
		ProjectSettings.set_as_basic(key,true)
		var info := {"name":key,"type":typeof(VALUES[property])}
		if property == "material_type":
			info.merge({"hint":PROPERTY_HINT_ENUM,"hint_string":"Blockout Grid,Custom Material"})
		elif property in ["roughness","checker_luminance"]:
			info.merge({"hint":PROPERTY_HINT_RANGE,"hint_string":"0,1,0.01"})
		elif property == "grid_size":
			info.merge({"hint":PROPERTY_HINT_RANGE,"hint_string":"0.01,100,0.01,or_greater"})
		ProjectSettings.add_property_info(info)
	if not ProjectSettings.has_setting(BOX_SIZE_KEY):
		ProjectSettings.set_setting(BOX_SIZE_KEY, DEFAULT_BOX_SIZE)
	ProjectSettings.set_initial_value(BOX_SIZE_KEY, DEFAULT_BOX_SIZE)
	ProjectSettings.set_as_basic(BOX_SIZE_KEY, true)
	ProjectSettings.add_property_info({"name":BOX_SIZE_KEY, "type":TYPE_VECTOR3})

static func get_default_box_size() -> Vector3:
	var value: Variant = ProjectSettings.get_setting(BOX_SIZE_KEY, DEFAULT_BOX_SIZE)
	if value is Vector3:
		return value
	return DEFAULT_BOX_SIZE

static func set_default_box_size(value: Vector3) -> void:
	var clamped := Vector3(
		maxf(value.x, 0.01),
		maxf(value.y, 0.01),
		maxf(value.z, 0.01)
	)
	ProjectSettings.set_setting(BOX_SIZE_KEY, clamped)
	var error := ProjectSettings.save()
	if error != OK:
		push_warning("Could not save the default Box size: %s" % error_string(error))

static func apply_to(shape: Node) -> void:
	for property in VALUES:
		var value: Variant = ProjectSettings.get_setting(PREFIX+property,VALUES[property])
		# Shape-specific defaults keep railings clear and curved surfaces readable.
		if property == "use_grid" and shape.shape_type == 6:
			value = false
		if property == "use_top_color" and shape.shape_type in [3,6,9]:
			value = false
		shape.set(property,value)
	if shape.shape_type == 0:
		shape.box_size = get_default_box_size()
