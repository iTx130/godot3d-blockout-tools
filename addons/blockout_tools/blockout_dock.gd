@tool
extends VBoxContainer

const DEFAULTS := preload("blockout_defaults.gd")

var plugin: EditorPlugin
var shape_option: OptionButton
var add_button: Button
var rebuild_button: Button
var info: Label
var default_box_size_inputs: Array[LineEdit] = []

## Keep these labels explicitly in English. The numeric order is the public
## ShapeType order used by BlockoutShape and the generator.
const SHAPES := [
	"Box", "Cone", "Corner Curved", "Corner Ramp", "Cylinder", "Doorway",
	"Railing", "Ramp", "Skewbox", "Sphere", "Stairs Curved", "Stairs Linear",
	"Stairs Linear Manual", "Tube", "Window"
]
const BOX_SIZE_AXIS_LABELS := ["x", "y", "z"]
const BOX_SIZE_AXIS_COLORS := [Color("c65a68"), Color("82a94b"), Color("517cad")]

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
		shape_option.add_item(SHAPES[shape_index], shape_index)
		shape_option.set_item_auto_translate_mode(shape_index, Node.AUTO_TRANSLATE_MODE_DISABLED)
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
	info = Label.new()
	info.text = "Godot-native: 15 procedural shapes"
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(info)
	var separator := HSeparator.new()
	add_child(separator)
	var default_box_size_label := Label.new()
	default_box_size_label.text = "Default Box Size"
	default_box_size_label.tooltip_text = "Default size for newly created Box shapes, in metres."
	add_child(default_box_size_label)
	var default_box_size := DEFAULTS.get_default_box_size()
	var input_panel := PanelContainer.new()
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("191919")
	panel_style.corner_radius_top_left = 6
	panel_style.corner_radius_top_right = 6
	panel_style.corner_radius_bottom_left = 6
	panel_style.corner_radius_bottom_right = 6
	panel_style.content_margin_left = 8.0
	panel_style.content_margin_top = 4.0
	panel_style.content_margin_right = 8.0
	panel_style.content_margin_bottom = 4.0
	input_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(input_panel)
	var axis_row := HBoxContainer.new()
	axis_row.add_theme_constant_override("separation", 8)
	input_panel.add_child(axis_row)
	for axis in 3:
		var axis_group := HBoxContainer.new()
		axis_group.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		axis_group.add_theme_constant_override("separation", 3)
		var axis_label := Label.new()
		axis_label.text = BOX_SIZE_AXIS_LABELS[axis]
		axis_label.custom_minimum_size.x = 16.0
		axis_label.add_theme_color_override("font_color", BOX_SIZE_AXIS_COLORS[axis])
		axis_group.add_child(axis_label)
		var input := LineEdit.new()
		input.flat = true
		input.custom_minimum_size.x = 42.0
		input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		input.select_all_on_focus = true
		input.text = _format_box_size(default_box_size[axis])
		input.tooltip_text = "%s axis, metres" % BOX_SIZE_AXIS_LABELS[axis].to_upper()
		input.add_theme_constant_override("minimum_character_width", 2)
		input.text_submitted.connect(_on_default_box_size_submitted.bind(axis))
		input.focus_exited.connect(_on_default_box_size_focus_exited.bind(input, axis))
		default_box_size_inputs.append(input)
		axis_group.add_child(input)
		axis_row.add_child(axis_group)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(spacer)

func _format_box_size(value: float) -> String:
	var formatted := "%.2f" % value
	if formatted.ends_with("0"):
		formatted = formatted.left(-1)
	return formatted

func _on_default_box_size_submitted(text: String, axis: int) -> void:
	var input := default_box_size_inputs[axis]
	var normalized := text.strip_edges()
	if not normalized.is_valid_float():
		input.text = _format_box_size(DEFAULTS.get_default_box_size()[axis])
		return
	var value := maxf(normalized.to_float(), 0.01)
	var default_box_size := DEFAULTS.get_default_box_size()
	default_box_size[axis] = value
	DEFAULTS.set_default_box_size(default_box_size)
	input.text = _format_box_size(value)

func _on_default_box_size_focus_exited(input: LineEdit, axis: int) -> void:
	_on_default_box_size_submitted(input.text, axis)

func _on_add_pressed() -> void:
	if plugin:
		plugin.create_shape(shape_option.selected)

func _on_rebuild_pressed() -> void:
	var selected: Node = plugin.get_selected_blockout() if plugin else null
	if selected:
		selected.rebuild()
