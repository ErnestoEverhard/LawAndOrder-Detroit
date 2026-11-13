extends SceneTree
# Debug: line Mixamo characters up, print their mesh names and heights, and save a picture.
# godot --path . -s tools/lineup.gd -- out.png joe martha brian
func _init() -> void:
	var root3 := Node3D.new()
	get_root().add_child(root3)
	var args := OS.get_cmdline_user_args()
	var names := args.slice(1)
	for i in names.size():
		var n: Node3D = (load("res://assets/mixamo/characters/%s.fbx" % names[i]) as PackedScene).instantiate()
		n.position = Vector3((i - (names.size() - 1) / 2.0) * 0.85, 0, 0)
		root3.add_child(n)
		var sk: Skeleton3D = n.find_child("Skeleton3D", true, false)
		var parts := []
		for mi in n.find_children("*", "MeshInstance3D", true, false):
			parts.append(str(mi.name))
		for b in sk.get_bone_count():
			if sk.get_bone_name(b).ends_with("HeadTop_End"):
				print(names[i], " head ", snappedf((sk.global_transform * sk.get_bone_global_rest(b)).origin.y, 0.01), " bones ", sk.get_bone_name(b), " parts ", parts)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.0, 1.2 + names.size() * 0.75)
	cam.fov = 40
	root3.add_child(cam)
	var l := DirectionalLight3D.new()
	l.rotation_degrees = Vector3(-30, 20, 0)
	root3.add_child(l)
	var e := WorldEnvironment.new()
	e.environment = Environment.new()
	e.environment.background_mode = Environment.BG_COLOR
	e.environment.background_color = Color(0.5, 0.5, 0.55)
	e.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.environment.ambient_light_color = Color.WHITE
	e.environment.ambient_light_energy = 0.6
	root3.add_child(e)
	for i in 30:
		await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png(args[0])
	quit()
