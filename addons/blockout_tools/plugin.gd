@tool
extends EditorPlugin

const SHAPE_SCRIPT := preload("res://addons/blockout_tools/blockout_shape.gd")
const DOCK_SCRIPT := preload("res://addons/blockout_tools/blockout_dock.gd")
const GIZMO_SCRIPT := preload("res://addons/blockout_tools/blockout_gizmo.gd")
const DEFAULTS := preload("res://addons/blockout_tools/blockout_defaults.gd")

var dock: Control
var shape_icon: Texture2D
var shape_gizmo: EditorNode3DGizmoPlugin

func _enter_tree() -> void:
	DEFAULTS.register_settings()
	shape_gizmo = GIZMO_SCRIPT.new()
	shape_gizmo.history = get_undo_redo()
	add_node_3d_gizmo_plugin(shape_gizmo)
	dock = DOCK_SCRIPT.new()
	dock.name = "Blockout Tools"
	dock.plugin = self
	add_control_to_dock(DOCK_SLOT_LEFT_UL, dock)

func _exit_tree() -> void:
	if shape_gizmo != null:
		remove_node_3d_gizmo_plugin(shape_gizmo)
		shape_gizmo = null
	if is_instance_valid(dock):
		remove_control_from_docks(dock)
		dock.queue_free()

func create_shape(shape_type: int) -> void:
	var parent: Node = get_editor_interface().get_edited_scene_root()
	if parent == null:
		return
	var node: BlockoutShape = SHAPE_SCRIPT.new()
	node.shape_type = shape_type
	DEFAULTS.apply_to(node)
	node.name = node.shape_type_name(shape_type)
	var history := get_undo_redo()
	history.create_action("Add " + node.name, UndoRedo.MERGE_DISABLE, parent)
	history.add_do_method(parent, "add_child", node, true)
	history.add_do_method(node, "set_owner", parent)
	history.add_undo_method(parent, "remove_child", node)
	history.add_do_reference(node)
	history.commit_action()
	get_editor_interface().get_selection().clear()
	get_editor_interface().get_selection().add_node(node)
	get_editor_interface().edit_node(node)

func get_selected_blockout() -> Node:
	var selected: Array[Node] = get_editor_interface().get_selection().get_selected_nodes()
	for node in selected:
		if node.get_script() == SHAPE_SCRIPT:
			return node
	return null
