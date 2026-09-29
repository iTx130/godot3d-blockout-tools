@tool
extends VBoxContainer

const DEFAULTS := preload("blockout_defaults.gd")

var plugin: EditorPlugin
var shape_option: OptionButton
var add_button: Button
var rebuild_button: Button
var info: Label
var default_box_size_inputs: Array[SpinBox] = []

## Keep these labels explicitly in English. The numeric order is the public
## ShapeType order used by BlockoutShape and the generator.
const SHAPES := [
	"Box", "Cone", "Corner Curved", "Corner Ramp", "Cylinder", "Doorway",
	"Railing", "Ramp", "Skewbox", "Sphere", "Stairs Curved", "Stairs Linear",
	"Stairs Linear Manual", "Tube", "Window"
]

func _ready() -> void:
	custom_minimum_size = Vector2(235, 0)
	var title := Label.new()
	title.text = "Blockout Tools"
	title.add_theme_font_size_override("font_size", 18)
	add_child(title)
	var hint := Label.new()
	hint.text = "Create a shape, then edit its parameters in the Inspector."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(hint)
	shape_option = OptionButton.new()
	# Shape names must stay English even with a translated editor interface.
	shape_option.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	shape_option.get_popup().auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	for shape_index in SHAPES.size():
		shape_option.add_item(SHAPES[shape_index], shape_index)
		shape_option.set_item_auto_translate_mode(shape_index, Node.AUTO_TRANSLATE_MODE_DISABLED)
	add_child(shape_option)
	add_button = Button.new()
	add_button.text = "Add Blockout Shape"
	add_button.pressed.connect(_on_add_pressed)
	add_child(add_button)
	rebuild_button = Button.new()
	rebuild_button.text = "Rebuild Selected"
	rebuild_button.pressed.connect(_on_rebuild_pressed)
	add_child(rebuild_button)
	info = Label.new()
	info.text = "Godot-native: 15 procedural shapes"
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(info)
	var separator := HSeparator.new()
	add_child(separator)
	var default_box_size_label := Label.new()
	default_box_size_label.text = "Default Box Size"
	add_child(default_box_size_label)
	var default_box_size := DEFAULTS.get_default_box_size()
	var axis_labels := ["X / Width", "Y / Height", "Z / Depth"]
	for axis in 3:
		var row := HBoxContainer.new()
		var axis_label := Label.new()
		axis_label.text = axis_labels[axis]
		axis_label.custom_minimum_size.x = 72.0
		row.add_child(axis_label)
		var input := SpinBox.new()
		input.min_value = 0.01
		input.max_value = 100.0
		input.step = 0.01
		input.allow_greater = true
		input.suffix = " m"
		input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		input.value = default_box_size[axis]
		input.value_changed.connect(_on_default_box_size_changed.bind(axis))
		default_box_size_inputs.append(input)
		row.add_child(input)
		add_child(row)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(spacer)

func _on_default_box_size_changed(value: float, axis: int) -> void:
	var default_box_size := DEFAULTS.get_default_box_size()
	default_box_size[axis] = value
	DEFAULTS.set_default_box_size(default_box_size)

func _on_add_pressed() -> void:
	if plugin:
		plugin.create_shape(shape_option.selected)

func _on_rebuild_pressed() -> void:
	var selected: Node = plugin.get_selected_blockout() if plugin else null
	if selected:
		selected.rebuild()
