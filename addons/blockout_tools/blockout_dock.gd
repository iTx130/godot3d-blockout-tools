@tool
extends VBoxContainer

var plugin: EditorPlugin
var shape_option: OptionButton
var add_button: Button
var rebuild_button: Button
var info: Label

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
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(spacer)

func _on_add_pressed() -> void:
	if plugin:
		plugin.create_shape(shape_option.selected)

func _on_rebuild_pressed() -> void:
	var selected: Node = plugin.get_selected_blockout() if plugin else null
	if selected:
		selected.rebuild()
