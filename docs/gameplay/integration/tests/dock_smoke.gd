extends SceneTree

func _initialize() -> void:
	call_deferred("_check_dock")

func _check_dock() -> void:
	var suite := "all"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--suite="):
			suite = argument.trim_prefix("--suite=")
	if suite not in ["all", "shape", "gameplay"]:
		push_error("Unknown dock suite: " + suite)
		quit(1)
		return
	var script = load("res://addons/blockout_tools/blockout_dock.gd")
	if script == null or not script.can_instantiate():
		push_error("Dock script could not be instantiated")
		quit(1)
		return
	var valid := true
	if suite in ["all", "shape"]:
		valid = _shape_checks(script) and valid
	if suite in ["all", "gameplay"]:
		valid = _gameplay_checks(script) and valid
	if not valid:
		push_error("Dock labels, IDs, translation settings or default Box size behavior mismatch")
		quit(1)
		return
	print("DOCK SMOKE: ", suite, " labels, IDs, translation settings and controls")
	quit(0)

func _shape_checks(script: Script) -> bool:
	var valid := true
	var defaults = load("res://addons/blockout_tools/blockout_defaults.gd")
	var shape_script = load("res://addons/blockout_tools/blockout_shape.gd")
	var had_box_size_setting := ProjectSettings.has_setting(defaults.BOX_SIZE_KEY)
	var previous_box_size: Variant = ProjectSettings.get_setting(defaults.BOX_SIZE_KEY)
	var expected_box_size := Vector3(2.5, 3.0, 4.25)
	ProjectSettings.set_setting(defaults.BOX_SIZE_KEY, expected_box_size)
	var dock = script.new()
	root.add_child(dock)
	var options: OptionButton = dock.shape_option
	var visible_ids := [0,1,2,3,4,5,6,7,8,9,10,11,13,14]
	valid = valid and options.item_count == visible_ids.size()
	valid = valid and dock.default_box_size_inputs.size() == 3
	var has_default_box_size_label := false
	for child in dock.get_children():
		if child is Label and child.text == "Default Box Size":
			has_default_box_size_label = true
	valid = valid and has_default_box_size_label
	for axis in 3:
		var input: LineEdit = dock.default_box_size_inputs[axis]
		valid = valid and is_equal_approx(input.text.to_float(), expected_box_size[axis])
		valid = valid and input.flat
		valid = valid and input.select_all_on_focus
		valid = valid and not input.has_theme_font_size_override("font_size")
	var box = shape_script.new()
	defaults.apply_to(box)
	valid = valid and box.box_size.is_equal_approx(expected_box_size)
	box.free()
	valid = valid and options.auto_translate_mode == Node.AUTO_TRANSLATE_MODE_DISABLED
	valid = valid and options.get_popup().auto_translate_mode == Node.AUTO_TRANSLATE_MODE_DISABLED
	for i in options.item_count:
		options.select(i)
		var shape_id: int = visible_ids[i]
		valid = valid and options.text == script.SHAPES[shape_id]
		valid = valid and options.get_item_id(i) == shape_id
		valid = valid and options.get_selected_id() == shape_id
		valid = valid and options.get_item_auto_translate_mode(i) == Node.AUTO_TRANSLATE_MODE_DISABLED
		valid = valid and options.get_popup().get_item_text(i) == script.SHAPES[shape_id]
	var shape = shape_script.new()
	for current in [0,13,14]:
		shape.shape_type = current
		for property in shape.get_property_list():
			if property.name == "shape_type":
				var expected := PackedStringArray()
				for shape_id in visible_ids:
					expected.append("%s:%d" % [script.SHAPES[shape_id], shape_id])
				valid = valid and property.hint_string == ",".join(expected)
	shape.shape_type = 12
	for property in shape.get_property_list():
		if property.name == "shape_type":
			valid = valid and "Stairs Linear Manual:12" in property.hint_string
	var packed := PackedScene.new()
	valid = valid and packed.pack(shape) == OK
	var legacy = packed.instantiate()
	valid = valid and legacy.shape_type == 12 and legacy.shape_type_name() == "BlockoutStairsLinearManual"
	legacy.free()
	shape.free()
	dock.free()
	if had_box_size_setting:
		ProjectSettings.set_setting(defaults.BOX_SIZE_KEY, previous_box_size)
	else:
		ProjectSettings.clear(defaults.BOX_SIZE_KEY)

	return valid

func _gameplay_checks(script: Script) -> bool:
	var valid := true
	var dock = script.new()
	root.add_child(dock)
	var node_options: OptionButton = dock.node_option
	valid = valid and node_options.item_count == 3 and node_options.selected == 0
	valid = valid and node_options.auto_translate_mode == Node.AUTO_TRANSLATE_MODE_DISABLED
	valid = valid and node_options.get_popup().auto_translate_mode == Node.AUTO_TRANSLATE_MODE_DISABLED
	for i in 3:
		valid = valid and node_options.get_item_text(i) == ["Player", "Spawn Point", "End Point"][i]
		valid = valid and node_options.get_item_id(i) == i
		valid = valid and node_options.is_item_disabled(i) == (i == 2)
		valid = valid and node_options.get_item_auto_translate_mode(i) == Node.AUTO_TRANSLATE_MODE_DISABLED
	valid = valid and dock.add_node_button.pressed.is_connected(dock._on_add_node_pressed)
	valid = valid and not dock.add_node_button.has_theme_font_size_override("font_size")
	dock.free()
	return valid
