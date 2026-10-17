@tool
extends VBoxContainer

const DEFAULTS := preload("blockout_defaults.gd")
const SHAPE := preload("blockout_shape.gd")

var plugin: EditorPlugin
var shape_option: OptionButton
var add_button: Button
var rebuild_button: Button
var default_blockout_material_picker: ColorPickerButton

## Keep these labels explicitly in English. The numeric order is the public
## ShapeType order used by BlockoutShape and the generator.
const SHAPES := [
	"Box", "Cone", "Corner Curved", "Corner Ramp", "Cylinder", "Doorway",
	"Railing", "Ramp", "Skewbox", "Sphere", "Stairs Curved", "Stairs Linear",
	"Stairs Linear Manual", "Tube", "Window"
]

func _ready() -> void:
	custom_minimum_size = Vector2(235, 0)
	var hint := Label.new()
	hint.text = "Create a shape, then edit its parameters in the Inspector."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(hint)
	shape_option = OptionButton.new()
	# Shape names must stay English even with a translated editor interface.
	shape_option.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	shape_option.get_popup().auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	for shape_index in SHAPES.size():
		# Keep serialized IDs stable while manual stairs are unavailable for creation.
		if shape_index == SHAPE.ShapeType.STAIRS_LINEAR_MANUAL:
			continue
		shape_option.add_item(SHAPES[shape_index], shape_index)
		shape_option.set_item_auto_translate_mode(shape_option.item_count - 1, Node.AUTO_TRANSLATE_MODE_DISABLED)
	add_child(shape_option)
	add_button = Button.new()
	add_button.text = "Add Blockout Shape"
	add_button.pressed.connect(_on_add_pressed)
	add_child(add_button)
	rebuild_button = Button.new()
	rebuild_button.text = "Refresh Selected"
	rebuild_button.tooltip_text = "Regenerate mesh and collision from current parameters."
	rebuild_button.pressed.connect(_on_rebuild_pressed)
	add_child(rebuild_button)
	var separator := HSeparator.new()
	add_child(separator)
	var default_material_label := Label.new()
	default_material_label.text = "Default Blockout Material"
	default_material_label.tooltip_text = "Default base color for newly created Blockout shapes. Existing shapes are unchanged."
	add_child(default_material_label)
	default_blockout_material_picker = ColorPickerButton.new()
	default_blockout_material_picker.edit_alpha = false
	_update_picker_height()
	default_blockout_material_picker.color = DEFAULTS.get_default_blockout_material_color()
	default_blockout_material_picker.tooltip_text = default_material_label.tooltip_text
	default_blockout_material_picker.color_changed.connect(_on_default_blockout_material_color_changed)
	# Dragging in the picker emits color_changed continuously; write project.godot once on close.
	default_blockout_material_picker.popup_closed.connect(DEFAULTS.save_settings)
	add_child(default_blockout_material_picker)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(spacer)

## The Inspector sizes its color property from this editor theme constant. The
## dock may not inherit the editor theme yet in _ready, so refresh on theme changes.
func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED or what == NOTIFICATION_VISIBILITY_CHANGED:
		_update_picker_height()

func _update_picker_height() -> void:
	if default_blockout_material_picker == null:
		return
	var height := 28.0
	if has_theme_constant("color_picker_button_height", "Editor"):
		height = float(get_theme_constant("color_picker_button_height", "Editor"))
	elif Engine.is_editor_hint():
		height *= EditorInterface.get_editor_scale()
	default_blockout_material_picker.custom_minimum_size.y = height

func _on_default_blockout_material_color_changed(color: Color) -> void:
	DEFAULTS.set_default_blockout_material_color(color)

func _on_add_pressed() -> void:
	if plugin:
		plugin.create_shape(shape_option.get_selected_id())

func _on_rebuild_pressed() -> void:
	var selected: Node = plugin.get_selected_blockout() if plugin else null
	if selected:
		selected.rebuild()
