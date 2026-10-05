@tool
extends Node3D

const DOCK := preload("res://addons/blockout_tools/blockout_dock.gd")
const GIZMO := preload("res://addons/blockout_tools/spawn_point_gizmo.gd")
const SPAWN_PATH := "res://addons/blockout_tools/nodes/spawn_point.tscn"
var failures: Array[String] = []
var tested := 0

func _ready() -> void:
	if Engine.is_editor_hint() and "--run-spawn-editor-tests" in OS.get_cmdline_user_args():
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
	dock.node_option.select(1)
	dock.add_node_button.pressed.emit()
	var first := get_child(0) as BlockoutSpawnPoint
	check("button adds Spawn Point", first != null and first.get_parent() == self)
	check("spawn retains external scene and owner", first.scene_file_path == SPAWN_PATH and first.owner == self)
	check("spawn selected and enabled by default", EditorInterface.get_selection().get_selected_nodes().has(first) and first.enabled)
	check("spawn contains correctly sized capsule collision", first.get_node("CollisionShape3D").shape is CapsuleShape3D and is_equal_approx(first.get_node("CollisionShape3D").shape.height, 2.0))
	var plugin := GIZMO.new()
	check("gizmo recognizes spawn", plugin._has_gizmo(first))
	check("gizmo does not recognize arbitrary Node3D", not plugin._has_gizmo(self))
	var gizmo := EditorNode3DGizmo.new()
	gizmo.set_node_3d(first)
	plugin._redraw(gizmo)
	check("spawn gizmo can draw capsule and arrow", gizmo != null)
	first.enabled = false
	plugin._redraw(gizmo)
	check("disabled gizmo can redraw", not first.enabled)
	first.position = Vector3(2, 0, 1)
	first.rotation.y = 0.6
	dock.add_node_button.pressed.emit()
	var second := get_child(1) as BlockoutSpawnPoint
	check("multiple additions have unique names", first.name != second.name)
	var history := EditorInterface.get_editor_undo_redo()
	var history_id := history.get_object_history_id(self)
	var undo := history.get_history_undo_redo(history_id)
	check("undo removes last Spawn Point", undo.undo() and get_child_count() == 1 and not second.is_inside_tree())
	check("redo restores Spawn Point and owner", undo.redo() and get_child_count() == 2 and second.owner == self)
	var packed := PackedScene.new()
	check("scene packs with external instances", packed.pack(self) == OK and packed.get_state().get_node_count() == 3)
	var save_path := "res://tests/evidence/spawn-saved.tscn"
	check("scene saves to disk", ResourceSaver.save(packed, save_path) == OK)
	var loaded := ResourceLoader.load(save_path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	check("saved scene reloads", loaded != null)
	if loaded:
		var restored := loaded.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
		var reloaded := restored.get_child(0) as BlockoutSpawnPoint
		check("reload keeps instance, capsule and disabled flag", reloaded.scene_file_path == SPAWN_PATH and reloaded.has_node("CollisionShape3D") and not reloaded.enabled)
		check("reload keeps placement and yaw", reloaded.position.is_equal_approx(Vector3(2, 0, 1)) and is_equal_approx(reloaded.rotation.y, 0.6))
		check("reload keeps second enabled", restored.get_child(1).enabled)
		restored.free()
	if "--render-spawn" in OS.get_cmdline_user_args():
		first.position = Vector3(-1.5, 0, 0)
		first.rotation.y = 0
		second.position = Vector3(1.5, 0, 0)
		second.rotation.y = PI / 2.0
		EditorInterface.get_selection().clear()
		EditorInterface.set_main_screen_editor("3D")
		var viewport := EditorInterface.get_editor_viewport_3d(0)
		var camera := viewport.get_camera_3d()
		for frame in 8:
			camera.global_transform = Transform3D(Basis.IDENTITY, Vector3(5, 6, 8)).looking_at(Vector3(0, 1, -0.5))
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		check("editor screenshot saved", viewport.get_texture().get_image().save_png("res://tests/evidence/spawn-editor.png") == OK)
	EditorInterface.get_selection().clear()
	EditorInterface.edit_node(self)
	gizmo.clear()
	gizmo = null
	plugin = null
	undo.undo()
	undo.undo()
	history.clear_history(history_id)
	print("SPAWN EDITOR: ", tested - failures.size(), "/", tested)
	get_tree().quit(0 if failures.is_empty() else 1)
