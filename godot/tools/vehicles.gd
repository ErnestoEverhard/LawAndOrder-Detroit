extends SceneTree
# Debug: park one of each vehicle on a lot and save a picture.   godot --path . -s tools/vehicles.gd -- out.png
func _init() -> void:
	var k: Node3D = load("res://kit.gd").new()
	get_root().add_child(k)
	k.env("hansaplatz", 1.0, Color(0.5, 0.5, 0.55), 1.0, 0.0, Color.WHITE)
	k.box(Vector3(0, -0.05, 0), Vector3(40, 0.1, 30), Color(0.3, 0.3, 0.31))
	k.van(Vector3(-5.5, 0, 0), 0.5, Color(0.86, 0.86, 0.84), true, "HOLLIS UNIVERSITY\nFACILITIES  ·  UNIT 7")
	k.van(Vector3(0.5, 0, 0), -0.6, Color(0.1, 0.13, 0.25), false, "POLICE", Color(0.9, 0.9, 0.9), true, "car")
	k.van(Vector3(6.5, 0, -1), -0.5, Color(0.6, 0.08, 0.06), false, "CALDER FIRE  ·  ENGINE 9", Color(0.9, 0.85, 0.3), true, "truck")
	k.van(Vector3(1, 0, -6), PI + 0.5, Color(0.9, 0.9, 0.88), true, "CALDER COUNTY EMS", Color(0.85, 0.3, 0.1), true)
	var l := DirectionalLight3D.new()
	l.rotation_degrees = Vector3(-40, 30, 0)
	l.shadow_enabled = true
	get_root().add_child(l)
	var cam := Camera3D.new()
	get_root().add_child(cam)
	cam.look_at_from_position(Vector3(0, 3.2, 11), Vector3(0.5, 0.8, -1))
	cam.fov = 55
	for i in 20:
		await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png(OS.get_cmdline_user_args()[0])
	quit()
