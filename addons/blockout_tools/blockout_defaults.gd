@tool
extends RefCounted
## Project-wide defaults affect newly created shapes, never existing scene instances.
const VALUES = {
	"material_type":0, "blockout_material_color":Color("9e9e9e"),
	"use_grid":true, "world_aligned":false, "grid_size":0.5, "grid_subdivisions":5,
	"checker_luminance":0.3, "roughness":0.3,
	"use_top_color":true, "top_color":Color(0.25,0.25,0.25)
}
const PREFIX = "blockout_tools/material_defaults/"

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
		elif property == "grid_subdivisions":
			info.merge({"hint":PROPERTY_HINT_RANGE,"hint_string":"1,100,1"})
		ProjectSettings.add_property_info(info)

static func get_default_blockout_material_color() -> Color:
	var value: Variant = ProjectSettings.get_setting(PREFIX + "blockout_material_color", VALUES["blockout_material_color"])
	if value is Color:
		return value
	return VALUES["blockout_material_color"]

## Updates the in-memory setting only; call save_settings() once editing is done.
static func set_default_blockout_material_color(value: Color) -> void:
	ProjectSettings.set_setting(PREFIX + "blockout_material_color", Color(value, 1.0))

static func save_settings() -> void:
	var error := ProjectSettings.save()
	if error != OK:
		push_warning("Could not save the default Blockout material color: %s" % error_string(error))

static func apply_to(shape: Node) -> void:
	for property in VALUES:
		var value: Variant = ProjectSettings.get_setting(PREFIX+property,VALUES[property])
		# Shape-specific defaults keep railings clear and curved surfaces readable.
		if property == "use_grid" and shape.shape_type == 6:
			value = false
		if property == "use_top_color" and shape.shape_type in [3,6,9]:
			value = false
		shape.set(property,value)
