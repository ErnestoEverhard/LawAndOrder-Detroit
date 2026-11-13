extends SceneTree
# Debug: line the Mixamo cast up and save a picture. godot --path . -s tools/lineup.gd -- out.png
func _init() -> void:
	var root3 := Node3D.new()
	get_root().add_child(root3)
	var names := ["james", "james", "james", "remy"]
	for i in names.size():
		var n: Node3D = (load("res://assets/mixamo/characters/%s.fbx" % names[i]) as PackedScene).instantiate()
		n.position = Vector3(i * 0.9 - 1.3, 0, 0)
		root3.add_child(n)
		var sk: Skeleton3D = n.find_child("Skeleton3D", true, false)
		for b in sk.get_bone_count():
			if sk.get_bone_name(b).ends_with("HeadTop_End"):
				print(names[i], " head ", (sk.global_transform * sk.get_bone_global_rest(b)).origin.y, " scale ", n.scale, sk.scale)
		if names[i] == "james" and i > 0:
			var mi: MeshInstance3D = n.find_child("Ch06", true, false)
			var t := StandardMaterial3D.new()
			t.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			t.albedo_color = Color(1, 1, 1, 0)
			mi.set_surface_override_material(0 if i == 1 else 2, t)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.3, 3.0)
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
	get_root().get_texture().get_image().save_png(OS.get_cmdline_user_args()[0])
	quit()
