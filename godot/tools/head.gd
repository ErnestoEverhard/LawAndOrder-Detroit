extends SceneTree
# Debug: one character's head from the front, side and back.   godot --path . -s tools/head.gd -- out.png louise
func _init() -> void:
	var k: Node3D = load("res://kit.gd").new()
	get_root().add_child(k)
	k.env("hansaplatz", 0.0, Color(0.9, 0.9, 0.92), 1.0, 0.0, Color.WHITE)
	k.box(Vector3(0, 1.5, -1.5), Vector3(12, 4, 0.1), Color(0.55, 0.57, 0.6))
	var args := OS.get_cmdline_user_args()
	var rots := [0.0, 0.9, PI / 2, PI]
	for i in rots.size():
		k.actor("", args[1], Vector3((i - 1.5) * 0.75, 0, 0), rots[i], "idle", "idle")
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 25, 0)
	get_root().add_child(sun)
	var cam := Camera3D.new()
	get_root().add_child(cam)
	cam.fov = 22
	var cx := float(args[2]) if args.size() > 2 else 0.0
	cam.look_at_from_position(Vector3(cx, 1.62, 5.6), Vector3(cx, 1.6, 0))
	cam.fov = 10.0 if args.size() > 2 else 22.0
	for i in 30:
		await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png(args[0])
	quit()
