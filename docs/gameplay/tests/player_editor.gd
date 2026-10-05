@tool
extends Node3D

const DOCK := preload("res://addons/blockout_tools/blockout_dock.gd")
const PLAYER_PATH := "res://addons/blockout_tools/nodes/player.tscn"
var failures: Array[String] = []
var tested := 0

func _ready() -> void:
	if Engine.is_editor_hint() and "--run-player-editor-tests" in OS.get_cmdline_user_args():
		call_deferred("_run")

func check(label: String, passed: bool) -> void:
	tested += 1
	if not passed:
		failures.append(label)
		push_error(label)

func _run() -> void:
	await get_tree().create_timer(1.0).timeout
	var dock: Control
	for candidate in get_tree().root.find_children("Blockout Tools", "", true, false):
		if candidate.get_script() == DOCK:
			dock = candidate
			break
	check("enabled plugin dock found", dock != null)
	if dock == null:
		get_tree().quit(1)
		return
	check("current edited scene is test root", EditorInterface.get_edited_scene_root() == self)
	var previous_mouse_mode := Input.mouse_mode
	dock.add_node_button.pressed.emit()
	var first := get_child(0)
	check("button adds Player under current scene root", first is CharacterBody3D and first.get_parent() == self)
	check("Player retains external scene instance", first.scene_file_path == PLAYER_PATH)
	check("Player owner is edited scene", first.owner == self)
	check("new Player is selected", EditorInterface.get_selection().get_selected_nodes().has(first))
	check("body mesh defaults to visible in editor", first.get_node("BodyMesh").visible)
	check("controller does not run in editor", first.get("camera") == null and Input.mouse_mode == previous_mouse_mode)
	dock.add_node_button.pressed.emit()
	var second := get_child(1)
	check("multiple additions have unique names", first.name != second.name)
	var history := EditorInterface.get_editor_undo_redo()
	var history_id := history.get_object_history_id(self)
	var undo := history.get_history_undo_redo(history_id)
	check("undo removes last Player", undo.undo() and get_child_count() == 1 and not second.is_inside_tree())
	check("redo restores Player and owner", undo.redo() and get_child_count() == 2 and second.owner == self)
	first.set("perspective", 1)
	first.set("view_height", 1.85)
	var packed := PackedScene.new()
	check("scene packs", packed.pack(self) == OK)
	check("save keeps Player instances without flattening", packed.get_state().get_node_count() == 3)
	var save_path := "res://tests/evidence/player-saved.tscn"
	check("scene saves to disk", ResourceSaver.save(packed, save_path) == OK)
	var loaded := ResourceLoader.load(save_path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	check("saved scene reloads", loaded != null)
	if loaded:
		var restored := loaded.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
		check("reloaded Player keeps its scene reference", restored.get_child(0).scene_file_path == PLAYER_PATH)
		check("reloaded Player keeps its camera and collision", restored.get_child(0).has_node("Head/Camera3D") and restored.get_child(0).has_node("CollisionShape3D"))
		check("reloaded Player keeps exported perspective", restored.get_child(0).get("perspective") == 1)
		check("reloaded Player keeps exported view height", is_equal_approx(restored.get_child(0).get("view_height"), 1.85))
		check("reloaded Player has third person arm and camera", restored.get_child(0).has_node("Head/SpringArm3D/Camera3D"))
		check("reloaded body mesh is visible in editor", restored.get_child(0).get_node("BodyMesh").visible)
		restored.free()
	for placeholder in [2]:
		dock.node_option.select(placeholder)
		dock.add_node_button.pressed.emit()
		check("placeholder %d adds nothing" % placeholder, get_child_count() == 2)
	dock.node_option.select(0)
	EditorInterface.get_selection().clear()
	EditorInterface.edit_node(self)
	undo.undo()
	undo.undo()
	history.clear_history(history_id)
	print("PLAYER EDITOR: ", tested - failures.size(), "/", tested)
	get_tree().quit(0 if failures.is_empty() else 1)
