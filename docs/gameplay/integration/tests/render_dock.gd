extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var show_menu := "--shape-menu" in OS.get_cmdline_user_args()
	root.gui_embed_subwindows = true
	root.size = Vector2i(378, 800 if show_menu else 670)
	var background := ColorRect.new()
	background.color = Color("242424")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)
	var dock_script = load("res://addons/blockout_tools/blockout_dock.gd")
	var dock: VBoxContainer = dock_script.new()
	dock.position = Vector2(11, 10)
	dock.size = Vector2(358, 650)
	root.add_child(dock)
	for frame in 5:
		await process_frame
	if show_menu:
		dock.shape_option.show_popup()
		dock.shape_option.get_popup().reset_size()
		dock.shape_option.get_popup().popup()
		for frame in 5:
			await process_frame
	await RenderingServer.frame_post_draw
	var fits := dock.get_combined_minimum_size().x <= dock.size.x
	for input: LineEdit in dock.default_box_size_inputs:
		fits = fits and input.get_global_rect().end.x <= dock.get_global_rect().end.x
	var screenshot := root.get_texture().get_image()
	var result := screenshot.save_png("res://tests/evidence/shape-menu-dock.png" if show_menu else "res://tests/evidence/gameplay-nodes-dock.png")
	print("DOCK RENDER: size=", dock.size, " minimum=", dock.get_combined_minimum_size(), " fits=", fits, " saved=", result == OK)
	quit(0 if fits and result == OK else 1)
