extends SceneTree

const PLAYER := preload("res://addons/blockout_tools/nodes/player.tscn")
const SHAPE := preload("res://addons/blockout_tools/blockout_shape.gd")

func _initialize() -> void:
	call_deferred("_run")

func _box(stage: Node3D, size: Vector3, position: Vector3) -> void:
	var box := SHAPE.new()
	box.box_size = size
	stage.add_child(box)
	box.rebuild()
	# Blockout shapes have their own alignment origins; fixture positions are centres.
	box.position = position - box.get_mesh().get_aabb().get_center()

func _run() -> void:
	root.size = Vector2i(800, 500)
	var stage := Node3D.new()
	root.add_child(stage)
	current_scene = stage
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.12, 0.15, 0.2)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color.WHITE
	environment.ambient_light_energy = 0.7
	world.environment = environment
	stage.add_child(world)
	var light := DirectionalLight3D.new()
	light.rotation = Vector3(-0.7, -0.4, 0)
	light.shadow_enabled = true
	stage.add_child(light)
	_box(stage, Vector3(12, 1, 12), Vector3(0, -0.5, 0))
	_box(stage, Vector3(12, 3, 0.5), Vector3(0, 1.5, -5))
	_box(stage, Vector3(1, 2, 1), Vector3(-2, 1, 0))
	_box(stage, Vector3(1, 2, 1), Vector3(2, 1, 0))
	var player := PLAYER.instantiate() as CharacterBody3D
	player.position = Vector3(0, 0.05, 2)
	stage.add_child(player)
	player.get_node("Head").rotation.x = -0.15
	var passed := true
	for perspective in 2:
		player.set("perspective", perspective)
		# Keep this deterministic even if the user focuses another window.
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		for frame in 8:
			await process_frame
		await RenderingServer.frame_post_draw
		var screenshot := root.get_texture().get_image()
		var path := "res://tests/evidence/player-%s.png" % ("first-person" if perspective == 0 else "third-person")
		passed = screenshot.save_png(path) == OK and passed
	print("PLAYER VIEW RENDER: ", "PASS" if passed else "FAIL")
	stage.free()
	quit(0 if passed else 1)
